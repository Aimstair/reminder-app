import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 10, 6);

Reminder _r(String title, Kind kind, {String? template}) => Reminder(
  meta: RecordMeta(id: title, createdAt: _now, updatedAt: _now, deviceId: 'd'),
  title: title,
  kind: kind,
  context: ReminderContext.personal,
  timing: Timing(type: TimingType.date, start: _now),
  alertPlan: const [],
  templateId: template,
);

void main() {
  test('DS11 icon tiles follow the mockup rows', () {
    expect(glyphFor(_r('Pay electricity bill', Kind.task)), ItemGlyph.bill);
    expect(glyphFor(_r('Return shoes', Kind.task)), ItemGlyph.shopping);
    expect(glyphFor(_r('Team standup', Kind.meeting)), ItemGlyph.meeting);
    expect(glyphFor(_r('Client call', Kind.meeting)), ItemGlyph.video);
    expect(glyphFor(_r('Call mom', Kind.task)), ItemGlyph.call);
    expect(glyphFor(_r("Mom's birthday", Kind.occasion)), ItemGlyph.gift);
    expect(glyphFor(_r('Dentist', Kind.event)), ItemGlyph.tooth);
    expect(glyphFor(_r('Lunch with Sam', Kind.event)), ItemGlyph.food);
    expect(glyphFor(_r('Work on report', Kind.task)), ItemGlyph.document);
  });

  test('a template decides before the words do', () {
    expect(glyphFor(_r('Netflix', Kind.task, template: Template.freeTrial.id)), ItemGlyph.trial);
    expect(glyphFor(_r('Call the clinic', Kind.event, template: Template.appointment.id)), ItemGlyph.medical);
  });

  test('falls back to the type; words must be whole', () {
    expect(glyphFor(_r('Water plants', Kind.task)), ItemGlyph.task);
    expect(glyphFor(_r('Concert', Kind.event)), ItemGlyph.event);
    expect(glyphFor(_r('Recall notes', Kind.task)), ItemGlyph.task); // "call" inside "recall" doesn't count
  });
}
