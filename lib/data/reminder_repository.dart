/// Reminders in app.db ↔ core model (docs/architecture.md §4). The only code that writes reminder rows.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:reminder_core/reminder_core.dart';

import 'app_database.dart';

typedef Clock = DateTime Function();

class ReminderRepository {
  ReminderRepository(this._db, {Clock? clock}) : _now = clock ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final Clock _now;

  /// DAT-1: soft-deleted rows are purged after this long.
  static const purgeAfter = Duration(days: 30);

  // ---- device id (DAT-4) ----

  static const _deviceIdKey = 'device_id';

  /// Stable per-install id, created on first use.
  Future<String> deviceId() async {
    final row = await (_db.select(_db.prefs)..where((p) => p.key.equals(_deviceIdKey))).getSingleOrNull();
    if (row != null) return jsonDecode(row.value) as String;
    final id = newId();
    await _db
        .into(_db.prefs)
        .insert(PrefsCompanion.insert(key: _deviceIdKey, value: jsonEncode(id), updatedAt: _now()));
    return id;
  }

  /// New metadata for a record created now on this device.
  Future<RecordMeta> newMeta() async {
    final now = _now();
    return RecordMeta(id: newId(), createdAt: now, updatedAt: now, deviceId: await deviceId());
  }

  // ---- writes ----

  Future<void> insert(Reminder r) => _db.into(_db.reminders).insert(_toRow(r));

  /// Saves changes and bumps updatedAt (sync relies on it — architecture.md §9).
  Future<Reminder> update(Reminder r) async {
    final updated = _withMeta(r, r.meta.touched(_now()));
    await _db.update(_db.reminders).replace(_toRow(updated));
    return updated;
  }

  /// DAT-1: hidden immediately, purged after 30 days.
  Future<void> softDelete(String id) => _setDeleted(id, _now());

  /// Undo of a delete (OCC-5 snackbar).
  Future<void> restore(String id) => _setDeleted(id, null);

  Future<void> _setDeleted(String id, DateTime? at) async {
    await (_db.update(
      _db.reminders,
    )..where((t) => t.id.equals(id))).write(RemindersCompanion(deletedAt: Value(at), updatedAt: Value(_now())));
  }

  /// DAT-1: removes soft-deleted reminders (and their occurrences) older than [purgeAfter].
  Future<int> purgeDeleted() async {
    final cutoff = _now().subtract(purgeAfter);
    return _db.transaction(() async {
      final old = await (_db.select(_db.reminders)..where((t) => t.deletedAt.isSmallerThanValue(cutoff))).get();
      final ids = old.map((r) => r.id).toList();
      if (ids.isEmpty) return 0;
      await (_db.delete(_db.occurrences)..where((o) => o.reminderId.isIn(ids))).go();
      return (_db.delete(_db.reminders)..where((t) => t.id.isIn(ids))).go();
    });
  }

  // ---- reads ----

  Future<Reminder?> byId(String id) async {
    final row = await (_db.select(_db.reminders)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Active, not-deleted reminders — updates live as rows change.
  Stream<List<Reminder>> watchActive() {
    final q = _db.select(_db.reminders)
      ..where((t) => t.deletedAt.isNull() & t.status.equalsValue(ReminderStatus.active))
      ..orderBy([(t) => OrderingTerm.asc(t.startLocal)]);
    return q.watch().map((rows) => rows.map(_fromRow).toList());
  }

  // ---- mapping ----

  static Reminder _withMeta(Reminder r, RecordMeta meta) => Reminder(
    meta: meta,
    title: r.title,
    notes: r.notes,
    rawInput: r.rawInput,
    kind: r.kind,
    context: r.context,
    timing: r.timing,
    alertPlan: r.alertPlan,
    rrule: r.rrule,
    repeatMode: r.repeatMode,
    nagInterval: r.nagInterval,
    source: r.source,
    templateId: r.templateId,
    status: r.status,
  );

  static String _wall(DateTime d, TimingType t) => t == TimingType.date ? formatWallDate(d) : formatWallDateTime(d);

  static ReminderRow _toRow(Reminder r) => ReminderRow(
    id: r.meta.id,
    createdAt: r.meta.createdAt,
    updatedAt: r.meta.updatedAt,
    deviceId: r.meta.deviceId,
    deletedAt: r.meta.deletedAt,
    title: r.title,
    notes: r.notes,
    rawInput: r.rawInput,
    kind: r.kind,
    context: r.context,
    timingType: r.timing.type,
    startLocal: _wall(r.timing.start, r.timing.type),
    endLocal: r.timing.end == null ? null : _wall(r.timing.end!, r.timing.type),
    tz: r.timing.timeZone,
    tzSetManually: r.timing.timeZoneSetManually,
    rrule: r.rrule,
    repeatMode: r.repeatMode,
    alertPlan: jsonEncode(r.alertPlan.map((s) => s.toJson()).toList()),
    nagMinutes: r.nagInterval?.inMinutes,
    completable: r.completable,
    source: jsonEncode(r.source.toJson()),
    templateId: r.templateId,
    status: r.status,
  );

  static Reminder _fromRow(ReminderRow row) => Reminder(
    meta: RecordMeta(
      id: row.id,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deviceId: row.deviceId,
      deletedAt: row.deletedAt,
    ),
    title: row.title,
    notes: row.notes,
    rawInput: row.rawInput,
    kind: row.kind,
    context: row.context,
    timing: Timing(
      type: row.timingType,
      start: parseWall(row.startLocal),
      end: row.endLocal == null ? null : parseWall(row.endLocal!),
      timeZone: row.tz,
      timeZoneSetManually: row.tzSetManually,
    ),
    alertPlan: (jsonDecode(row.alertPlan) as List)
        .map((j) => AlertStage.fromJson((j as Map).cast<String, Object?>()))
        .toList(),
    rrule: row.rrule,
    repeatMode: row.repeatMode,
    nagInterval: row.nagMinutes == null ? null : Duration(minutes: row.nagMinutes!),
    source: ReminderSource.fromJson((jsonDecode(row.source) as Map).cast<String, Object?>()),
    templateId: row.templateId,
    status: row.status,
  );
}
