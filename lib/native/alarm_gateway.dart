/// Dart side of the native alarm module (docs/architecture.md §5). The only code that talks to Kotlin
/// for alarms; an interface so services can be tested with a fake.
library;

import 'package:reminder_core/reminder_core.dart';

import 'alarm_api.g.dart';

/// Notification buttons recorded natively (NTF-8).
enum JournalActionType { done, prepared, snooze, tomorrow, undo }

class JournalAction {
  const JournalAction({required this.id, required this.alarmKey, required this.type, required this.actedAt});
  final int id;
  final String alarmKey;
  final JournalActionType type;

  /// Instant (UTC).
  final DateTime actedAt;
}

abstract class AlarmGateway {
  /// SCH-4: replace the registered set.
  Future<void> sync(List<PlannedAlarm> alarms);
  Future<List<JournalAction>> readJournal();
  Future<void> markApplied(List<int> ids);
}

class PigeonAlarmGateway implements AlarmGateway {
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
