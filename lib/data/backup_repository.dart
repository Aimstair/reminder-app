/// Local backup (DAT-5, FL-17): export everything to a JSON file and import it back. Import merges
/// by `id`; on conflict the newer `updated_at` wins.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';

class BackupPreview {
  const BackupPreview({required this.total, required this.newer, required this.same, required this.data});
  final int total;
  final int newer;
  final int same;
  final Map<String, Object?> data;
}

class BackupRepository {
  BackupRepository(this.db);

  final AppDatabase db;

  static const format = 'reminder-app-backup';

  Future<String> export() async {
    final data = {
      'format': format,
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'reminders': [for (final r in await db.select(db.reminders).get()) r.toJson()],
      'occurrences': [for (final o in await db.select(db.occurrences).get()) o.toJson()],
      'overlays': [for (final o in await db.select(db.calendarOverlays).get()) o.toJson()],
    };
    return jsonEncode(data);
  }

  String fileName(DateTime now) =>
      'reminder-app-backup-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';

  /// Null when [text] isn't a backup ("This file isn't a Reminder App backup.").
  Future<BackupPreview?> preview(String text) async {
    try {
      final data = (jsonDecode(text) as Map).cast<String, Object?>();
      if (data['format'] != format) return null;
      final rows = (data['reminders'] as List).map((j) => ReminderRow.fromJson((j as Map).cast())).toList();
      var newer = 0, same = 0;
      for (final r in rows) {
        final existing = await (db.select(db.reminders)..where((t) => t.id.equals(r.id))).getSingleOrNull();
        if (existing == null || r.updatedAt.isAfter(existing.updatedAt)) {
          newer++;
        } else {
          same++;
        }
      }
      return BackupPreview(total: rows.length, newer: newer, same: same, data: data);
    } catch (_) {
      return null;
    }
  }

  /// Applies a previewed backup; returns how many reminders were added or updated. Resync after.
  Future<int> import(BackupPreview p) async {
    var count = 0;
    await db.transaction(() async {
      for (final j in p.data['reminders'] as List) {
        final r = ReminderRow.fromJson((j as Map).cast());
        final existing = await (db.select(db.reminders)..where((t) => t.id.equals(r.id))).getSingleOrNull();
        if (existing == null || r.updatedAt.isAfter(existing.updatedAt)) {
          await db.into(db.reminders).insertOnConflictUpdate(r);
          count++;
        }
      }
      for (final j in (p.data['occurrences'] as List?) ?? const []) {
        final o = OccurrenceRow.fromJson((j as Map).cast());
        final existing = await (db.select(db.occurrences)..where((t) => t.id.equals(o.id))).getSingleOrNull();
        if (existing == null || o.updatedAt.isAfter(existing.updatedAt)) {
          // Unique (reminder, key): drop a different local row for the same occurrence first.
          await (db.delete(db.occurrences)
                ..where((t) => t.reminderId.equals(o.reminderId) & t.occurrenceKey.equals(o.occurrenceKey) & t.id.equals(o.id).not()))
              .go();
          await db.into(db.occurrences).insertOnConflictUpdate(o);
        }
      }
      for (final j in (p.data['overlays'] as List?) ?? const []) {
        final o = CalendarOverlayRow.fromJson((j as Map).cast());
        final existing = await (db.select(db.calendarOverlays)..where((t) => t.id.equals(o.id))).getSingleOrNull();
        if (existing == null || o.updatedAt.isAfter(existing.updatedAt)) {
          await db.into(db.calendarOverlays).insertOnConflictUpdate(o);
        }
      }
    });
    return count;
  }
}
