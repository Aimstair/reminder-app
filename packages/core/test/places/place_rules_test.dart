import 'dart:convert';

import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

const _ny = 'America/New_York';
const _prefs = UserPrefs(defaultTimeZone: _ny, deviceTimeZone: _ny);

/// Now = Mon Oct 5 2026, 14:00 New York.
final _now = wallToInstant(DateTime.utc(2026, 10, 5, 14), _ny);

RecordMeta _meta(String id) => RecordMeta(id: id, createdAt: _now, updatedAt: _now, deviceId: 'd');

final _home = Place(meta: _meta('home'), name: 'Home', latitude: 40.7, longitude: -74.0);

Reminder _place(
  String title, {
  PlaceActive active = PlaceActive.anyDay,
  DateTime? date,
  String? rrule,
  bool arrive = true,
  bool leave = false,
  ClockTime? from,
  ClockTime? to,
  PlaceRemind remind = PlaceRemind.firstTime,
  bool paused = false,
}) => Reminder(
  meta: _meta(title),
  title: title,
  kind: Kind.place,
  context: ReminderContext.personal,
  timing: Timing(type: TimingType.date, start: date ?? DateTime.utc(2026, 10, 1)),
  alertPlan: const [],
  rrule: rrule,
  place: PlaceTrigger(
    placeId: 'home',
    onArrive: arrive,
    onLeave: leave,
    active: active,
    hoursFrom: from,
    hoursTo: to,
    remind: remind,
    paused: paused,
  ),
);

Occurrence _occ(Reminder r, DateTime key, {OccurrenceState state = OccurrenceState.pending, DateTime? firedAt}) =>
    Occurrence(
      meta: _meta('${r.id}-occ'),
      reminderId: r.id,
      occurrenceKey: key,
      state: state,
      firedAt: firedAt,
      firedBy: firedAt == null ? null : PlaceEvent.arrive,
    );

DateTime _wall(int d, int h, [int m = 0]) => DateTime.utc(2026, 10, d, h, m);

