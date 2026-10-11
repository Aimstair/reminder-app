import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/data/app_database.dart';
import 'package:reminder_app/data/occurrence_repository.dart';
import 'package:reminder_app/data/place_repository.dart';
import 'package:reminder_app/data/reminder_repository.dart';
import 'package:reminder_app/l10n/gen/app_localizations_en.dart';
import 'package:reminder_app/native/alarm_gateway.dart';
import 'package:reminder_app/native/place_gateway.dart';
import 'package:reminder_app/notifications/alert_text.dart';
import 'package:reminder_app/services/place_service.dart';
import 'package:reminder_app/services/reminder_service.dart';
import 'package:reminder_core/reminder_core.dart';

import 'reminder_service_test.dart' show FakeGateway;

const _ny = 'America/New_York';
const _prefs = UserPrefs(defaultTimeZone: _ny, deviceTimeZone: _ny);

class FakePlaceGateway extends PlaceGateway {
  List<GeofencePlan> synced = [];

  @override
  Future<({int registered, int requested, String? error})> sync(List<GeofencePlan> plans, Duration lateCutoff) async {
    synced = plans;
    return (registered: plans.length, requested: plans.length, error: null);
  }
}

void main() {
  setUpAll(() => NotificationTextBuilder.init('en'));

  late AppDatabase db;
  late ReminderRepository reminders;
  late OccurrenceRepository occurrences;
  late FakeGateway alarms;
  late FakePlaceGateway geofences;
  late ReminderService service;
  late PlaceService places;
  var now = wallToInstant(DateTime.utc(2026, 10, 5, 14), _ny);

  setUp(() async {
    now = wallToInstant(DateTime.utc(2026, 10, 5, 14), _ny);
    db = AppDatabase(NativeDatabase.memory());
    reminders = ReminderRepository(db, clock: () => now);
    occurrences = OccurrenceRepository(db, reminders, clock: () => now);
    alarms = FakeGateway();
    geofences = FakePlaceGateway();
    final l10n = AppLocalizationsEn();
    late PlaceService p;
    service = ReminderService(
      reminders: reminders,
      occurrences: occurrences,
      gateway: alarms,
      prefs: () => _prefs,
      text: (prefs) => NotificationTextBuilder(l10n: l10n, prefs: prefs, placeName: (id) => p.byId[id]?.name).call,
      clock: () => now,
    );
    p = PlaceService(
      places: PlaceRepository(db, reminders, clock: () => now),
      reminders: reminders,
      service: service,
      gateway: geofences,
      prefs: () => _prefs,
      text: (place) => (arrived: l10n.notifPlaceArrived(place.name), left: l10n.notifPlaceLeft(place.name)),
      clock: () => now,
    );
    places = p;
    await places.start();
    service.afterSync = places.syncGeofences;
    service.extraHousekeeping = places.archiveExpired;
  });
  tearDown(() async {
    await places.dispose();
    await db.close();
  });

  Future<Reminder> buyMilk(Place at) async => Reminder(
    meta: await reminders.newMeta(),
    title: 'Buy milk',
    kind: Kind.place,
    context: ReminderContext.personal,
    timing: Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 5)),
    alertPlan: const [],
    place: PlaceTrigger(placeId: at.id),
  );

  Future<Place> traderJoes() =>
      places.createPlace(name: "Trader Joe's", latitude: 40.7, longitude: -74.0, icon: PlaceIcon.store);

  String key(Reminder r, String suffix) => '${AlarmPlanner.occurrenceId(r.id, DateTime.utc(2026, 10, 5))}:$suffix';

  test('LOC-13 saving a place reminder registers its place geofence', () async {
    final tj = await traderJoes();
    await service.create(await buyMilk(tj));
    await places.syncGeofences();
    expect(geofences.synced.single.place.id, tj.id);
    expect(geofences.synced.single.reminders.single.arrivedBody, "Arrived at Trader Joe's");
    expect(alarms.synced, isEmpty, reason: 'place reminders have no timed alarms');
  });

  test('LOC-8 an arrival from the journal shows it under Today; Done resolves it', () async {
    final r = await buyMilk(await traderJoes());
    await service.create(r);
    alarms.journal.add(JournalAction(id: 1, alarmKey: key(r, 'place:1'), type: JournalActionType.arrived, actedAt: now));
    await service.applyJournal();
    final occ = (await occurrences.forReminder(r.id)).single;
    expect(occ.firedAt, now);
    expect(occ.firedBy, PlaceEvent.arrive);
    final items = ScheduleView(prefs: _prefs).build([r], await occurrences.byPlannerId(), now);
    expect(items.single.group, ScheduleGroup.today);

    alarms.journal.add(JournalAction(id: 2, alarmKey: key(r, 'place:1'), type: JournalActionType.done, actedAt: now));
    await service.applyJournal();
    expect((await occurrences.forReminder(r.id)).single.state, OccurrenceState.done);
  });

  test('LOC-9 Next time sends it back to waiting; In 1 hour re-rings as an alarm', () async {
    final r = await buyMilk(await traderJoes());
    await service.create(r);
    alarms.journal
      ..add(JournalAction(id: 1, alarmKey: key(r, 'place:1'), type: JournalActionType.arrived, actedAt: now))
      ..add(JournalAction(id: 2, alarmKey: key(r, 'place:1'), type: JournalActionType.snooze, actedAt: now));
    await service.applyJournal();
    final planned = await service.resync();
    expect(planned.single.kind, 'place');
    expect(planned.single.body, "Arrived at Trader Joe's");
    expect(planned.single.fireAt, now.add(const Duration(hours: 1)));

    alarms.journal.add(JournalAction(id: 3, alarmKey: key(r, 'place:1'), type: JournalActionType.nextTime, actedAt: now));
    await service.applyJournal();
    final occ = (await occurrences.forReminder(r.id)).single;
    expect(occ.firedAt, isNull);
    expect(ScheduleView(prefs: _prefs).build([r], await occurrences.byPlannerId(), now), isEmpty);
  });

  test('LOC-2 deleting a place deletes its reminders; Undo brings both back', () async {
    final tj = await traderJoes();
    final r = await buyMilk(tj);
    await service.create(r);
    final ids = await places.deletePlace(tj);
    expect(ids, [r.id]);
    expect(await reminders.watchActive().first, isEmpty);
    expect(await places.places.all(), isEmpty);
    await places.restorePlace(tj, ids);
    expect((await reminders.watchActive().first).single.id, r.id);
    expect((await places.places.all()).single.id, tj.id);
  });

  test('LOC-12 a paused reminder is left out of the geofences', () async {
    final r = await buyMilk(await traderJoes());
    await service.create(r);
    await places.setPaused((await reminders.byId(r.id))!, true);
    await places.syncGeofences();
    expect(geofences.synced, isEmpty);
  });

  test('LOC-8 an "On a date" reminder whose day passed is archived', () async {
    final tj = await traderJoes();
    final r = Reminder(
      meta: await reminders.newMeta(),
      title: 'Bring the tickets',
      kind: Kind.place,
      context: ReminderContext.personal,
      timing: Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 4)),
      alertPlan: const [],
      place: PlaceTrigger(placeId: tj.id, active: PlaceActive.onDate),
    );
    await service.create(r);
    await service.housekeeping();
    expect((await reminders.byId(r.id))!.status, ReminderStatus.archived);
  });
}
