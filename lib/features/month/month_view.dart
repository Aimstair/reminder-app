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
import '../actions/occurrence_actions.dart';
import '../../ui/widgets.dart';
import '../capture/capture_sheet.dart';
import '../../ui/icons.dart';
import '../../ui/motion.dart';

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
    final home = ref.watch(homeProvider);
    final selected = home.date.month == month.month && home.date.year == month.year ? home.date : null;
    final showCompleted = ref.watch(prefsRepoProvider).flag(PrefKeys.showCompleted, fallback: true);
    final items = (ref.watch(rangeProvider((from: days.first, to: days.last))) ?? const <DayItem>[])
        .where((i) => showCompleted || !i.resolved)
        .toList();
    final byDay = <DateTime, List<DayItem>>{};
    for (final i in items) {
      (byDay[i.day] ??= []).add(i);
    }
    // Month summary chips (mockup 08): occasions · bills due · meetings in this month.
    final inMonth = items.where((i) => i.day.month == month.month && i.day.year == month.year).toList();
    final occasions = inMonth.where((i) => i.reminder.kind == Kind.occasion).length;
    final bills = inMonth.where((i) => i.reminder.kind == Kind.bill || glyphFor(i.reminder) == ItemGlyph.bill).length;
    final meetings = inMonth.where((i) => i.reminder.kind == Kind.meeting).length;
    final dayItems = selected == null ? const <DayItem>[] : (byDay[selected] ?? const <DayItem>[]);
    final notifier = ref.read(homeProvider.notifier);

    return ColoredBox(
      color: c.surface,
      child: CustomScrollView(
        slivers: [
          // October 2026  ‹ ›
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.m),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Radii.row),
                      onTap: () async {
                        final d = await showMiniMonth(context, selected ?? month); // S-18
                        if (d != null) notifier.setDate(d);
                      },
                      child: Text.rich(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        TextSpan(
                          text: f.month(month),
                          style: text.displaySmall,
                          children: [
                            TextSpan(
                              text: ' ${month.year}',
                              style: text.titleLarge?.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _RoundButton(
                    icon: AppIcons.previous,
                    tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
                    onTap: () => notifier.setDate(DateTime.utc(month.year, month.month - 1)),
                  ),
                  const SizedBox(width: Space.s),
                  _RoundButton(
                    icon: AppIcons.next,
                    tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                    onTap: () => notifier.setDate(DateTime.utc(month.year, month.month + 1)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
              child: Row(
                children: [
                  Expanded(
                    child: _Summary(
                      count: occasions,
                      icon: AppIcons.birthday,
                      label: l10n.summaryOccasions(occasions),
                      color: c.occasion,
                    ),
                  ),
                  const SizedBox(width: Space.s),
                  Expanded(
                    child: _Summary(count: bills, icon: AppIcons.bill, label: l10n.summaryBills(bills), color: c.bill),
                  ),
                  const SizedBox(width: Space.s),
                  Expanded(
                    child: _Summary(
                      count: meetings,
                      icon: AppIcons.meeting,
                      label: l10n.summaryMeetings(meetings),
                      color: c.meeting,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s),
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Text(
                        f.weekdayShort(days[i]).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: text.labelMedium?.copyWith(color: c.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.s, Space.xs, Space.s, Space.m),
              child: Column(
                children: [
                  for (var w = 0; w < 6; w++)
                    Container(
                      height: 62,
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: c.separator.withValues(alpha: 0.4), width: 0.5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var d = 0; d < 7; d++)
                            Expanded(
                              child: _Cell(
                                day: days[w * 7 + d],
                                inMonth: days[w * 7 + d].month == month.month,
                                today: days[w * 7 + d] == today,
                                selected: days[w * 7 + d] == selected,
                                items: byDay[days[w * 7 + d]] ?? const [],
                                onTap: () => notifier.setDate(days[w * 7 + d]), // VW-8: select, list below
                                onLongPress: () => showCaptureSheet(context, day: days[w * 7 + d]),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Selected day's items (mockup 08): rounded panel on the grouped background.
          if (selected != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                decoration: BoxDecoration(
                  color: c.bgGrouped,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
                ),
                padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(Radii.row),
                            onTap: () => notifier.openDay(selected), // heading → Day view (VW-8)
                            child: Text(
                              f.date(selected, today: today),
                              style: text.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.s),
                        Text(
                          '${dayItems.length} ${l10n.statItems(dayItems.length)}',
                          style: text.bodyMedium,
                          maxLines: 1,
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.m),
                    if (dayItems.isEmpty)
                      Text(l10n.monthDayEmpty, style: text.bodyMedium)
                    else
                      for (final (n, i) in dayItems.indexed) ...[
                        FadeSlideIn(
                          key: ValueKey('${selected.day}-${i.occurrenceKey}'),
                          index: n,
                          child: _DayItemCard(item: i, today: today),
                        ),
                        const SizedBox(height: Space.m),
                      ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      child: Pressable(
        scale: 0.88,
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.of(context).bgGrouped, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: AppColors.of(context).accent),
        ),
      ),
    ),
  );
}

/// "2 occasions" chip (mockup 08): tinted, the type's icon + a big colored count. The name ("occasions")
/// was cut off at a third of the width, so it is only read out (TalkBack) and shown on long-press.
class _Summary extends StatelessWidget {
  const _Summary({required this.count, required this.icon, required this.label, required this.color});
  final int count;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final deep = Color.lerp(color, Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, 0.3)!;
    return Tooltip(
      message: '$count $label',
      excludeFromSemantics: true,
      child: Semantics(
        label: '$count $label',
        excludeSemantics: true,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: Space.m),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: deep),
              const SizedBox(width: Space.s),
              Flexible(
                child: Text(
                  '$count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(color: deep, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Month cell (VW-10, mockup 08): day number (today filled, selected ringed), up to 3 type dots,
/// one short label for the first all-day item.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.day,
    required this.inMonth,
    required this.today,
    required this.selected,
    required this.items,
    required this.onTap,
    required this.onLongPress,
  });
  final DateTime day;
  final bool inMonth;
  final bool today;
  final bool selected;
  final List<DayItem> items;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final open = items.where((i) => !i.resolved).toList();
    final kinds = Kind.values.where((k) => open.any((i) => i.reminder.kind == k)).take(3).toList();
    final labelItem = items.where((i) => i.allDay).firstOrNull;
    final ring = selected && !today ? (open.isEmpty ? c.accent : c.kind(open.first.reminder.kind)) : null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          const SizedBox(height: Space.xs),
          // The selection ring fades and pops in on the chosen day.
          AnimatedScale(
            scale: selected && !today ? 1.08 : 1,
            duration: Motion.standard,
            curve: Motion.spring,
            child: AnimatedContainer(
              duration: Motion.standard,
              curve: Curves.easeOutCubic,
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: today ? c.accent : (ring?.withValues(alpha: 0.12)),
                shape: BoxShape.circle,
                border: Border.all(color: ring ?? Colors.transparent, width: 2),
              ),
              child: Text(
                '${day.day}',
                style: text.titleSmall?.copyWith(
                  color: today
                      ? Colors.white
                      : (ring ?? (inMonth ? c.textPrimary : c.textSecondary.withValues(alpha: 0.4))),
                  fontWeight: today || selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final k in kinds)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: c.kind(k), shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
          if (labelItem != null) ...[const SizedBox(height: 2), _Label(item: labelItem)],
        ],
      ),
    );
  }
}

/// One short label in a cell (VW-10): "Mom", "Rent", "Party" — tinted in the type color.
class _Label extends StatelessWidget {
  static const _verbs = {
    'pay',
    'buy',
    'call',
    'pick',
    'get',
    'book',
    'return',
    'renew',
    'cancel',
    'order',
    'send',
    'take',
    'fix',
    'clean',
    'water',
    'submit',
    'file',
    'email',
    'text',
    'visit',
  };

  const _Label({required this.item});
  final DayItem item;

  /// A noun for the cell: first word with the possessive dropped ("Mom's birthday" → "Mom"), or the
  /// last word when the title starts with an action ("Pay rent" → "Rent", "Pick up dry cleaning" → "Cleaning").
  static String short(Reminder r) {
    final words = r.title.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    final action = _verbs.contains(words.first.toLowerCase());
    var w = action && words.length > 1 ? words.last : words.first;
    w = w.replaceAll(RegExp(r"['’]s$"), '');
    return w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = item.overdue ? c.danger : c.kind(item.reminder.kind);
    final deep = Color.lerp(
      color,
      Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
      0.25,
    )!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: item.resolved ? 0.06 : 0.16),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        short(item.reminder),
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: TextStyle(
          fontSize: 11,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: item.resolved ? c.textSecondary : deep,
          decoration: item.resolved ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}

/// Row card in the selected-day panel (mockup 08): icon tile, title, when, type chip.
class _DayItemCard extends StatelessWidget {
  const _DayItemCard({required this.item, required this.today});
  final DayItem item;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final r = item.reminder;
    final color = c.kind(r.kind);
    final bill = glyphFor(r) == ItemGlyph.bill;
    return Pressable(
      onTap: () => openDetail(context, r, item.occurrenceKey),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: Space.m),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card + 4)),
        child: Row(
          children: [
            IconTile.item(context, r),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    r.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(decoration: item.resolved ? TextDecoration.lineThrough : null),
                  ),
                  Text(
                    f.when(item.start, allDay: item.allDay, today: today),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: item.overdue ? c.danger : null),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.s),
            MiniChip(bill ? l10n.chipBill : f.kind(r.kind), color: bill ? c.event : color),
          ],
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
                icon: const Icon(AppIcons.previous),
              ),
              Expanded(
                child: Text(f.monthYear(_month), textAlign: TextAlign.center, style: text.titleMedium),
              ),
              IconButton(
                onPressed: () => setState(() => _month = DateTime.utc(_month.year, _month.month + 1)),
                icon: const Icon(AppIcons.next),
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
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(color: c.textSecondary, shape: BoxShape.circle),
                          ),
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
