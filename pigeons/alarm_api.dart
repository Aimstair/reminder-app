// Pigeon definition for the Dart ↔ Kotlin alarm bridge (docs/architecture.md §5).
// Regenerate: dart run pigeon --input pigeons/alarm_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/native/alarm_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/app/aimstair/reminder_app/alarms/AlarmApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'app.aimstair.reminder_app.alarms'),
  dartPackageName: 'reminder_app',
))

/// One alarm the native side should fire. Key = `occurrence_id:stage:nag_seq` (SCH-4).
class AlarmSpec {
  AlarmSpec({
    required this.key,
    required this.fireAtUtcMs,
    required this.title,
    required this.body,
    required this.kind,
    required this.lateCutoffMs,
  });

  String key;
  int fireAtUtcMs;
  String title;
  String body;

  /// Which notification buttons to show (NTF-2): task | occasion_prep | occasion_day | meeting | test
  String kind;

  /// SCH-7: alarms later than this are recorded as missed instead of shown.
  int lateCutoffMs;
}

/// An alarm currently registered natively — the same fields as [AlarmSpec] plus whether it's exact.
class RegisteredAlarm {
  RegisteredAlarm({required this.spec, required this.exact});

  AlarmSpec spec;

  /// False when exact alarms aren't allowed and an inexact window was used (SCH-9).
  bool exact;
}

class PermissionState {
  PermissionState({
    required this.notifications,
    required this.exactAlarms,
    required this.ignoringBatteryOptimizations,
  });

  bool notifications;
  bool exactAlarms;
  bool ignoringBatteryOptimizations;
}

/// A notification button tapped while Flutter may not have been running.
class JournalEntry {
  JournalEntry({
    required this.id,
    required this.alarmKey,
    required this.action,
    required this.actedAtMs,
  });

  int id;
  String alarmKey;

  /// done | snooze | tomorrow | prepared | undo
  String action;
  int actedAtMs;
}

/// Delivery record for metrics (D4) and the test reminder (PRM-7).
class FireLogEntry {
  FireLogEntry({
    required this.alarmKey,
    required this.scheduledAtMs,
    required this.firedAtMs,
    required this.outcome,
  });

  String alarmKey;
  int scheduledAtMs;
  int firedAtMs;

  /// shown | late | missed
  String outcome;
}

@HostApi()
abstract class AlarmHostApi {
  /// Replace the registered set with [alarms] (diff by key: add, update, cancel) — SCH-4.
  void sync(List<AlarmSpec> alarms);

  /// Cancel alarms and remove their notifications — OCC-4, DAT-2.
  void cancel(List<String> keys);

  List<RegisteredAlarm> registered();

  PermissionState getPermissionState();
  void requestNotificationPermission();
  void openExactAlarmSettings();
  void openBatteryOptimizationSettings();

  List<JournalEntry> readJournal();
  void markApplied(List<int> ids);

  List<FireLogEntry> getFireLog(int sinceMs);
  void clearLogs();
}
