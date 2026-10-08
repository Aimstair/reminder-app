import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/l10n/gen/app_localizations.dart';
import 'package:reminder_app/ui/icons.dart';
import 'package:reminder_app/ui/theme.dart';
import 'package:reminder_app/ui/widgets.dart';

Widget _app(Widget child) => MaterialApp(
  theme: buildTheme(Brightness.light),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('DS14 form rows: chevrons line up on the right edge whatever the value length', (tester) async {
    await tester.pumpWidget(
      _app(
        InsetGroup(
          children: [
            FormRow(label: 'Date', value: 'Fri, Oct 9', onTap: () {}),
            FormRow(label: 'Time', value: '3:00 PM – 4:00 PM', onTap: () {}),
            FormRow(label: 'Repeat', value: 'Never', onTap: () {}),
            FormRow(label: 'Notes', value: 'A very long value that cannot possibly fit on one line here', onTap: () {}),
          ],
        ),
      ),
    );
    final rights = find.byIcon(AppIcons.next).evaluate().map((e) => tester.getRect(find.byWidget(e.widget)).right);
    expect(rights.toSet(), hasLength(1), reason: 'every chevron at the same x');
    expect(tester.takeException(), isNull, reason: 'long values truncate instead of overflowing');
  });

  testWidgets('DS14 section header: the trailing note sits on the right edge', (tester) async {
    await tester.pumpWidget(_app(const SectionHeader('Overdue', count: 2, trailing: Text('Nagging'))));
    final screen = tester.getSize(find.byType(Scaffold)).width;
    expect(tester.getRect(find.text('Nagging')).right, closeTo(screen - 16, 0.5));
  });
}