void main() {
  group('LOC-4 active days', () {
    test('LOC-4 any day has one occurrence keyed on the day it was made', () {
      final r = _place('Buy milk');
      expect(placeOccurrenceKeys(r, DateTime.utc(2026, 10, 5), DateTime.utc(2026, 10, 20)), [DateTime.utc(2026, 10, 1)]);
    });

    test('LOC-4 on a date only that day', () {
      final r = _place('Tickets', active: PlaceActive.onDate, date: DateTime.utc(2026, 10, 10));
      expect(placeOccurrenceKeys(r, DateTime.utc(2026, 10, 5), DateTime.utc(2026, 10, 20)), [DateTime.utc(2026, 10, 10)]);
      expect(placeOccurrenceKeys(r, DateTime.utc(2026, 10, 11), DateTime.utc(2026, 10, 20)), isEmpty);
    });

    test('LOC-4 repeats uses the normal repeat rules', () {
      final r = _place('Bins', active: PlaceActive.repeats, date: DateTime.utc(2026, 10, 6), rrule: 'FREQ=WEEKLY;BYDAY=TU');
      expect(placeOccurrenceKeys(r, DateTime.utc(2026, 10, 5), DateTime.utc(2026, 10, 20)), [
        DateTime.utc(2026, 10, 6),
        DateTime.utc(2026, 10, 13),
        DateTime.utc(2026, 10, 20),
      ]);
    });
  });

  group('LOC-5 hours', () {
    final day = PlaceTrigger(placeId: 'p', hoursFrom: const ClockTime(9, 0), hoursTo: const ClockTime(17, 0));
    final night = PlaceTrigger(placeId: 'p', hoursFrom: const ClockTime(22, 0), hoursTo: const ClockTime(2, 0));

    test('LOC-5 any time covers the whole day', () {
      expect(placeWindowDay(const PlaceTrigger(placeId: 'p'), _wall(5, 3)), DateTime.utc(2026, 10, 5));
    });

    test('LOC-5 between: start inclusive, end exclusive', () {
      expect(placeWindowDay(day, _wall(5, 8, 59)), isNull);
      expect(placeWindowDay(day, _wall(5, 9)), DateTime.utc(2026, 10, 5));
      expect(placeWindowDay(day, _wall(5, 17)), isNull);
    });

    test('LOC-5 a range past midnight belongs to the day it starts', () {
      expect(placeWindowDay(night, _wall(6, 23)), DateTime.utc(2026, 10, 6)); // Tue 23:00
      expect(placeWindowDay(night, _wall(7, 1, 30)), DateTime.utc(2026, 10, 6)); // Wed 01:30 → Tue's window
      expect(placeWindowDay(night, _wall(7, 2)), isNull);
      expect(placeWindowDay(night, _wall(7, 12)), isNull);
    });
  });

  group('LOC-7 firing', () {
    test('LOC-7 rings only for the chosen trigger', () {
      final r = _place('Keys', arrive: false, leave: true);
      expect(placeShouldRing(r, PlaceEvent.leave, _wall(5, 14), now: _now), isTrue);
      expect(placeShouldRing(r, PlaceEvent.arrive, _wall(5, 14), now: _now), isFalse);
    });

    test('LOC-7 arrive + leave both on rings on either', () {
      final r = _place('Plants', leave: true);
      expect(placeShouldRing(r, PlaceEvent.arrive, _wall(5, 14), now: _now), isTrue);
      expect(placeShouldRing(r, PlaceEvent.leave, _wall(5, 14), now: _now), isTrue);
    });

    test('LOC-7 outside the hours is ignored — no catch-up', () {
      final r = _place('Buy milk', from: const ClockTime(9, 0), to: const ClockTime(17, 0));
      expect(placeShouldRing(r, PlaceEvent.arrive, _wall(5, 8, 45), now: _now), isFalse);
      expect(placeShouldRing(r, PlaceEvent.arrive, _wall(5, 9, 5), now: _now), isTrue);
    });

    test('LOC-7 only on active days', () {
      final r = _place('Bins', active: PlaceActive.repeats, date: DateTime.utc(2026, 10, 6), rrule: 'FREQ=WEEKLY;BYDAY=TU');
      expect(placeShouldRing(r, PlaceEvent.arrive, _wall(5, 19), now: _now), isFalse); // Mon
      expect(placeShouldRing(r, PlaceEvent.arrive, _wall(6, 19), now: _now), isTrue); // Tue
    });

    test('LOC-7 first time rings once per occurrence; resolved never rings', () {
      final r = _place('Buy milk');
      final key = DateTime.utc(2026, 10, 1);
      expect(placeShouldRing(r, PlaceEvent.arrive, _wall(5, 14), now: _now, occurrence: _occ(r, key, firedAt: _now)), isFalse);
      expect(
        placeShouldRing(r, PlaceEvent.arrive, _wall(5, 14), now: _now, occurrence: _occ(r, key, state: OccurrenceState.done)),
        isFalse,
      );
    });

    test('LOC-6 every time rings again after an hour, not sooner', () {
      final r = _place('Stretch', remind: PlaceRemind.everyTime);
      final key = DateTime.utc(2026, 10, 1);
      final occ = _occ(r, key, firedAt: _now);
      expect(
        placeShouldRing(r, PlaceEvent.arrive, _wall(5, 14), now: _now.add(const Duration(minutes: 30)), occurrence: occ, lastFire: _now),
        isFalse,
      );
      expect(
        placeShouldRing(r, PlaceEvent.arrive, _wall(5, 15), now: _now.add(const Duration(minutes: 61)), occurrence: occ, lastFire: _now),
        isTrue,
      );
    });

    test('LOC-12 paused never rings and is not active', () {
      final r = _place('Buy milk', paused: true);
      expect(placeShouldRing(r, PlaceEvent.arrive, _wall(5, 14), now: _now), isFalse);
      expect(placeActiveNow(r, _wall(5, 14)), isFalse);
    });

    test('LOC-7 active now follows days, hours and first-time fires', () {
      final r = _place('Buy milk', from: const ClockTime(9, 0), to: const ClockTime(17, 0));
      expect(placeActiveNow(r, _wall(5, 14)), isTrue);
      expect(placeActiveNow(r, _wall(5, 18)), isFalse);
      expect(placeActiveNow(r, _wall(5, 14), occurrence: _occ(r, DateTime.utc(2026, 10, 1), firedAt: _now)), isFalse);
    });
  });

  group('LOC-8 states', () {
    test('LOC-8 a fired place reminder shows under Today, then Overdue the next day (VW-17)', () {
      final r = _place('Buy milk');
      final key = DateTime.utc(2026, 10, 1);
      final fired = wallToInstant(_wall(5, 12), _ny);
      final saved = {AlarmPlanner.occurrenceId(r.id, key): _occ(r, key, firedAt: fired)};
      final today = ScheduleView(prefs: _prefs).build([r], saved, _now);
      expect(today.single.group, ScheduleGroup.today);
      expect(today.single.firedAt, fired);
      final tomorrow = ScheduleView(prefs: _prefs).build([r], saved, _now.add(const Duration(days: 1)));
      expect(tomorrow.single.group, ScheduleGroup.overdue);
    });

    test('LOC-10 waiting place reminders are not on Schedule, Day or Month', () {
      final r = _place('Buy milk');
      expect(ScheduleView(prefs: _prefs).build([r], {}, _now), isEmpty);
      expect(RangeView(prefs: _prefs).build([r], {}, DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 31), _now), isEmpty);
    });

    test('LOC-8 on a date expires after its day; any day never does', () {
      final dated = _place('Tickets', active: PlaceActive.onDate, date: DateTime.utc(2026, 10, 4));
      expect(placeExpired(dated, DateTime.utc(2026, 10, 5), hasOpenFired: false), isTrue);
      expect(placeExpired(dated, DateTime.utc(2026, 10, 5), hasOpenFired: true), isFalse);
      expect(placeExpired(_place('Milk'), DateTime.utc(2030, 1, 1), hasOpenFired: false), isFalse);
    });

    test('LOC-3 place reminders are completable; Done is allowed', () {
      expect(_place('Milk').completable, isTrue);
      expect(transition(OccurrenceState.pending, OccurrenceAction.done, Kind.place), OccurrenceState.done);
    });
  });

  group('LOC-13 geofence set', () {
    ({String arrived, String left}) text(Place p) => (arrived: 'Arrived at ${p.name}', left: 'Left ${p.name}');

    test('LOC-13 one geofence per place with the union of transitions', () {
      final plans = planGeofences(
        reminders: [_place('Bins'), _place('Keys', arrive: false, leave: true)],
        places: {'home': _home},
        saved: {},
        prefs: _prefs,
        now: _now,
        text: text,
      );
      expect(plans, hasLength(1));
      expect(plans.single.arrive && plans.single.leave, isTrue);
      final payload = jsonDecode(plans.single.payloadJson(lateCutoff: const Duration(hours: 2))) as Map;
      expect((payload['reminders'] as List).map((r) => (r as Map)['arrived']), ['Arrived at Home', 'Arrived at Home']);
    });

    test('LOC-13 paused, resolved and out-of-window reminders are left out', () {
      final done = _place('Done one');
      final key = DateTime.utc(2026, 10, 1);
      final plans = planGeofences(
        reminders: [
          _place('Paused', paused: true),
          done,
          _place('Later', active: PlaceActive.onDate, date: DateTime.utc(2026, 11, 30)),
        ],
        places: {'home': _home},
        saved: {AlarmPlanner.occurrenceId(done.id, key): _occ(done, key, state: OccurrenceState.done)},
        prefs: _prefs,
        now: _now,
        text: text,
      );
      expect(plans, isEmpty);
    });

    test('LOC-13 repeating days are listed with their occurrence ids', () {
      final r = _place('Bins', active: PlaceActive.repeats, date: DateTime.utc(2026, 10, 6), rrule: 'FREQ=WEEKLY;BYDAY=TU');
      final plan = planGeofences(reminders: [r], places: {'home': _home}, saved: {}, prefs: _prefs, now: _now, text: text);
      final days = plan.single.reminders.single.days;
      expect(days.map((d) => d.day), [DateTime.utc(2026, 10, 6), DateTime.utc(2026, 10, 13)]);
      expect(days.first.occurrenceId, AlarmPlanner.occurrenceId('Bins', DateTime.utc(2026, 10, 6)));
    });
  });

  test('LOC-9 a snoozed place reminder re-rings as a normal alarm; waiting ones plan nothing', () {
    final r = _place('Buy milk');
    final key = DateTime.utc(2026, 10, 1);
    final at = _now.add(const Duration(hours: 1));
    final occ = Occurrence(
      meta: _meta('o'),
      reminderId: r.id,
      occurrenceKey: key,
      state: OccurrenceState.snoozed,
      snoozedUntil: at,
      firedAt: _now,
      firedBy: PlaceEvent.arrive,
    );
    final planner = AlarmPlanner(prefs: _prefs, text: (c) => (title: c.reminder.title, body: ''));
    expect(planner.plan([r], {}, _now), isEmpty);
    final alarms = planner.plan([r], {AlarmPlanner.occurrenceId(r.id, key): occ}, _now);
    expect(alarms.single.fireAt, at);
    expect(alarms.single.kind, 'place');
  });

  test('LOC-3 trigger survives a JSON round trip', () {
    const t = PlaceTrigger(
      placeId: 'p',
      onLeave: true,
      active: PlaceActive.repeats,
      hoursFrom: ClockTime(22, 0),
      hoursTo: ClockTime(2, 0),
      remind: PlaceRemind.everyTime,
      paused: true,
    );
    final back = PlaceTrigger.fromJson(jsonDecode(jsonEncode(t.toJson())) as Map<String, Object?>);
    expect([back.onArrive, back.onLeave, back.active, back.hoursFrom?.minutes, back.hoursTo?.minutes, back.remind, back.paused],
        [true, true, PlaceActive.repeats, 1320, 120, PlaceRemind.everyTime, true]);
  });

  test('LOC-1 radius stays within 100 m – 2 km', () {
    expect(clampRadius(20), 100);
    expect(clampRadius(5000), 2000);
    expect(_home.copyWith(radiusMeters: 300).radiusMeters, 300);
  });
}
