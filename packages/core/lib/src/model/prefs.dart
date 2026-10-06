/// User settings the rules depend on (behavior-spec §12 PRF-*), with spec defaults.
library;

import 'alert.dart';
import 'enums.dart';

/// A time of day (wall clock).
class TimeOfDay {
  const TimeOfDay(this.hour, this.minute);
  final int hour;
  final int minute;

  int get minutes => hour * 60 + minute;

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// PRF-5: what "Tomorrow" on a notification means.
enum TomorrowMode { dayTime, sameTime }

class UserPrefs {
  const UserPrefs({
    required this.defaultTimeZone,
    required this.deviceTimeZone,
    this.askOnTravel = true,
    this.dayTime = const TimeOfDay(9, 0),
    this.nagStart = const TimeOfDay(8, 0),
    this.nagEnd = const TimeOfDay(22, 0),
    this.tomorrowMode = TomorrowMode.dayTime,
    this.lateAlertCutoff = const Duration(hours: 2),
    this.digestTime = const TimeOfDay(8, 0),
    this.digestNotification = true,
    this.completionSounds = true,
    this.autoAddBirthdays = true,
    this.alertDefaults = const {},
  });

  /// PRF-1: zone for new timed reminders.
  final String defaultTimeZone;

  /// The phone's current zone — date-only reminders follow it (TIM-4, TIM-15).
  final String deviceTimeZone;

  /// PRF-2
  final bool askOnTravel;

  /// PRF-3: time used for date-only reminders.
  final TimeOfDay dayTime;

  /// PRF-4: nagging only between these (device local time).
  final TimeOfDay nagStart;
  final TimeOfDay nagEnd;

  /// PRF-5
  final TomorrowMode tomorrowMode;

  /// PRF-6: null = "Always" (show however late).
  final Duration? lateAlertCutoff;

  /// PRF-7 / PRF-8
  final TimeOfDay digestTime;
  final bool digestNotification;

  /// PRF-12
  final bool completionSounds;

  /// PRF-13
  final bool autoAddBirthdays;

  /// PRF-9: user-set default alert plans; missing types use ALR-4.
  final Map<Kind, List<AlertStage>> alertDefaults;

  List<AlertStage> alertPlanFor(Kind kind, TimingType timing) => alertDefaults[kind] ?? defaultAlertPlan(kind, timing);
}
