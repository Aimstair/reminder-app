/// Composition root: opens the database, loads settings and wires the reminder service to the native
/// alarm module. Created once in main(); screens read it through the app's providers.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:reminder_core/reminder_core.dart';

import '../data/app_database.dart';
import '../data/occurrence_repository.dart';
import '../data/prefs_repository.dart';
import '../data/reminder_repository.dart';
import '../l10n/gen/app_localizations.dart';
import '../native/alarm_gateway.dart';
import '../notifications/alert_text.dart';
import '../services/reminder_service.dart';

class AppServices {
  AppServices._(this.db, this.prefs, this.reminders, this.occurrences, this.service);

  final AppDatabase db;
  final PrefsRepository prefs;
  final ReminderRepository reminders;
  final OccurrenceRepository occurrences;
  final ReminderService service;

  static Future<AppServices> start({AppDatabase? db, AlarmGateway? gateway}) async {
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
    final service = ReminderService(
      reminders: reminders,
      occurrences: occurrences,
      gateway: gateway ?? PigeonAlarmGateway(),
      prefs: () => prefs.current,
      text: (p) => NotificationTextBuilder(l10n: l10n, prefs: p, locale: l10n.localeName).call,
    );
    return AppServices._(database, prefs, reminders, occurrences, service);
  }

  /// App start / resume: pick up a zone change (TIM-15), apply notification taps, resync alarms.
  Future<void> refresh() async {
    prefs.setDeviceTimeZone(await deviceTimeZone());
    await service.onAppStart();
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
