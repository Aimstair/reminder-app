import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/data/app_database.dart';
import 'package:reminder_app/data/prefs_repository.dart';
import 'package:reminder_core/reminder_core.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('first run: spec defaults, default zone = device zone (PRF-1)', () async {
    final prefs = PrefsRepository(db);
    await prefs.load(deviceTimeZone: 'Asia/Manila');
    final p = prefs.current;
    expect(p.defaultTimeZone, 'Asia/Manila');
    expect(p.deviceTimeZone, 'Asia/Manila');
    expect(p.dayTime.toString(), '09:00');
    expect([p.nagStart.toString(), p.nagEnd.toString()], ['08:00', '22:00']);
    expect(p.lateAlertCutoff, const Duration(hours: 2));
    expect(p.completionSounds, isTrue);
    expect(prefs.onboarded, isFalse);
  });

  test('saved values survive a reload; travel keeps the default zone (TIM-15)', () async {
    final prefs = PrefsRepository(db);
    await prefs.load(deviceTimeZone: 'America/New_York');
    await prefs.set(PrefKeys.dayTime, PrefsRepository.encodeTime(const TimeOfDay(7, 30)));
    await prefs.set(PrefKeys.tomorrowMode, TomorrowMode.sameTime.name);
    await prefs.set(PrefKeys.lateAlertCutoffMin, null); // "Always"
    await prefs.set(PrefKeys.completionSounds, false);

    final again = PrefsRepository(db);
    await again.load(deviceTimeZone: 'Europe/London');
    final p = again.current;
    expect(p.defaultTimeZone, 'America/New_York');
    expect(p.deviceTimeZone, 'Europe/London');
    expect(p.dayTime.toString(), '07:30');
    expect(p.tomorrowMode, TomorrowMode.sameTime);
    expect(p.lateAlertCutoff, isNull);
    expect(p.completionSounds, isFalse);
  });
}
