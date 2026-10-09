import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  const subtypes = [
    (value: 'birthday', label: 'Birthday', dot: null),
    (value: 'anniversary', label: 'Anniversary', dot: null),
    (value: 'holiday', label: 'Holiday', dot: null),
    (value: 'memorial', label: 'Memorial', dot: null),
    (value: 'other', label: 'Other', dot: null),
  ];

  testWidgets('SUB-1 subtypes use the segmented control; too many to fit → full names and a sideways scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? picked;
    await tester.pumpWidget(
      _app(
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedPills<String>(
            scrollable: true,
            items: subtypes,
            selected: 'memorial',
            onChanged: (v) => picked = v,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SingleChildScrollView), findsOneWidget, reason: 'five names do not fit in 328dp');
    // Every label is shown whole: its text is narrower than its segment.
    for (final l in subtypes) {
      expect(tester.renderObject<RenderParagraph>(find.text(l.label)).didExceedMaxLines, isFalse, reason: l.label);
    }
    // The selected segment was scrolled into view.
    final memorial = tester.getRect(find.text('Memorial'));
    expect(memorial.left, greaterThanOrEqualTo(16));
    expect(memorial.right, lessThanOrEqualTo(344));
    await tester.tap(find.text('Memorial'));
    expect(picked, 'memorial');
  });

  testWidgets('SUB-1 a scrollable control that fits stays a plain control', (tester) async {
    await tester.pumpWidget(
      _app(
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedPills<String>(
            scrollable: true,
            items: subtypes.sublist(2),
            selected: 'holiday',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(SingleChildScrollView), findsNothing);
  });
}
