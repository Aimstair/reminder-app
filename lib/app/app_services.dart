/// Composition root: opens the database, loads settings and wires the services to the native side.
/// Created once in main(); screens read it through the app's providers.
library;

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:reminder_core/reminder_core.dart';

import '../data/app_database.dart';
import '../data/backup_repository.dart';
import '../data/occurrence_repository.dart';
import '../data/overlay_repository.dart';
import '../data/prefs_repository.dart';
import '../data/reminder_repository.dart';
import '../integrations/feedback.dart';
import '../integrations/voice.dart';
import '../l10n/gen/app_localizations.dart';
import '../native/alarm_gateway.dart';
import '../native/platform_gateway.dart';
import '../notifications/alert_text.dart';
import '../services/calendar_service.dart';
import '../services/contacts_service.dart';
import '../services/reminder_service.dart';
import '../ui/format.dart';

class AppServices {
  AppServices._({
    required this.db,
    required this.prefs,
    required this.reminders,
    required this.occurrences,
    required this.overlays,
    required this.service,
    required this.alarms,
    required this.platform,
    required this.calendar,
    required this.contacts,
    required this.backup,
    required this.l10n,
  });

  final AppDatabase db;
  final PrefsRepository prefs;
  final ReminderRepository reminders;
  final OccurrenceRepository occurrences;
  final OverlayRepository overlays;
  final ReminderService service;
  final AlarmGateway alarms;
  final PlatformGateway? platform;
  final CalendarService calendar;
  final ContactsService contacts;
  final BackupRepository backup;
  final AppLocalizations l10n;
  final feedback = CompletionFeedback();
  final voice = VoiceInput();

  /// Permission state from the last refresh (PRM-5), for banners and Settings → Reliability.
  Permissions permissions = Permissions.allGranted;

  static Future<AppServices> start({
    AppDatabase? db,
    AlarmGateway? gateway,
    PlatformGateway? platform,
    CalendarReader? calendarReader,
    ContactsReader? contactsReader,
  }) async {
    ensureTimeZones();
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = lookupAppLocalizations(
      AppLocalizations.supportedLocales.contains(Locale(locale.languageCode)) ? locale : const Locale('en'),
    );
    await NotificationTextBuilder.init(l10n.localeName);

    final database = db ?? AppDatabase();
    final prefs = PrefsRepository(database);
    await prefs.load(deviceTimeZone: await deviceTimeZone());
    final reminders = ReminderRepository(database);
    final occurrences = OccurrenceRepository(database, reminders);
    final overlays = OverlayRepository(database, reminders);
    final alarms = gateway ?? PigeonAlarmGateway();
    final service = ReminderService(
      reminders: reminders,
      occurrences: occurrences,
      gateway: alarms,
      prefs: () => prefs.current,
      text: (p) => NotificationTextBuilder(l10n: l10n, prefs: p, locale: l10n.localeName).call,
    );
    final calendar = CalendarService(
      reader: calendarReader ?? (platform != null ? PlatformCalendarReader(platform) : _NoCalendar()),
      prefs: prefs,
      overlays: overlays,
      deviceId: await reminders.deviceId(),
    );
    service.calendarReminders = () => calendar.reminders;
    service.extraAlarms = (active, saved, now) => _digestAlarm(prefs, l10n, active, saved, now);
    final contacts = ContactsService(
      reader: contactsReader ?? DeviceContactsReader(),
      prefs: prefs,
      reminders: reminders,
      service: service,
    );
    final backup = BackupRepository(database);
    return AppServices._(
      db: database,
      prefs: prefs,
      reminders: reminders,
      occurrences: occurrences,
      overlays: overlays,
      service: service,
      alarms: alarms,
      platform: platform,
      calendar: calendar,
      contacts: contacts,
      backup: backup,
      l10n: l10n,
    );
  }

  /// App start / resume: zone change (TIM-15), permissions (PRM-5), calendar (CAL-2), contacts
  /// (CON-6), notification taps, housekeeping, alarms (SCH-5), widget.
  Future<void> refresh() async {
    prefs.setDeviceTimeZone(await deviceTimeZone());
    try {
      permissions = await alarms.permissions();
    } catch (_) {}
    await calendar.refresh();
    await contacts.rescan();
    await service.onAppStart();
    await updateWidget();
  }

  /// S-61: the next three upcoming items for the home-screen widget.
  Future<void> updateWidget() async {
    final p = platform;
    if (p == null) return;
    try {
      final now = DateTime.now().toUtc();
      final items = ScheduleView(prefs: prefs.current)
          .build([...await reminders.watchActive().first, ...calendar.reminders], await occurrences.byPlannerId(), now)
          .where((i) => !i.overdue)
          .take(3);
      final f = Fmt(l10n, l10n.localeName);
      final today = dateOnly(instantToWall(now, prefs.deviceTimeZone));
      await p.updateWidget(jsonEncode({
        'items': [
          for (final i in items)
            {
              'title': i.reminder.title,
              'when': f.when(i.start, allDay: i.reminder.timing.type == TimingType.date, today: today),
            },
        ],
        'empty': l10n.widgetEmpty,
      }));
    } catch (_) {}
  }

  /// DIG-3: one notification at the next digest time if there will be something to say
  /// ("3 overdue · 1 coming up"); none when empty or turned off (PRF-8).
  static List<PlannedAlarm> _digestAlarm(
    PrefsRepository prefs,
    AppLocalizations l10n,
    List<Reminder> active,
    Map<String, Occurrence> saved,
    DateTime now,
  ) {
    final p = prefs.current;
    if (!p.digestNotification) return const [];
    final zone = p.deviceTimeZone;
    final today = dateOnly(instantToWall(now, zone));
    var at = wallToInstant(today.add(Duration(minutes: p.digestTime.minutes)), zone);
    if (!at.isAfter(now)) at = wallToInstant(addDays(today, 1).add(Duration(minutes: p.digestTime.minutes)), zone);
    final d = buildDigest(reminders: active, saved: saved, prefs: p, now: at);
    final parts = [
      if (d.overdue.isNotEmpty) l10n.digestPartOverdue(d.overdue.length),
      if (d.upcomingOccasions.isNotEmpty) l10n.digestPartComing(d.upcomingOccasions.length),
    ];
    if (parts.isEmpty) return const [];
    final day = dateOnly(instantToWall(at, zone));
    final key = 'digest~${formatWallDate(day).replaceAll('-', '')}:0:0';
    return [
      PlannedAlarm(
        key: key,
        fireAt: at,
        title: l10n.digestTitle,
        body: parts.join(' · '),
        kind: 'digest',
        lateCutoff: const Duration(hours: 6),
      ),
    ];
  }

  /// The phone's IANA zone; UTC if the platform reports one the tz database doesn't know.
  static Future<String> deviceTimeZone() async {
    try {
      final id = (await FlutterTimezone.getLocalTimezone()).identifier;
      instantToWall(DateTime.now().toUtc(), id); // throws for unknown ids
      return id;
    } catch (_) {
      return 'UTC';
    }
  }
}

/// Calendar reader for tests and platforms without the native module.
class _NoCalendar implements CalendarReader {
  @override
  Future<bool> hasPermission() async => false;
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<List<DeviceCalendar>> calendars() async => const [];
  @override
  Future<List<CalendarEvent>> events({required DateTime from, required DateTime to, required Set<String> calendarIds}) async =>
      const [];
}
