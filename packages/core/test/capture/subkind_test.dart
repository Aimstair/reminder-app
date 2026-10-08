import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 10, 5, 18);

Reminder _r(String title, Kind kind, {SubKind? sub}) => Reminder(
  meta: RecordMeta(id: title, createdAt: _now, updatedAt: _now, deviceId: 'd'),
  title: title,
  kind: kind,
  subKind: sub,
  context: ReminderContext.personal,
  timing: Timing(type: TimingType.date, start: DateTime.utc(2026, 10, 12)),
  alertPlan: const [],
);

void main() {
  test('SUB-1 each subtype belongs to one type; Task and Bill have none', () {
    expect(SubKind.of(Kind.occasion), [SubKind.birthday, SubKind.anniversary, SubKind.holiday, SubKind.memorial]);
    expect(SubKind.of(Kind.meeting), [SubKind.video, SubKind.inPerson, SubKind.phone]);
    expect(SubKind.of(Kind.event), [SubKind.appointment, SubKind.travel, SubKind.social]);
    expect([SubKind.of(Kind.task), SubKind.of(Kind.bill)], [isEmpty, isEmpty]);
  });

  test('SUB-2 guesses from words within the type', () {
    expect(guessSubKind(Kind.occasion, "Mom's birthday"), SubKind.birthday);
    expect(guessSubKind(Kind.occasion, 'Our anniversary'), SubKind.anniversary);
    expect(guessSubKind(Kind.occasion, "Grandpa's death anniversary"), SubKind.memorial);
    expect(guessSubKind(Kind.occasion, 'Memorial Day'), SubKind.holiday);
    expect(guessSubKind(Kind.occasion, 'Diwali'), SubKind.holiday);
    expect(guessSubKind(Kind.occasion, 'Graduation'), isNull);
    expect(guessSubKind(Kind.meeting, 'Sync on Zoom'), SubKind.video);
    expect(guessSubKind(Kind.meeting, 'Conference call with ACME'), SubKind.phone);
    expect(guessSubKind(Kind.meeting, 'Coffee with Anna'), SubKind.inPerson);
    expect(guessSubKind(Kind.event, 'Dentist'), SubKind.appointment);
    expect(guessSubKind(Kind.event, 'Train to Boston'), SubKind.travel);
    expect(guessSubKind(Kind.event, 'Concert'), SubKind.social);
    expect(guessSubKind(Kind.task, 'Buy birthday gift'), isNull, reason: 'tasks have no subtypes');
  });

  test('SUB-1 changing the type drops a subtype that does not fit', () {
    final r = _r('Diwali', Kind.occasion, sub: SubKind.holiday);
    expect(r.copyWith(title: 'Diwali!').subKind, SubKind.holiday);
    expect(r.copyWith(kind: Kind.event).subKind, isNull);
    expect(r.copyWith(kind: Kind.event, subKind: () => SubKind.social).subKind, SubKind.social);
    expect(r.copyWith(subKind: () => null).subKind, isNull, reason: '"Other"');
  });

  test('SUB-1 templates and contacts set their subtype', () {
    expect(Template.birthday.subKind, SubKind.birthday);
    expect(Template.appointment.subKind, SubKind.appointment);
    expect(Template.nightOut.subKind, SubKind.social);
    final c = ContactDate(contactId: 'c', name: 'Ana', field: ContactDateField.anniversary, month: 6, day: 18);
    final r = reminderFromContact(
      c,
      meta: RecordMeta(id: 'x', createdAt: _now, updatedAt: _now, deviceId: 'd'),
      today: DateTime.utc(2026, 10, 5),
    );
    expect(r.subKind, SubKind.anniversary);
  });

  test('SUB-1 the subtype picks the tile icon', () {
    expect(glyphFor(_r('Ana and Ben', Kind.occasion, sub: SubKind.anniversary)), ItemGlyph.anniversary);
    expect(glyphFor(_r('Christmas', Kind.occasion, sub: SubKind.holiday)), ItemGlyph.holiday);
    expect(glyphFor(_r('Dad', Kind.occasion, sub: SubKind.memorial)), ItemGlyph.memorial);
    expect(glyphFor(_r('Graduation', Kind.occasion)), ItemGlyph.celebration);
    expect(glyphFor(_r('Weekly sync', Kind.meeting, sub: SubKind.phone)), ItemGlyph.call);
    expect(glyphFor(_r('Weekly sync', Kind.meeting, sub: SubKind.video)), ItemGlyph.video);
    expect(
      glyphFor(_r('Dentist', Kind.event, sub: SubKind.appointment)),
      ItemGlyph.tooth,
      reason: 'words still refine',
    );
    expect(glyphFor(_r('Check-up', Kind.event, sub: SubKind.appointment)), ItemGlyph.medical);
    expect(glyphFor(_r('To Lisbon', Kind.event, sub: SubKind.travel)), ItemGlyph.travel);
  });
}
