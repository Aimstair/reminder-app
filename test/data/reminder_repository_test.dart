import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/data/app_database.dart';
import 'package:reminder_app/data/reminder_repository.dart';
import 'package:reminder_core/reminder_core.dart';

void main() {
  late AppDatabase db;
  late ReminderRepository repo;
  var now = DateTime.utc(2026, 10, 5, 18);

  setUp(() {
    now = DateTime.utc(2026, 10, 5, 18);
    db = AppDatabase(NativeDatabase.memory());
    repo = ReminderRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  Future<Reminder> birthday() async => Reminder(
    meta: await repo.newMeta(),
    title: "Mom's birthday",
    kind: Kind.occasion,
    context: ReminderContext.personal,
    timing: Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 12)),
    alertPlan: defaultAlertPlan(Kind.occasion, TimingType.date),
    rrule: 'FREQ=YEARLY',
    source: const ContactSource(contactId: 'c42', field: 'birthday'),
    rawInput: "Mom's birthday Oct 12",
  );

  Future<Reminder> meeting() async => Reminder(
    meta: await repo.newMeta(),
    title: 'Call with Tokyo team',
    kind: Kind.meeting,
    context: ReminderContext.work,
    timing: Timing(
      type: TimingType.datetime,
      start: DateTime.utc(2026, 10, 6, 9),
      end: DateTime.utc(2026, 10, 6, 9, 30),
      timeZone: 'Asia/Tokyo',
      timeZoneSetManually: true,
    ),
    alertPlan: const [AlertStage(AlertOffset(-10, OffsetUnit.minutes))],
    nagInterval: null,
  );

  test('DAT-4 device id is created once and stays stable', () async {
    final a = await repo.deviceId();
    final b = await repo.deviceId();
    expect(a, b);
    expect(a, hasLength(36));
  });

  test('BIL-1 BIL-2 a bill keeps its kind and amount; other types never store one', () async {
    final rent = (await birthday()).copyWith(
      kind: Kind.bill,
      billKind: BillKind.subscription,
      amount: () => const Money(120000, 'USD'),
    );
    await repo.insert(rent);
    final back = (await repo.byId(rent.id))!;
    expect([back.kind, back.billKind, back.amount], [Kind.bill, BillKind.subscription, const Money(120000, 'USD')]);

    final task = (await meeting()).copyWith(amount: () => const Money(5, 'USD'));
    await repo.insert(task);
    expect((await repo.byId(task.id))!.amount, isNull);
  });

  test('ATT-1 links and files round-trip; none stays an empty list', () async {
    final m = (await meeting()).copyWith(
      attachments: [
        Attachment.link('zoom.us/j/123', name: 'Zoom'),
        const Attachment(
          kind: AttachmentKind.file,
          uri: '/files/a/agenda.pdf',
          name: 'Agenda.pdf',
          mime: 'application/pdf',
          size: 42,
        ),
      ],
    );
    await repo.insert(m);
    final back = (await repo.byId(m.id))!;
    expect(back.attachments, m.attachments);
    final plain = await birthday();
    await repo.insert(plain);
    expect((await repo.byId(plain.id))!.attachments, isEmpty);
  });

  test('round-trips every field (date occasion from Contacts)', () async {
    final r = await birthday();
    await repo.insert(r);
    final back = (await repo.byId(r.id))!;
    expect(back.title, "Mom's birthday");
    expect(back.kind, Kind.occasion);
    expect(back.timing.type, TimingType.date);
    expect(back.timing.start, DateTime.utc(2026, 10, 12));
    expect(back.timing.timeZone, isNull); // TIM-4
    expect(back.rrule, 'FREQ=YEARLY');
    expect(back.alertPlan.map((s) => '${s.offset}'), ['-7d', '-1d', '0']);
    expect((back.source as ContactSource).contactId, 'c42');
    expect(back.rawInput, "Mom's birthday Oct 12");
    expect(back.completable, isTrue);
    expect(back.meta.deviceId, await repo.deviceId());
  });

  test('round-trips a zoned datetime meeting (TIM-2, TIM-7)', () async {
    final r = await meeting();
    await repo.insert(r);
    final back = (await repo.byId(r.id))!;
    expect(back.timing.start, DateTime.utc(2026, 10, 6, 9));
    expect(back.timing.end, DateTime.utc(2026, 10, 6, 9, 30));
    expect(back.timing.timeZone, 'Asia/Tokyo');
    expect(back.timing.timeZoneSetManually, isTrue);
    expect(back.completable, isFalse);
  });

  test('update bumps updatedAt but keeps createdAt', () async {
    final r = await birthday();
    await repo.insert(r);
    now = now.add(const Duration(minutes: 5));
    await repo.update(r);
    final back = (await repo.byId(r.id))!;
    expect(back.meta.createdAt, r.meta.createdAt);
    expect(back.meta.updatedAt, now);
  });

  test('DAT-1 soft delete hides from the active list; restore brings it back', () async {
    final a = await birthday();
    final b = await meeting();
    await repo.insert(a);
    await repo.insert(b);
    expect((await repo.watchActive().first).map((r) => r.id), containsAll([a.id, b.id]));

    await repo.softDelete(a.id);
    expect((await repo.watchActive().first).map((r) => r.id), [b.id]);
    expect((await repo.byId(a.id))!.meta.isDeleted, isTrue);

    await repo.restore(a.id);
    expect((await repo.watchActive().first).map((r) => r.id), containsAll([a.id, b.id]));
  });

  test('DAT-1 purge removes soft-deleted rows only after 30 days', () async {
    final r = await birthday();
    await repo.insert(r);
    await repo.softDelete(r.id);

    now = now.add(const Duration(days: 29));
    expect(await repo.purgeDeleted(), 0);

    now = now.add(const Duration(days: 2));
    expect(await repo.purgeDeleted(), 1);
    expect(await repo.byId(r.id), isNull);
  });
}
