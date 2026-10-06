import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

const _ny = 'America/New_York';

void main() {
  test('normal times convert both ways', () {
    final i = wallToInstant(DateTime.utc(2026, 11, 2, 9), _ny);
    expect(i, DateTime.utc(2026, 11, 2, 14)); // EST, UTC−5
    expect(instantToWall(i, _ny), DateTime.utc(2026, 11, 2, 9));
  });

  test('the day after fall-back keeps the wall time (regression)', () {
    expect(instantToWall(wallToInstant(DateTime.utc(2026, 11, 1, 9), _ny), _ny), DateTime.utc(2026, 11, 1, 9));
    expect(instantToWall(wallToInstant(DateTime.utc(2026, 11, 1, 3), _ny), _ny), DateTime.utc(2026, 11, 1, 3));
  });

  test('TIM-14 overlap → first occurrence (EDT)', () {
    expect(wallToInstant(DateTime.utc(2026, 11, 1, 1, 30), _ny), DateTime.utc(2026, 11, 1, 5, 30));
  });

  test('TIM-13 gap → shifted forward by the gap', () {
    expect(normalizeWall(DateTime.utc(2027, 3, 14, 2, 30), _ny), DateTime.utc(2027, 3, 14, 3, 30));
  });

  test('zones east of UTC and without DST', () {
    expect(wallToInstant(DateTime.utc(2026, 10, 6, 9), 'Asia/Tokyo'), DateTime.utc(2026, 10, 6, 0));
    expect(wallToInstant(DateTime.utc(2026, 10, 6, 9), 'Asia/Kolkata'), DateTime.utc(2026, 10, 6, 3, 30));
  });

  test('every hour of a DST year round-trips (except the gap)', () {
    var wall = DateTime.utc(2026, 1, 1);
    while (wall.year == 2026) {
      final back = instantToWall(wallToInstant(wall, _ny), _ny);
      final inGap = wall.month == 3 && wall.day == 8 && wall.hour == 2;
      if (!inGap) expect(back, wall, reason: '$wall');
      wall = wall.add(const Duration(hours: 1));
    }
  });

  test('"UTC" works as a zone (device fallback)', () {
    final i = DateTime.utc(2026, 10, 5, 14);
    expect(instantToWall(i, 'UTC'), i);
    expect(wallToInstant(i, 'UTC'), i);
  });
}
