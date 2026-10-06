import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/native/platform_gateway.dart';
import 'package:reminder_core/reminder_core.dart';

DeviceEvent _e({bool allDay = false, String? rrule, int others = 0}) => DeviceEvent(
  calendarId: '7',
  eventId: '42',
  title: 'Team sync',
  beginMs: DateTime.utc(2026, 10, 6, 14).millisecondsSinceEpoch,
  endMs: DateTime.utc(2026, 10, 6, 15).millisecondsSinceEpoch,
  allDay: allDay,
  timeZone: 'America/New_York',
  rrule: rrule,
  otherAttendees: others,
);

void main() {
  test('DeviceEvent → CalendarEvent keeps instants in UTC and the ids', () {
    final c = calendarEventFrom(_e(others: 2), fromBirthdayCalendar: false);
    expect(c.begin, DateTime.utc(2026, 10, 6, 14));
    expect(c.begin.isUtc, isTrue);
    expect(c.end, DateTime.utc(2026, 10, 6, 15));
    expect([c.calendarId, c.eventId, c.otherAttendees, c.recurring, c.yearly], ['7', '42', 2, false, false]);
    expect(autoTag(c), (Kind.meeting, ReminderContext.work)); // CAL-4 rule 3
  });

  test('CAL-4 rule 2: yearly all-day events become occasions', () {
    final c = calendarEventFrom(_e(allDay: true, rrule: 'FREQ=YEARLY;BYMONTHDAY=6'), fromBirthdayCalendar: false);
    expect([c.recurring, c.yearly, c.allDay], [true, true, true]);
    expect(autoTag(c).$1, Kind.occasion);
  });

  test('CAL-4 rule 1: birthday calendar flag carries over', () {
    final c = calendarEventFrom(_e(), fromBirthdayCalendar: true);
    expect(c.fromBirthdayCalendar, isTrue);
    expect(autoTag(c).$1, Kind.occasion);
  });
}
