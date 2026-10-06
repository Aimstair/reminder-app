/// Calendar overlays (CAL-5, CAL-6) in app.db ↔ core [EventOverlay].
/// `scope` is `series`, or `event:<beginMs>` for one instance.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:reminder_core/reminder_core.dart';

import 'app_database.dart';
import 'reminder_repository.dart';

class OverlayRepository {
  OverlayRepository(this._db, this._reminders, {Clock? clock}) : _now = clock ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final ReminderRepository _reminders;
  final Clock _now;

  Future<List<EventOverlay>> all() async =>
      (await (_db.select(_db.calendarOverlays)..where((o) => o.deletedAt.isNull())).get()).map(_fromRow).toList();

  /// Replaces the overlay for this event/instance (CAL-6).
  Future<void> save({
    required String calendarId,
    required String eventId,
    DateTime? instanceBegin,
    List<AlertStage>? alertPlan,
    Kind? kindOverride,
    ReminderContext? contextOverride,
  }) async {
    final scope = instanceBegin == null ? 'series' : 'event:${instanceBegin.millisecondsSinceEpoch}';
    final existing = await (_db.select(_db.calendarOverlays)
          ..where((o) => o.calendarId.equals(calendarId) & o.eventId.equals(eventId) & o.scope.equals(scope)))
        .getSingleOrNull();
    final now = _now();
    final meta = existing == null ? await _reminders.newMeta() : null;
    await _db.into(_db.calendarOverlays).insertOnConflictUpdate(
      CalendarOverlayRow(
        id: existing?.id ?? meta!.id,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        deviceId: existing?.deviceId ?? meta!.deviceId,
        deletedAt: null,
        calendarId: calendarId,
        eventId: eventId,
        seriesId: null,
        alertPlan: jsonEncode([for (final s in alertPlan ?? _plan(existing)) s.toJson()]),
        kindOverride: kindOverride ?? existing?.kindOverride,
        contextOverride: contextOverride ?? existing?.contextOverride,
        scope: scope,
        orphanedAt: null,
      ),
    );
  }

  /// CAL-8: overlays whose event is gone get `orphaned_at` (once); purged after 30 days.
  Future<List<EventOverlay>> markOrphans(Set<String> liveEventKeys) async {
    final now = _now();
    final newlyOrphaned = <EventOverlay>[];
    final rows = await (_db.select(_db.calendarOverlays)..where((o) => o.deletedAt.isNull())).get();
    for (final r in rows) {
      final live = liveEventKeys.contains('${r.calendarId}/${r.eventId}');
      if (live && r.orphanedAt != null) {
        await (_db.update(_db.calendarOverlays)..where((o) => o.id.equals(r.id)))
            .write(const CalendarOverlaysCompanion(orphanedAt: Value(null)));
      } else if (!live && r.orphanedAt == null) {
        await (_db.update(_db.calendarOverlays)..where((o) => o.id.equals(r.id)))
            .write(CalendarOverlaysCompanion(orphanedAt: Value(now)));
        if (_plan(r).isNotEmpty) newlyOrphaned.add(_fromRow(r));
      } else if (!live && now.difference(r.orphanedAt!) > const Duration(days: 30)) {
        await (_db.delete(_db.calendarOverlays)..where((o) => o.id.equals(r.id))).go();
      }
    }
    return newlyOrphaned;
  }

  static List<AlertStage> _plan(CalendarOverlayRow? r) => r == null
      ? const []
      : (jsonDecode(r.alertPlan) as List).map((j) => AlertStage.fromJson((j as Map).cast<String, Object?>())).toList();

  static EventOverlay _fromRow(CalendarOverlayRow r) => EventOverlay(
    id: r.id,
    calendarId: r.calendarId,
    eventId: r.eventId,
    instanceBegin: r.scope.startsWith('event:')
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(r.scope.substring(6)), isUtc: true)
        : null,
    alertPlan: _plan(r),
    kindOverride: r.kindOverride,
    contextOverride: r.contextOverride,
  );
}
