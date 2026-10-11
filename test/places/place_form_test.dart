import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/app/app_services.dart';
import 'package:reminder_app/app/providers.dart';
import 'package:reminder_app/data/app_database.dart';
import 'package:reminder_app/features/places/place_form.dart';
import 'package:reminder_app/l10n/gen/app_localizations.dart';
import 'package:reminder_app/ui/theme.dart';
import 'package:reminder_core/reminder_core.dart';

import '../app/home_flow_test.dart' show pumpFor, settleUntil;
import '../services/place_service_test.dart' show FakePlaceGateway;
import '../services/reminder_service_test.dart' show FakeGateway;

void main() {
  testWidgets('LOC-3 S-25: a place reminder saves its place, triggers, active days and remind mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    final geofences = FakePlaceGateway();
    final services = (await tester.runAsync(
      () => AppServices.start(db: db, gateway: FakeGateway(), placeGateway: geofences),
    ))!;
    final home = (await tester.runAsync(
      () => services.places.createPlace(name: 'Home', latitude: 40.7, longitude: -74.0, icon: PlaceIcon.home),
    ))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [servicesProvider.overrideWithValue(services)],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(onPressed: () => showPlaceForm(context, place: home), child: const Text('open')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await pumpFor(tester);
    expect(find.text('New Place Reminder'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Take out the bins');
    await pumpFor(tester);
    await tester.tap(find.text('Leave')); // both on (LOC-3)
    await pumpFor(tester);
    await tester.tap(find.text('Repeats'));
    await pumpFor(tester);
    await tester.tap(find.text('Every time'));
    await pumpFor(tester);
    expect(find.textContaining('Rings when you arrive at or leave Home'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await settleUntil(tester, () => find.text('New Place Reminder').evaluate().isEmpty);

    final saved = (await tester.runAsync(() => services.reminders.watchActive().first))!;
    final r = saved.single;
    expect(r.kind, Kind.place);
    expect(r.place!.placeId, home.id);
    expect(r.place!.onArrive && r.place!.onLeave, isTrue);
    expect(r.place!.active, PlaceActive.repeats);
    expect(r.rrule, startsWith('FREQ=WEEKLY'));
    expect(r.place!.remind, PlaceRemind.everyTime);

    await tester.pumpWidget(const SizedBox());
    final closed = db.close();
    await tester.pump(const Duration(seconds: 1));
    await closed;
  });
}
