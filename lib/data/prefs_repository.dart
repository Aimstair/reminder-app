/// User settings (behavior-spec §12 PRF-*, screens.md VW-1/VW-6) stored as JSON values in the
/// `prefs` table. Unset keys fall back to the spec defaults in [UserPrefs].
library;

import 'dart:async';
import 'dart:convert';

import 'package:reminder_core/reminder_core.dart';

import 'app_database.dart';
import 'reminder_repository.dart';

/// Keys in the `prefs` table.
abstract final class PrefKeys {
  static const defaultTimeZone = 'default_time_zone';
  static const askOnTravel = 'ask_on_travel';
  static const dayTime = 'day_time';
  static const nagStart = 'nag_start';
  static const nagEnd = 'nag_end';
  static const tomorrowMode = 'tomorrow_mode';
  static const lateAlertCutoffMin = 'late_alert_cutoff_min';
  static const digestTime = 'digest_time';
  static const digestNotification = 'digest_notification';
  static const completionSounds = 'completion_sounds';
  static const autoAddBirthdays = 'auto_add_birthdays';
  static const alertDefaults = 'alert_defaults'; // PRF-9: {kind: ["-7d", ...]}
  static const onboarded = 'onboarded';

  // Views & appearance (S-56)
  static const startIn = 'start_in'; // VW-1: last | schedule | day | month
  static const lastView = 'last_view';
  static const showCompleted = 'show_completed'; // VW-6
  static const theme = 'theme'; // system | light | dark

  // Drawer filters (VW-2): lists of hidden values
  static const hiddenKinds = 'hidden_kinds';
  static const hiddenContexts = 'hidden_contexts';
  static const hiddenCalendars = 'hidden_calendars';

  // Calendars & contacts (S-55)
  static const selectedCalendars = 'selected_calendars'; // CAL-1
  static const calendarConnected = 'calendar_connected';
  static const contactsImport = 'contacts_import'; // CON-1
  static const dismissedContacts = 'dismissed_contacts';

  static const digestDismissedDay = 'digest_dismissed_day'; // DIG-1
  static const firstDoneShown = 'first_done_shown';
  static const lastTest = 'last_test_result'; // PRM-7
  static const batteryTipDismissed = 'battery_tip_dismissed'; // PRM-4
}

class PrefsRepository {
  PrefsRepository(this._db, {Clock? clock}) : _now = clock ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final Clock _now;
  Map<String, Object?> _values = {};
  String _deviceZone = 'UTC';
  final _changes = StreamController<void>.broadcast();

  /// Fires after every change (settings screens, filters) so the UI can rebuild.
  Stream<void> get changes => _changes.stream;

  /// Loads stored values. [deviceTimeZone] is the phone's current zone; on first run it also becomes
  /// the default zone for new reminders (PRF-1).
  Future<void> load({required String deviceTimeZone}) async {
    _deviceZone = deviceTimeZone;
    final rows = await _db.select(_db.prefs).get();
    _values = {for (final r in rows) r.key: jsonDecode(r.value)};
    if (_values[PrefKeys.defaultTimeZone] == null) await set(PrefKeys.defaultTimeZone, deviceTimeZone);
  }

  /// The phone's zone changed (TIM-15) — date-only reminders follow it.
  void setDeviceTimeZone(String zone) {
    if (zone == _deviceZone) return;
    _deviceZone = zone;
    _changes.add(null);
  }

  String get deviceTimeZone => _deviceZone;

  Future<void> set(String key, Object? value) async {
    _values[key] = value;
    await _db
        .into(_db.prefs)
        .insertOnConflictUpdate(PrefsCompanion.insert(key: key, value: jsonEncode(value), updatedAt: _now()));
    _changes.add(null);
  }

  Object? raw(String key) => _values[key];
  bool flag(String key, {bool fallback = false}) => (_values[key] as bool?) ?? fallback;
  String? string(String key) => _values[key] as String?;
  Set<String> stringSet(String key) => {...((_values[key] as List?) ?? const []).cast<String>()};

  bool get onboarded => flag(PrefKeys.onboarded);

  UserPrefs get current {
    const d = UserPrefs(defaultTimeZone: 'UTC', deviceTimeZone: 'UTC');
    final cutoff = _values.containsKey(PrefKeys.lateAlertCutoffMin)
        ? switch (_values[PrefKeys.lateAlertCutoffMin]) {
            final int m => Duration(minutes: m),
            _ => null, // stored null = "Always"
          }
        : d.lateAlertCutoff;
    return UserPrefs(
      defaultTimeZone: (_values[PrefKeys.defaultTimeZone] as String?) ?? _deviceZone,
      deviceTimeZone: _deviceZone,
      askOnTravel: _bool(PrefKeys.askOnTravel, d.askOnTravel),
      dayTime: _time(PrefKeys.dayTime, d.dayTime),
      nagStart: _time(PrefKeys.nagStart, d.nagStart),
      nagEnd: _time(PrefKeys.nagEnd, d.nagEnd),
      tomorrowMode: _values[PrefKeys.tomorrowMode] == TomorrowMode.sameTime.name
          ? TomorrowMode.sameTime
          : TomorrowMode.dayTime,
      lateAlertCutoff: cutoff,
      digestTime: _time(PrefKeys.digestTime, d.digestTime),
      digestNotification: _bool(PrefKeys.digestNotification, d.digestNotification),
      completionSounds: _bool(PrefKeys.completionSounds, d.completionSounds),
      autoAddBirthdays: _bool(PrefKeys.autoAddBirthdays, d.autoAddBirthdays),
      alertDefaults: _alertDefaults(),
    );
  }

  /// PRF-9: saves the default plan for [kind] (null = back to ALR-4).
  Future<void> setAlertDefault(Kind kind, List<AlertStage>? plan) {
    final map = {...((_values[PrefKeys.alertDefaults] as Map?) ?? const {})};
    if (plan == null) {
      map.remove(kind.name);
    } else {
      map[kind.name] = [for (final s in plan) s.offset.toString()];
    }
    return set(PrefKeys.alertDefaults, map);
  }

  Map<Kind, List<AlertStage>> _alertDefaults() {
    final map = _values[PrefKeys.alertDefaults];
    if (map is! Map) return const {};
    return {
      for (final k in Kind.values)
        if (map[k.name] case final List offsets)
          k: [for (final o in offsets.cast<String>()) AlertStage(AlertOffset.parse(o))],
    };
  }

  /// Stores a time of day as "HH:mm".
  static String encodeTime(TimeOfDay t) => t.toString();

  bool _bool(String key, bool fallback) => (_values[key] as bool?) ?? fallback;

  TimeOfDay _time(String key, TimeOfDay fallback) {
    final s = _values[key];
    if (s is! String) return fallback;
    final parts = s.split(':');
    if (parts.length != 2) return fallback;
    final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
    return h == null || m == null ? fallback : TimeOfDay(h, m);
  }
}
