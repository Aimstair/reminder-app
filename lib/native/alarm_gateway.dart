/// Dart side of the native alarm module (docs/architecture.md §5). The only code that talks to Kotlin
/// for alarms; an interface so services can be tested with a fake.
library;

import 'package:reminder_core/reminder_core.dart';

import 'alarm_api.g.dart';

/// Notification buttons recorded natively (NTF-8), plus in-app actions (skip).
enum JournalActionType { done, prepared, snooze, tomorrow, undo, skip }

class JournalAction {
  const JournalAction({required this.id, required this.alarmKey, required this.type, required this.actedAt});
  final int id;
  final String alarmKey;
  final JournalActionType type;

  /// Instant (UTC).
  final DateTime actedAt;
}

/// PRM-5: what the OS currently allows.
class Permissions {
  const Permissions({required this.notifications, required this.exactAlarms, required this.batteryUnrestricted});
  final bool notifications;
  final bool exactAlarms;
  final bool batteryUnrestricted;

  static const allGranted = Permissions(notifications: true, exactAlarms: true, batteryUnrestricted: true);
}

/// One alarm the native side tried to show (SCH-7, PRM-7).
class FireRecord {
  const FireRecord({required this.alarmKey, required this.scheduledAt, required this.firedAt, required this.outcome});
  final String alarmKey;
  final DateTime scheduledAt;
  final DateTime firedAt;

  /// `shown` · `late` · `missed`
  final String outcome;

  Duration get delay => firedAt.difference(scheduledAt);
}

abstract class AlarmGateway {
  /// SCH-4: replace the registered set.
  Future<void> sync(List<PlannedAlarm> alarms);
  Future<List<JournalAction>> readJournal();
  Future<void> markApplied(List<int> ids);

  Future<Permissions> permissions() async => Permissions.allGranted;
  Future<void> requestNotificationPermission() async {}
  Future<void> openExactAlarmSettings() async {}
  Future<void> openBatteryOptimizationSettings() async {}
  Future<List<FireRecord>> fireLog(DateTime since) async => const [];
}

class PigeonAlarmGateway extends AlarmGateway {
  PigeonAlarmGateway([AlarmHostApi? api]) : _api = api ?? AlarmHostApi();
  final AlarmHostApi _api;

  @override
  Future<void> sync(List<PlannedAlarm> alarms) => _api.sync([
    for (final a in alarms)
      AlarmSpec(
        key: a.key,
        fireAtUtcMs: a.fireAt.millisecondsSinceEpoch,
        title: a.title,
        body: a.body,
        kind: a.kind,
        lateCutoffMs: a.lateCutoff.inMilliseconds,
      ),
  ]);

  @override
  Future<List<JournalAction>> readJournal() async {
    final entries = await _api.readJournal();
    return [
      for (final e in entries)
        if (_type(e.action) case final t?)
          JournalAction(
            id: e.id,
            alarmKey: e.alarmKey,
            type: t,
            actedAt: DateTime.fromMillisecondsSinceEpoch(e.actedAtMs, isUtc: true),
          ),
    ];
  }

  @override
  Future<void> markApplied(List<int> ids) => _api.markApplied(ids);

  @override
  Future<Permissions> permissions() async {
    final p = await _api.getPermissionState();
    return Permissions(
      notifications: p.notifications,
      exactAlarms: p.exactAlarms,
      batteryUnrestricted: p.ignoringBatteryOptimizations,
    );
  }

  @override
  Future<void> requestNotificationPermission() => _api.requestNotificationPermission();

  @override
  Future<void> openExactAlarmSettings() => _api.openExactAlarmSettings();

  @override
  Future<void> openBatteryOptimizationSettings() => _api.openBatteryOptimizationSettings();

  @override
  Future<List<FireRecord>> fireLog(DateTime since) async => [
    for (final f in await _api.getFireLog(since.millisecondsSinceEpoch))
      FireRecord(
        alarmKey: f.alarmKey,
        scheduledAt: DateTime.fromMillisecondsSinceEpoch(f.scheduledAtMs, isUtc: true),
        firedAt: DateTime.fromMillisecondsSinceEpoch(f.firedAtMs, isUtc: true),
        outcome: f.outcome,
      ),
  ];

  /// Kotlin records actions as `app.aimstair.reminder_app.DONE` etc.
  static JournalActionType? _type(String action) => switch (action.split('.').last) {
    'DONE' => JournalActionType.done,
    'PREPARED' => JournalActionType.prepared,
    'SNOOZE' => JournalActionType.snooze,
    'TOMORROW' => JournalActionType.tomorrow,
    'UNDO' => JournalActionType.undo,
    _ => null,
  };
}
