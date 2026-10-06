import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

void main() {
  test('wall times round-trip in both formats', () {
    final dt = DateTime.utc(2026, 10, 11, 18, 5);
    expect(formatWallDateTime(dt), '2026-10-11T18:05');
    expect(parseWall('2026-10-11T18:05'), dt);
    expect(formatWallDate(DateTime.utc(2027, 2, 28)), '2027-02-28');
    expect(parseWall('2027-02-28'), DateTime.utc(2027, 2, 28));
  });

  test('rejects other formats', () {
    expect(() => parseWall('Oct 11'), throwsFormatException);
    expect(() => parseWall('2026-10-11 18:05'), throwsFormatException);
  });
}
