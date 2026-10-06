import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/data/app_database.dart';
import 'package:reminder_app/data/occurrence_repository.dart';
import 'package:reminder_app/data/reminder_repository.dart';
import 'package:reminder_app/l10n/gen/app_localizations_en.dart';
import 'package:reminder_app/native/alarm_gateway.dart';
import 'package:reminder_app/notifications/alert_text.dart';
import 'package:reminder_app/services/reminder_service.dart';
import 'package:reminder_core/reminder_core.dart';

import 'reminder_service_test.dart' show FakeGateway;

const _ny = 'America/New_York';
const _prefs = UserPrefs(defaultTimeZone: _ny, deviceTimeZone: _ny);

void main() {
  setUpAll(() => NotificationTextBuilder.init('en'));

  late AppDatabase db;
  late ReminderRepository reminders;
  late OccurrenceRepository occurrences;
  late ReminderService service;
  final now = wallToInstant(DateTime.utc(2026, 10, 5, 14), _ny);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    reminders = ReminderRepository(db, clock: () => now);
    occurrences = OccurrenceRepository(db, reminders, clock: () => now);
    service = ReminderService(
      reminders: reminders,
      occurrences: occurrences,
      gateway: FakeGateway(),
      prefs: () => _prefs,
      text: (p) => NotificationTextBuilder(l10n: AppLocalizationsEn(), prefs: p).call,
      clock: () => now,
    );
  });
  tearDown(() => db.close());

  Future<Reminder> weekly() async {
    final r = Reminder(
      meta: await reminders.newMeta(),
      title: '1:1',
      kind: Kind.meeting,
      context: ReminderContext.work,
      timing: Timing(
        type: TimingType.datetime,
        start: DateTime.utc(2026, 10, 5, 10),
        end: DateTime.utc(2026, 10, 5, 10, 30),
        timeZone: _ny,
      ),
      alertPlan: const [AlertStage(AlertOffset(-10, OffsetUnit.minutes))],
      rrule: 'FREQ=WEEKLY;BYDAY=MO',
    );
    await service.create(r);
    return r;
  }

  test('REC-12 reschedule of a repeating occurrence stores an override, keeps duration', () async {
    final r = await weekly();
    await service.reschedule(r, DateTime.utc(2026, 10, 12, 10), DateTime.utc(2026, 10, 13, 15));
    final occ = (await occurrences.find(r.id, DateTime.utc(2026, 10, 12, 10)))!;
    expect(formatWallDateTime(occ.overrideStart!), '2026-10-13T15:00');
    expect(formatWallDateTime(occ.overrideEnd!), '2026-10-13T15:30');
    expect((await reminders.byId(r.id))!.rrule, 'FREQ=WEEKLY;BYDAY=MO');
  });

  test('NTF-7 reschedule of a one-time reminder moves the reminder itself', () async {
    final r = Reminder(
      meta: await reminders.newMeta(),
      title: 'Pay rent',
      kind: Kind.task,
      context: ReminderContext.personal,
      timing: Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 6)),
      alertPlan: const [AlertStage(AlertOffset.zero)],
    );
    await service.create(r);
    await service.reschedule(r, r.timing.start, DateTime.utc(2026, 10, 9, 9));
    expect(formatWallDate((await reminders.byId(r.id))!.timing.start), '2026-10-09');
  });

  test('REC-13 "this and future" splits the series', () async {
    final r = await weekly();
    final edited = r.copyWith(title: '1:1 (new room)');
    await service.editScoped(r, edited, DateTime.utc(2026, 10, 19, 10), EditScope.thisAndFuture);
    final all = await reminders.watchActive().first;
    expect(all.map((x) => x.title), containsAll(['1:1', '1:1 (new room)']));
    expect(all.firstWhere((x) => x.title == '1:1').rrule, contains('UNTIL=20261018'));
    expect(formatWallDateTime(all.firstWhere((x) => x.title != '1:1').timing.start), '2026-10-19T10:00');
  });

  test('REC-15 delete "this one" skips just that occurrence', () async {
    final r = await weekly();
    await service.deleteScoped(r, DateTime.utc(2026, 10, 12, 10), EditScope.thisOne);
    expect((await occurrences.find(r.id, DateTime.utc(2026, 10, 12, 10)))!.state, OccurrenceState.skipped);
    expect(await reminders.byId(r.id), isNotNull);
  });

  test('REC-7 skipping an after-completion task counts from the skipped date; Undo restores state', () async {
    final r = Reminder(
      meta: await reminders.newMeta(),
      title: 'AC filter',
      kind: Kind.task,
      context: ReminderContext.personal,
      timing: Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 1)),
      alertPlan: const [],
      rrule: 'FREQ=MONTHLY;INTERVAL=3',
      repeatMode: RepeatMode.afterCompletion,
    );
    await service.create(r);
    final before = await service.act(r.id, r.timing.start, JournalActionType.skip);
    expect(before, OccurrenceState.pending);
    expect(formatWallDate((await reminders.byId(r.id))!.timing.start), '2027-01-01');
  });

  test('PRM-7 test reminder is synced 15 s ahead with the test kind', () async {
    final gateway = service.gateway as FakeGateway;
    await service.sendTestReminder(title: 'Test reminder', body: 'it works');
    final t = gateway.synced.singleWhere((a) => a.kind == 'test');
    expect(t.fireAt.difference(now), const Duration(seconds: 15));
    expect(parseAlarmKey(t.key), isNull);
  });
}
