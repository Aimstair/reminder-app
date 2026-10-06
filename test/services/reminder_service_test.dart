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

const _ny = 'America/New_York';
const _prefs = UserPrefs(defaultTimeZone: _ny, deviceTimeZone: _ny);

class FakeGateway extends AlarmGateway {
  List<PlannedAlarm> synced = [];
  final journal = <JournalAction>[];
  final applied = <int>[];

  @override
  Future<void> sync(List<PlannedAlarm> alarms) async => synced = alarms;
  @override
  Future<List<JournalAction>> readJournal() async => List.of(journal);
  @override
  Future<void> markApplied(List<int> ids) async {
    applied.addAll(ids);
    journal.removeWhere((j) => ids.contains(j.id));
  }
}

String _local(DateTime instant) => formatWallDateTime(instantToWall(instant, _ny));

void main() {
  setUpAll(() => NotificationTextBuilder.init('en'));

  late AppDatabase db;
  late ReminderRepository reminders;
  late FakeGateway gateway;
  late ReminderService service;
  var now = wallToInstant(DateTime.utc(2026, 10, 5, 14), _ny);

  setUp(() {
    now = wallToInstant(DateTime.utc(2026, 10, 5, 14), _ny);
    db = AppDatabase(NativeDatabase.memory());
    reminders = ReminderRepository(db, clock: () => now);
    gateway = FakeGateway();
    service = ReminderService(
      reminders: reminders,
      occurrences: OccurrenceRepository(db, reminders, clock: () => now),
      gateway: gateway,
      prefs: () => _prefs,
      text: (p) => NotificationTextBuilder(l10n: AppLocalizationsEn(), prefs: p).call,
      clock: () => now,
    );
  });
  tearDown(() => db.close());

  Future<Reminder> birthday() async => Reminder(
    meta: await reminders.newMeta(),
    title: "Mom's birthday",
    kind: Kind.occasion,
    context: ReminderContext.personal,
    timing: Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 12)),
    alertPlan: defaultAlertPlan(Kind.occasion, TimingType.date),
    rrule: 'FREQ=YEARLY',
  );

  JournalAction tap(int id, String key, JournalActionType type) =>
      JournalAction(id: id, alarmKey: key, type: type, actedAt: now);

  test('FL-2 saving a reminder syncs its alarms with wording from copy.md', () async {
    await service.create(await birthday());
    expect(gateway.synced.map((a) => (_local(a.fireAt), a.body)), [
      ('2026-10-11T09:00', 'In 1 day · Tomorrow'),
      ('2026-10-12T09:00', 'Today'),
    ]);
    expect(gateway.synced.first.title, "Mom's birthday");
    expect(gateway.synced.first.kind, 'occasion_prep');
  });

  test('DAT-2 deleting cancels alarms; restore brings them back', () async {
    final r = await birthday();
    await service.create(r);
    await service.delete(r.id);
    expect(gateway.synced, isEmpty);
    await service.restore(r.id);
    expect(gateway.synced, hasLength(2));
  });

  test("OCC-3 I'm prepared from a notification keeps only the day-of alert", () async {
    final r = await birthday();
    await service.create(r);
    final key = gateway.synced.first.key;
    gateway.journal.add(tap(1, key, JournalActionType.prepared));
    await service.onAppStart();
    expect(gateway.applied, [1]);
    expect(gateway.synced.map((a) => a.body), ['Today']);
  });

  test('OCC-4 Done from a notification cancels the remaining alerts', () async {
    final r = await birthday();
    await service.create(r);
    gateway.journal.add(tap(1, gateway.synced.first.key, JournalActionType.done));
    await service.onAppStart();
    expect(gateway.synced, isEmpty);
  });

  test('NTF-4 Snooze re-plans the alert 1 hour later', () async {
    final task = Reminder(
      meta: await reminders.newMeta(),
      title: 'Pay rent',
      kind: Kind.task,
      context: ReminderContext.personal,
      timing: Timing(type: TimingType.datetime, start: DateTime.utc(2026, 10, 5, 14, 30), timeZone: _ny),
      alertPlan: defaultAlertPlan(Kind.task, TimingType.datetime),
    );
    await service.create(task);
    final key = gateway.synced.single.key;
    now = wallToInstant(DateTime.utc(2026, 10, 5, 14, 30), _ny); // alert fired, user taps Snooze 1h
    gateway.journal.add(tap(1, key, JournalActionType.snooze));
    await service.onAppStart();
    expect(gateway.synced.map((a) => _local(a.fireAt)), ['2026-10-05T15:30']);
  });

  test('REC-6 Done on a repeat-after-completion task moves its due date', () async {
    final filter = Reminder(
      meta: await reminders.newMeta(),
      title: 'Change AC filter',
      kind: Kind.task,
      context: ReminderContext.personal,
      timing: Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 1)),
      alertPlan: defaultAlertPlan(Kind.task, TimingType.date),
      rrule: 'FREQ=MONTHLY;INTERVAL=3',
      repeatMode: RecurrenceMode.afterCompletion,
    );
    await service.create(filter);
    gateway.journal.add(
      tap(1, '${AlarmPlanner.occurrenceId(filter.id, DateTime.utc(2026, 10, 1))}:0:0', JournalActionType.done),
    );
    await service.onAppStart();
    final moved = (await reminders.byId(filter.id))!;
    expect(moved.timing.start, DateTime.utc(2027, 1, 5)); // done Oct 5 → +3 months
  });

  test('unknown or stale journal entries are marked applied and ignored', () async {
    gateway.journal.add(tap(7, '1791298405716:test:0', JournalActionType.done)); // PRM-7 test reminder
    await service.onAppStart();
    expect(gateway.applied, [7]);
  });
}
