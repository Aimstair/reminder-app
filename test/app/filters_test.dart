import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/app/app_services.dart';
import 'package:reminder_app/app/providers.dart';
import 'package:reminder_app/data/app_database.dart';
import 'package:reminder_app/data/prefs_repository.dart';

import '../services/reminder_service_test.dart' show FakeGateway;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('VW-2 drawer filters update when a calendar is unchecked and checked again', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final services = await AppServices.start(db: db, gateway: FakeGateway());
    final container = ProviderContainer(overrides: [servicesProvider.overrideWithValue(services)]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final seen = <Set<String>>[];
    container.listen(filtersProvider, (_, f) => seen.add(f.hiddenCalendars), fireImmediately: true);
    await Future<void>.delayed(Duration.zero);

    await services.prefs.set(PrefKeys.hiddenCalendars, ['work-cal']);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(filtersProvider).hiddenCalendars, {'work-cal'});

    await services.prefs.set(PrefKeys.hiddenCalendars, <String>[]);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(filtersProvider).hiddenCalendars, isEmpty);
    expect(seen.last, isEmpty);
  });
}
