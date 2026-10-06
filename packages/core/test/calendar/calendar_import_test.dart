import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

CalendarEvent _e({
  String title = 'Team sync',
  bool allDay = false,
  bool yearly = false,
  int others = 0,
  bool birthdays = false,
  DateTime? begin,
}) {
  final b = begin ?? DateTime.utc(2026, 10, 6, 14);
  return CalendarEvent(
    calendarId: 'c1',
    eventId: 'e1',
    title: title,
    begin: b,
    end: b.add(const Duration(hours: 1)),
    allDay: allDay,
    yearly: yearly,
    recurring: yearly,
    otherAttendees: others,
    fromBirthdayCalendar: birthdays,
    timeZone: 'America/New_York',
  );
}

void main() {
  test('CAL-4 auto-tag rules, first match wins', () {
    expect(autoTag(_e(birthdays: true, others: 3)), (Kind.occasion, ReminderContext.personal));
    expect(autoTag(_e(allDay: true, yearly: true)), (Kind.occasion, ReminderContext.personal));
    expect(autoTag(_e(others: 1)), (Kind.meeting, ReminderContext.work));
    expect(autoTag(_e()), (Kind.event, ReminderContext.personal));
  });

  test('CAL-1/CON-7 only selected calendars; birthday calendar skipped while contacts import is on', () {
    expect(shouldImport(_e(), selectedCalendars: {'c1'}, contactsImportOn: false), isTrue);
    expect(shouldImport(_e(), selectedCalendars: {'c2'}, contactsImportOn: false), isFalse);
    expect(shouldImport(_e(birthdays: true), selectedCalendars: {'c1'}, contactsImportOn: true), isFalse);
  });

  test('CAL-3/CAL-6 events are read-only, not completable, no alerts by default', () {
    final r = reminderFromEvent(_e(others: 2), overlays: const [], deviceId: 'd');
    expect(r.isCalendarEvent, isTrue);
    expect(r.completable, isFalse);
    expect(r.alertPlan, isEmpty);
    expect(r.kind, Kind.meeting);
    expect(formatWallDateTime(r.timing.start), '2026-10-06T10:00');
  });

  test('CAL-5/CAL-6 overlays: series type override + instance alerts', () {
    final e = _e();
    final r = reminderFromEvent(
      e,
      overlays: [
        const EventOverlay(id: 's', calendarId: 'c1', eventId: 'e1', alertPlan: [], kindOverride: Kind.meeting),
        EventOverlay(
          id: 'i',
          calendarId: 'c1',
          eventId: 'e1',
          instanceBegin: e.begin,
          alertPlan: const [AlertStage(AlertOffset(-10, OffsetUnit.minutes))],
        ),
      ],
      deviceId: 'd',
    );
    expect(r.kind, Kind.meeting);
    expect(r.alertPlan.single.offset.toString(), '-10m');
  });

  test('CAL-9 duplicate: similar title and within 30 min', () {
    expect(titleSimilarity('Dentist appointment', 'dentist appointment!'), 1);
    expect(titleSimilarity('Dentist', 'Team sync'), lessThan(0.8));
    final manual = Reminder(
      meta: RecordMeta(id: 'm', createdAt: DateTime.utc(2026), updatedAt: DateTime.utc(2026), deviceId: 'd'),
      title: 'Team sync',
      kind: Kind.meeting,
      context: ReminderContext.work,
      timing: Timing(type: TimingType.datetime, start: DateTime.utc(2026, 10, 6, 10), timeZone: 'America/New_York'),
      alertPlan: const [],
    );
    final e = _e();
    expect(findDuplicate(manual, e.begin.add(const Duration(minutes: 20)), [e]), same(e));
    expect(findDuplicate(manual, e.begin.add(const Duration(minutes: 45)), [e]), isNull);
  });
}
