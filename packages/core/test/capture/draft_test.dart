import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

const _ny = 'America/New_York';
const _prefs = UserPrefs(defaultTimeZone: _ny, deviceTimeZone: _ny);
final _meta = RecordMeta(id: 'r', createdAt: DateTime.utc(2026, 10, 5), updatedAt: DateTime.utc(2026, 10, 5), deviceId: 'd');

ParseResult _parse(String s) =>
    ReminderParser(ParseContext(now: DateTime.utc(2026, 10, 5, 14), defaultTimeZone: _ny)).parse(s);

void main() {
  test('timed task gets the default zone and the type default alert (ALR-4)', () {
    final r = reminderFromParse(_parse('call mom tomorrow at 6pm'), meta: _meta, prefs: _prefs, rawInput: 'x');
    expect(r.title, 'Call mom');
    expect(r.kind, Kind.task);
    expect(formatWallDateTime(r.timing.start), '2026-10-06T18:00');
    expect(r.timing.timeZone, _ny);
    expect(r.timing.timeZoneSetManually, isFalse);
    expect(r.alertPlan.map((s) => s.offset.toString()), ['0']);
  });

  test('occasion: date-only, no zone, three-stage default plan', () {
    final r = reminderFromParse(_parse("mom's birthday oct 12"), meta: _meta, prefs: _prefs);
    expect(r.kind, Kind.occasion);
    expect(r.timing.type, TimingType.date);
    expect(r.timing.timeZone, isNull);
    expect(r.alertPlan.map((s) => s.offset.toString()), ['-7d', '-1d', '0']);
  });

  test('stated alerts and nag until done carry over (PRS-24…27)', () {
    final p = _parse('pay rent on the 1st remind me 3 days before nag me');
    final r = reminderFromParse(p, meta: _meta, prefs: _prefs);
    expect(r.alertPlan.first.offset.toString(), '-3d');
    expect(r.nagInterval, const Duration(hours: 2));
  });

  test('canSave needs a title and a date (CAP-7)', () {
    expect(canSave(_parse('call mom tomorrow')), isTrue);
    expect(canSave(_parse('tomorrow at 5pm')), isFalse);
  });
}
