/// S-14 Month view: month grid with colored labels (max 3, then "+N", VW-10), occasion icons,
/// overdue style on the original date (VW-5), tap a day → Day view, long-press → capture on that
/// date (VW-8), swipe between months (VW-9). Also the S-18 mini month picker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../data/prefs_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../capture/capture_sheet.dart';

const _origin = 10000;

/// First day of the week for the locale (Sunday in en-US, Monday in most others).
int firstWeekday(BuildContext context) {
  final loc = MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = Sunday
  return loc == 0 ? DateTime.sunday : loc;
}

/// The 6×7 grid of days for the month of [month], starting on [weekStart].
List<DateTime> monthGrid(DateTime month, int weekStart) {
  final first = DateTime.utc(month.year, month.month, 1);
  final lead = (first.weekday - weekStart + 7) % 7;
  final start = addDays(first, -lead);
  return [for (var i = 0; i < 42; i++) addDays(start, i)];
}

class MonthView extends ConsumerStatefulWidget {
  const MonthView({super.key});

  @override
  ConsumerState<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<MonthView> {
  late final DateTime _base = DateTime.utc(ref.read(homeProvider).date.year, ref.read(homeProvider).date.month);
  late final _pages = PageController(initialPage: _origin);

  DateTime _monthAt(int i) => DateTime.utc(_base.year, _base.month + (i - _origin));

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(homeProvider.select((s) => s.date), (_, date) {
      final index = _origin + (date.year - _base.year) * 12 + date.month - _base.month;
      if (_pages.hasClients && _pages.page?.round() != index) _pages.jumpToPage(index);
    });
    return PageView.builder(
      controller: _pages,
      onPageChanged: (i) {
        final m = _monthAt(i);
        final current = ref.read(homeProvider).date;
        if (current.year != m.year || current.month != m.month) ref.read(homeProvider.notifier).setDate(m);
      },
      itemBuilder: (_, i) => _MonthPage(month: _monthAt(i)),
    );
  }
}

class _MonthPage extends ConsumerWidget {
  const _MonthPage({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final days = monthGrid(month, firstWeekday(context));
    final today = ref.watch(todayProvider);
    final showCompleted = ref.watch(prefsRepoProvider).flag(PrefKeys.showCompleted, fallback: true);
    final items = (ref.watch(rangeProvider((from: days.first, to: days.last))) ?? const <DayItem>[])
        .where((i) => showCompleted || !i.resolved)
        .toList();
    final byDay = <DateTime, List<DayItem>>{};
    for (final i in items) {
      (byDay[i.day] ??= []).add(i);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
          child: Align(alignment: Alignment.centerLeft, child: Text(f.monthYear(month), style: text.titleLarge)),
        ),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  f.weekdayShort(days[i]).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: text.labelSmall,
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.xs),
        Expanded(
          child: Column(
            children: [
              for (var w = 0; w < 6; w++)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var d = 0; d < 7; d++)
                        Expanded(
                          child: Builder(builder: (context) {
                            final day = days[w * 7 + d];
                            final inMonth = day.month == month.month;
                            final isToday = day == today;
                            final list = byDay[day] ?? const <DayItem>[];
                            return InkWell(
                              onTap: () => ref.read(homeProvider.notifier).openDay(day), // VW-8
                              onLongPress: () => showCaptureSheet(context, day: day),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: c.separator.withValues(alpha: 0.5), width: 0.5)),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: isToday ? c.accent : null, shape: BoxShape.circle),
                                      child: Text(
                                        '${day.day}',
                                        style: text.labelSmall?.copyWith(
                                          color: isToday
                                              ? Colors.white
                                              : (inMonth ? c.textPrimary : c.textSecondary.withValues(alpha: 0.4)),
                                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    for (final i in list.take(list.length > 3 ? 2 : 3)) _Label(item: i),
                                    if (list.length > 3)
                                      Text(l10n.moreCount(list.length - 2), style: text.labelSmall?.copyWith(fontSize: 10)),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Month cell label (screens.md §4): type color, occasion icon, done faded, overdue red.
class _Label extends StatelessWidget {
  const _Label({required this.item});
  final DayItem item;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = item.overdue ? c.danger : c.kind(item.reminder.kind);
    final done = item.resolved;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: done ? 0.06 : 0.16),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '${item.reminder.kind == Kind.occasion ? '🎂 ' : ''}${item.reminder.title}',
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: TextStyle(
          fontSize: 10,
          height: 1.25,
          color: done ? c.textSecondary : c.textPrimary,
          decoration: done ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}

/// S-18 Mini month picker dropping down from the title: tap a date → jump the current view there.
Future<DateTime?> showMiniMonth(BuildContext context, DateTime selected) {
  return showDialog<DateTime>(
    context: context,
    barrierColor: Colors.black12,
    builder: (ctx) => Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(ctx).top + kToolbarHeight),
        child: Material(
          color: AppColors.of(ctx).surfaceElevated,
          borderRadius: BorderRadius.circular(Radii.card),
          elevation: 6,
          child: SizedBox(width: 340, child: _MiniMonth(selected: selected)),
        ),
      ),
    ),
  );
}

class _MiniMonth extends ConsumerStatefulWidget {
  const _MiniMonth({required this.selected});
  final DateTime selected;

  @override
  ConsumerState<_MiniMonth> createState() => _MiniMonthState();
}

class _MiniMonthState extends ConsumerState<_MiniMonth> {
  late DateTime _month = DateTime.utc(widget.selected.year, widget.selected.month);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final days = monthGrid(_month, firstWeekday(context));
    final today = ref.watch(todayProvider);
    final marked = {
      for (final i in ref.watch(rangeProvider((from: days.first, to: days.last))) ?? const <DayItem>[])
        if (!i.resolved) i.day,
    };
    return Padding(
      padding: const EdgeInsets.all(Space.m),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _month = DateTime.utc(_month.year, _month.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(child: Text(f.monthYear(_month), textAlign: TextAlign.center, style: text.titleMedium)),
              IconButton(
                onPressed: () => setState(() => _month = DateTime.utc(_month.year, _month.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < 7; i++)
                Center(child: Text(DateFormat.E(f.locale).format(days[i]).substring(0, 1), style: text.labelSmall)),
              for (final d in days)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context, d),
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: d == dateOnly(widget.selected)
                          ? c.accent
                          : d == today
                              ? c.accent.withValues(alpha: 0.15)
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${d.day}',
                          style: text.bodyMedium?.copyWith(
                            color: d == dateOnly(widget.selected)
                                ? Colors.white
                                : (d.month == _month.month ? c.textPrimary : c.textSecondary.withValues(alpha: 0.4)),
                          ),
                        ),
                        if (marked.contains(d))
                          Container(width: 4, height: 4, decoration: BoxDecoration(color: c.textSecondary, shape: BoxShape.circle)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
