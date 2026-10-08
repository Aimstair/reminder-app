import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/app/app_services.dart';
import 'package:reminder_app/app/providers.dart';
import 'package:reminder_app/data/app_database.dart';
import 'package:reminder_app/data/prefs_repository.dart';
import 'package:reminder_app/main.dart';

import '../services/reminder_service_test.dart' show FakeGateway;

/// Lets real async work (SQLite, streams) run until [done] holds, then pumps until animations end.
/// (pumpAndSettle can't be used: it never lets the database's real async work run.)
Future<void> settleUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 50 && !done(); i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await pumpFor(tester);
}

/// The bell mascot animates forever, so pumpAndSettle never settles; pump a bounded time instead.
Future<void> pumpFor(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('FL-2: type a reminder, save, see it on Schedule; swipe right = Done', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final gateway = FakeGateway();
    final services = (await tester.runAsync(() async {
      final s = await AppServices.start(db: db, gateway: gateway);
      await s.prefs.set(PrefKeys.onboarded, true);
      await s.prefs.set('first_done_shown', true);
      await s.prefs.set('notif_asked', true); // skip the PRM-6 flow here
      return s;
    }))!;

    await tester.pumpWidget(
      ProviderScope(overrides: [servicesProvider.overrideWithValue(services)], child: const ReminderApp()),
    );
    await settleUntil(tester, () => find.text('Nothing to remember… yet').evaluate().isNotEmpty);
    expect(find.text('Nothing to remember… yet'), findsOneWidget);

    await tester.tap(find.byTooltip('New reminder'));
    await pumpFor(tester);
    await tester.enterText(find.byType(TextField), 'Call mom tomorrow at 6pm');
    await pumpFor(tester);
    expect(find.text('Date'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await settleUntil(tester, () => gateway.synced.isNotEmpty && find.text('Call mom').evaluate().isNotEmpty);
    expect(find.text('Call mom'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(gateway.synced, isNotEmpty, reason: 'alarms scheduled on save');

    await tester.drag(find.text('Call mom'), const Offset(500, 0));
    await settleUntil(tester, () => gateway.synced.isEmpty && find.text('Call mom').evaluate().isEmpty);
    expect(find.text('Call mom'), findsNothing);
    expect(gateway.synced, isEmpty, reason: 'alarms cancelled when done');
    expect(find.text('Done'), findsOneWidget); // Undo snackbar

    // OCC-5: Undo still works although the swiped row is gone (it once read a disposed ref).
    await tester.tap(find.text('Undo'));
    await settleUntil(tester, () => gateway.synced.isNotEmpty && find.text('Call mom').evaluate().isNotEmpty);
    expect(find.text('Call mom'), findsOneWidget);
    expect(gateway.synced, isNotEmpty, reason: 'alarms restored by Undo');

    await tester.pumpWidget(const SizedBox());
    final closed = db.close();
    await tester.pump(const Duration(seconds: 1));
    await closed;
  });
}
