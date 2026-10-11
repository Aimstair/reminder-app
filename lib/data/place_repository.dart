/// Saved places in app.db ↔ core model (LOC-1, LOC-2). The only code that writes place rows.
library;

import 'package:drift/drift.dart';
import 'package:reminder_core/reminder_core.dart';

import 'app_database.dart';
import 'reminder_repository.dart';

class PlaceRepository {
  PlaceRepository(this._db, this._reminders, {Clock? clock}) : _now = clock ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final ReminderRepository _reminders;
  final Clock _now;

  /// New place with fresh metadata (DAT-4).
  Future<Place> create({
    required String name,
    required double latitude,
    required double longitude,
    String? address,
    int radiusMeters = placeDefaultRadius,
    PlaceIcon icon = PlaceIcon.pin,
    PlaceColor color = PlaceColor.teal,
  }) async {
    final p = Place(
      meta: await _reminders.newMeta(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      address: address,
      radiusMeters: clampRadius(radiusMeters),
      icon: icon,
      color: color,
    );
    await _db.into(_db.places).insert(_toRow(p));
    return p;
  }

  /// LOC-2: edits apply to every reminder at this place (they reference it by id).
  Future<Place> update(Place p) async {
    final updated = p.copyWith(meta: p.meta.touched(_now()));
    await _db.update(_db.places).replace(_toRow(updated));
    return updated;
  }

  /// DAT-1 soft delete / Undo.
  Future<void> setDeleted(String id, bool deleted) =>
      (_db.update(_db.places)..where((t) => t.id.equals(id))).write(
        PlacesCompanion(deletedAt: Value(deleted ? _now() : null), updatedAt: Value(_now())),
      );

  Future<Place?> byId(String id) async {
    final row = await (_db.select(_db.places)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Live, not-deleted places, by name.
  Stream<List<Place>> watchAll() =>
      (_db.select(_db.places)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch()
          .map((rows) => rows.map(_fromRow).toList());

  Future<List<Place>> all() => watchAll().first;

  /// Every row incl. soft-deleted ones (backup, DAT-5).
  Future<List<Place>> everything() async => (await _db.select(_db.places).get()).map(_fromRow).toList();

  static PlaceRow _toRow(Place p) => PlaceRow(
    id: p.meta.id,
    createdAt: p.meta.createdAt,
    updatedAt: p.meta.updatedAt,
    deviceId: p.meta.deviceId,
    deletedAt: p.meta.deletedAt,
    name: p.name,
    latitude: p.latitude,
    longitude: p.longitude,
    address: p.address,
    radiusMeters: p.radiusMeters,
    icon: p.icon,
    color: p.color,
  );

  static Place _fromRow(PlaceRow r) => Place(
    meta: RecordMeta(
      id: r.id,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      deviceId: r.deviceId,
      deletedAt: r.deletedAt,
    ),
    name: r.name,
    latitude: r.latitude,
    longitude: r.longitude,
    address: r.address,
    radiusMeters: r.radiusMeters,
    icon: r.icon,
    color: r.color,
  );
}
