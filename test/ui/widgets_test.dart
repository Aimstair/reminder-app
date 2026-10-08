import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/l10n/gen/app_localizations.dart';
import 'package:reminder_app/ui/icons.dart';
import 'package:reminder_app/ui/theme.dart';
import 'package:reminder_app/ui/widgets.dart';
import 'package:reminder_core/reminder_core.dart';

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

  testWidgets('DS15 segmented control: labels sit in the middle of their segment', (tester) async {
    await tester.pumpWidget(
      _app(
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedPills<int>(
            items: const [(value: 0, label: 'Personal', dot: null), (value: 1, label: 'Work', dot: null)],
            selected: 0,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    final track = tester.getRect(find.byType(SegmentedPills<int>));
    for (final label in ['Personal', 'Work']) {
      final r = tester.getRect(find.text(label));
      expect(r.center.dy, closeTo(track.center.dy, 1), reason: '$label vertically centered');
    }
    final half = track.width / 2;
    expect(tester.getRect(find.text('Personal')).center.dx, closeTo(track.left + half / 2, 1));
    expect(tester.getRect(find.text('Work')).center.dx, closeTo(track.left + half * 1.5, 1));
  });

  testWidgets('DS14 section header: the trailing note sits on the right edge', (tester) async {
    await tester.pumpWidget(_app(const SectionHeader('Overdue', count: 2, trailing: Text('Nagging'))));
    final screen = tester.getSize(find.byType(Scaffold)).width;
    expect(tester.getRect(find.text('Nagging')).right, closeTo(screen - 16, 0.5));
  });

  testWidgets('SUB-1 subtype chips: every option plus Other, full names, picking reports it', (tester) async {
    SubKind? picked = SubKind.birthday;
    await tester.pumpWidget(
      _app(
        Padding(
          padding: const EdgeInsets.all(16),
          child: SubKindChips(kind: Kind.occasion, selected: SubKind.birthday, onChanged: (s) => picked = s),
        ),
      ),
    );
    for (final name in ["Birthday", "Anniversary", "Holiday", "Memorial", "Other"]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(tester.takeException(), isNull, reason: "chips wrap instead of truncating");
    await tester.tap(find.text("Other"));
    expect(picked, isNull);
    await tester.tap(find.text("Holiday"));
    expect(picked, SubKind.holiday);
  });

  testWidgets('SUB-1 no chips for types without subtypes', (tester) async {
    await tester.pumpWidget(_app(SubKindChips(kind: Kind.task, selected: null, onChanged: (_) {})));
    expect(find.text("Other"), findsNothing);
  });
}
