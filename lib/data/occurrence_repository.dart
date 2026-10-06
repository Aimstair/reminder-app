/// Occurrences in app.db ↔ core model. Rows exist only when an occurrence's state changed or it is in
/// the planning window (OCC-6).
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:reminder_core/reminder_core.dart';

import 'app_database.dart';
import 'reminder_repository.dart';

class OccurrenceRepository {
  OccurrenceRepository(this._db, this._reminders, {Clock? clock}) : _now = clock ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final ReminderRepository _reminders;
  final Clock _now;

  /// All live occurrences keyed by planner occurrence id (`reminderId~yyyyMMddHHmm`).
  Future<Map<String, Occurrence>> byPlannerId() async {
    final rows = await (_db.select(_db.occurrences)..where((o) => o.deletedAt.isNull())).get();
    return {for (final r in rows) _plannerId(r): _fromRow(r)};
  }

  /// Live view of [byPlannerId] for the UI.
  Stream<Map<String, Occurrence>> watchByPlannerId() =>
      (_db.select(_db.occurrences)..where((o) => o.deletedAt.isNull())).watch().map(
        (rows) => {for (final r in rows) _plannerId(r): _fromRow(r)},
      );

  Future<Occurrence?> find(String reminderId, DateTime occurrenceKey) async {
    final row =
        await (_db.select(_db.occurrences)..where(
              (o) => o.reminderId.equals(reminderId) & o.occurrenceKey.equals(formatWallDateTime(occurrenceKey)),
            ))
            .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Insert or update (unique on reminder + occurrence key).
  Future<Occurrence> save({
    required String reminderId,
    required DateTime occurrenceKey,
    required OccurrenceState state,
    DateTime? snoozedUntil,
    DateTime? resolvedAt,
  }) async {
    final existing = await find(reminderId, occurrenceKey);
    final now = _now();
    final meta = existing?.meta.touched(now) ?? await _reminders.newMeta();
    final occ = Occurrence(
      meta: meta,
      reminderId: reminderId,
      occurrenceKey: occurrenceKey,
      state: state,
      overrideStart: existing?.overrideStart,
      overrideEnd: existing?.overrideEnd,
      overrideAlertPlan: existing?.overrideAlertPlan,
      snoozedUntil: snoozedUntil,
      resolvedAt: resolvedAt,
      alertsSent: existing?.alertsSent ?? const {},
    );
    await _db.into(_db.occurrences).insertOnConflictUpdate(_toRow(occ));
    return occ;
  }

  static String _plannerId(OccurrenceRow r) => AlarmPlanner.occurrenceId(r.reminderId, parseWall(r.occurrenceKey));

  static String? _wall(DateTime? d) => d == null ? null : formatWallDateTime(d);

  static OccurrenceRow _toRow(Occurrence o) => OccurrenceRow(
    id: o.meta.id,
    createdAt: o.meta.createdAt,
    updatedAt: o.meta.updatedAt,
    deviceId: o.meta.deviceId,
    deletedAt: o.meta.deletedAt,
    reminderId: o.reminderId,
    occurrenceKey: formatWallDateTime(o.occurrenceKey),
    state: o.state,
    overrideStart: _wall(o.overrideStart),
    overrideEnd: _wall(o.overrideEnd),
    overrideAlertPlan: o.overrideAlertPlan == null
        ? null
        : jsonEncode(o.overrideAlertPlan!.map((s) => s.toJson()).toList()),
    snoozedUntil: o.snoozedUntil,
    resolvedAt: o.resolvedAt,
    alertsSent: jsonEncode(o.alertsSent.toList()),
  );

  static Occurrence _fromRow(OccurrenceRow r) => Occurrence(
    meta: RecordMeta(
      id: r.id,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      deviceId: r.deviceId,
      deletedAt: r.deletedAt,
    ),
    reminderId: r.reminderId,
    occurrenceKey: parseWall(r.occurrenceKey),
    state: r.state,
    overrideStart: r.overrideStart == null ? null : parseWall(r.overrideStart!),
    overrideEnd: r.overrideEnd == null ? null : parseWall(r.overrideEnd!),
    overrideAlertPlan: r.overrideAlertPlan == null
        ? null
        : (jsonDecode(r.overrideAlertPlan!) as List)
              .map((j) => AlertStage.fromJson((j as Map).cast<String, Object?>()))
              .toList(),
    snoozedUntil: r.snoozedUntil,
    resolvedAt: r.resolvedAt,
    alertsSent: (jsonDecode(r.alertsSent) as List).cast<String>().toSet(),
  );
}
