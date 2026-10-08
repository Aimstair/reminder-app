/// S-13 Day view — built to mockup `docs/design/mockups/06-day-view.png` (DS11): big date header
/// with "items" / "busy" pills (tap → mini month, S-18), week strip with the selected day circled,
/// all-day chips (with "Overdue (n)" on today, VW-5), hourly grid with tinted blocks and a now line
/// with its time (VW-11), overlapping items side by side (max 3, then "+N"), swipe between days
/// (VW-9), tap an empty slot to capture there (VW-8). The grid is reused by 3 Day / Week in v1.2.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../data/prefs_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/icons.dart';
import '../../ui/motion.dart';
import '../../ui/tokens.dart';
import '../actions/occurrence_actions.dart';
import '../capture/capture_sheet.dart';
import '../digest/digest_card.dart';
import '../month/month_view.dart' show firstWeekday, showMiniMonth;

const _hourHeight = 60.0;
const _gutter = 52.0;
const _origin = 100000; // PageView index of the base day

class DayView extends ConsumerStatefulWidget {
  const DayView({super.key});

  @override
  ConsumerState<DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
  late final DateTime _base = ref.read(homeProvider).date;
  late final _pages = PageController(initialPage: _origin);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Jump when the date is changed elsewhere ([Today], mini month, week strip).
    ref.listen(homeProvider.select((s) => s.date), (_, date) {
      final index = _origin + date.difference(_base).inDays;
      if (_pages.hasClients && _pages.page?.round() != index) _pages.jumpToPage(index);
    });
    // White page like the mockup (Notion-style grid), not the grouped gray.
    return ColoredBox(
      color: AppColors.of(context).surface,
      child: PageView.builder(
        controller: _pages,
        onPageChanged: (i) => ref.read(homeProvider.notifier).setDate(addDays(_base, i - _origin)),
        itemBuilder: (_, i) => _DayPage(day: addDays(_base, i - _origin)),
      ),
    );
  }
}

class _DayPage extends ConsumerStatefulWidget {
  const _DayPage({required this.day});
  final DateTime day;

  @override
  ConsumerState<_DayPage> createState() => _DayPageState();
}

class _DayPageState extends ConsumerState<_DayPage> {
  late final ScrollController _scroll;
  bool _overdueOpen = false;

  @override
  void initState() {
    super.initState();
    // VW-11: today → one hour before now; other days → day time.
    final today = ref.read(todayProvider);
    final prefs = ref.read(prefsProvider);
    final hour = widget.day == today
        ? math.max(0, instantToWall(DateTime.now().toUtc(), prefs.deviceTimeZone).hour - 1)
        : prefs.dayTime.hour;
    _scroll = ScrollController(initialScrollOffset: math.max(0, hour * _hourHeight - 14)); // label not clipped
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final today = ref.watch(todayProvider);
    final isToday = day == today;
    final showCompleted = ref.watch(prefsRepoProvider).flag(PrefKeys.showCompleted, fallback: true);
    final all = (ref.watch(rangeProvider((from: day, to: day))) ?? const <DayItem>[])
        .where((i) => showCompleted || !i.resolved)
        .toList();
    final allDay = all.where((i) => i.allDay).toList();
    final timed = all.where((i) => !i.allDay).toList();
    final overdue = isToday
        ? (ref.watch(scheduleProvider) ?? const <ScheduleItem>[])
              .where((i) => i.overdue && i.start.isBefore(day))
              .toList()
        : const <ScheduleItem>[];

    final nowWall = instantToWall(DateTime.now().toUtc(), ref.watch(prefsProvider).deviceTimeZone);
    final nowMinutes = nowWall.hour * 60 + nowWall.minute;

    return Column(
      children: [
        _Header(day: day, items: all.length, busyMinutes: _busyMinutes(timed, day)),
        _DayStrip(selected: day),
        if (isToday) const DigestBar(),
        if (allDay.isNotEmpty || overdue.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.separator.withValues(alpha: 0.5), width: 0.5),
                bottom: BorderSide(color: c.separator.withValues(alpha: 0.5), width: 0.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(Space.s, Space.s, Space.l, Space.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _gutter - Space.s,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n.allDay.toUpperCase().replaceFirst(' ', '\n'),
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.1),
                    ),
                  ),
                ),
                const SizedBox(width: Space.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: Space.s,
                        runSpacing: Space.s,
                        children: [
                          if (overdue.isNotEmpty)
                            _AllDayChip(
                              label: l10n.overdueCount(overdue.length),
                              icon: AppIcons.error,
                              color: c.danger,
                              onTap: () => setState(() => _overdueOpen = !_overdueOpen),
                            ),
                          for (final i in allDay)
                            _AllDayChip(
                              label: i.reminder.title,
                              icon: glyphIcon(glyphFor(i.reminder)),
                              color: i.overdue ? c.danger : c.kind(i.reminder.kind),
                              done: i.resolved,
                              onTap: () => openDetail(context, i.reminder, i.occurrenceKey),
                            ),
                        ],
                      ),
                      if (_overdueOpen)
                        Padding(
                          padding: const EdgeInsets.only(top: Space.s),
                          child: Wrap(
                            spacing: Space.s,
                            runSpacing: Space.s,
                            children: [
                              for (final o in overdue)
                                _AllDayChip(
                                  label: o.reminder.title,
                                  icon: glyphIcon(glyphFor(o.reminder)),
                                  color: c.danger,
                                  onTap: () => openDetail(context, o.reminder, o.occurrenceKey),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Hourly grid
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            child: SizedBox(
              height: 24 * _hourHeight + Space.l,
              child: LayoutBuilder(
                builder: (context, box) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Like iOS Calendar: the hour label next to the now pill is hidden.
                    for (var h = 0; h < 24; h++)
                      _HourLine(hour: h, hideLabel: isToday && (nowMinutes - h * 60).abs() < 16),
                    // Empty-slot taps → capture at that time (VW-8, CAP-11 locked).
                    Positioned.fill(
                      left: _gutter,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapUp: (d) {
                          final mins = ((d.localPosition.dy / _hourHeight) * 60 ~/ 30) * 30;
                          showCaptureSheet(
                            context,
                            at: DateTime.utc(day.year, day.month, day.day, mins ~/ 60, mins % 60),
                          );
                        },
                      ),
                    ),
                    ..._blocks(context, timed, box.maxWidth - _gutter - Space.l),
                    if (isToday) _NowLine(zone: ref.watch(prefsProvider).deviceTimeZone),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Minutes covered by timed items on this day (overlaps counted once) — the "busy" pill.
  int _busyMinutes(List<DayItem> timed, DateTime day) {
    final spans = [
      for (final i in timed)
        (
          i.start,
          (i.end ?? i.start.add(const Duration(minutes: 30))).isAfter(i.start)
              ? (i.end ?? i.start.add(const Duration(minutes: 30)))
              : i.start,
        ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    var total = 0;
    DateTime? curStart, curEnd;
    for (final (s, e) in spans) {
      if (curEnd == null || s.isAfter(curEnd)) {
        if (curStart != null) total += curEnd!.difference(curStart).inMinutes;
        curStart = s;
        curEnd = e;
      } else if (e.isAfter(curEnd)) {
        curEnd = e;
      }
    }
    if (curStart != null) total += curEnd!.difference(curStart).inMinutes;
    return total;
  }

  /// Lays out overlapping items side by side (max 3 columns, then "+N", VW-11).
  List<Widget> _blocks(BuildContext context, List<DayItem> items, double width) {
    final out = <Widget>[];
    DateTime endOf(DayItem i) {
      final e = i.end ?? i.start.add(const Duration(minutes: 30)); // VW-3: tasks without an end
      final dayEnd = DateTime.utc(widget.day.year, widget.day.month, widget.day.day, 23, 59);
      final clipped = e.isAfter(dayEnd) ? dayEnd : e;
      return clipped.difference(i.start).inMinutes < 30 ? i.start.add(const Duration(minutes: 30)) : clipped;
    }

    // Group into clusters of mutually overlapping items, then assign columns.
    final sorted = [...items]..sort((a, b) => a.start.compareTo(b.start));
    var cluster = <DayItem>[];
    DateTime? clusterEnd;
    void flush() {
      if (cluster.isEmpty) return;
      final cols = <List<DayItem>>[];
      for (final i in cluster) {
        final col = cols.indexWhere((col) => !endOf(col.last).isAfter(i.start));
        if (col < 0) {
          cols.add([i]);
        } else {
          cols[col].add(i);
        }
      }
      final shown = math.min(cols.length, 3);
      final w = width / shown;
      for (var ci = 0; ci < cols.length; ci++) {
        for (final i in cols[ci]) {
          if (ci >= 3) continue;
          final top = (i.start.hour * 60 + i.start.minute) / 60 * _hourHeight;
          final height = endOf(i).difference(i.start).inMinutes / 60 * _hourHeight;
          final hidden = ci == 2 && cols.length > 3 ? cols.skip(3).expand((x) => x).length : 0;
          out.add(
            Positioned(
              top: top + 1,
              left: _gutter + Space.xs + ci * w,
              width: w - 4,
              height: math.max(height - 3, 24),
              child: _Block(item: i, end: endOf(i), more: hidden),
            ),
          );
        }
      }
      cluster = [];
      clusterEnd = null;
    }

    for (final i in sorted) {
      if (clusterEnd != null && !i.start.isBefore(clusterEnd!)) flush();
      cluster.add(i);
      final e = endOf(i);
      if (clusterEnd == null || e.isAfter(clusterEnd!)) clusterEnd = e;
    }
    flush();
    return out;
  }
}

/// Big date + weekday / month, and the "items" / "busy" pills (mockup 06). Tap → mini month (S-18).
class _Header extends ConsumerWidget {
  const _Header({required this.day, required this.items, required this.busyMinutes});
  final DateTime day;
  final int items;
  final int busyMinutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final busy = busyMinutes < 60 ? l10n.minutesShort(busyMinutes) : l10n.hoursShort((busyMinutes / 60).round());
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.s),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.row),
              onTap: () async {
                final d = await showMiniMonth(context, day);
                if (d != null) ref.read(homeProvider.notifier).setDate(d);
              },
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text('${day.day}', maxLines: 1, style: text.displayLarge?.copyWith(height: 1)),
                  ),
                  const SizedBox(width: Space.m),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.weekdayLong(day), style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(f.monthYear(day), style: text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Pill(value: '$items', label: l10n.statItems(items)),
          const SizedBox(width: Space.s),
          _Pill(value: busy, label: l10n.statBusy),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    // Fixed 60 × 48 so both pills match; values shrink rather than overflow.
    return Container(
      width: 60,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
      decoration: BoxDecoration(color: c.bgGrouped, borderRadius: BorderRadius.circular(Radii.row)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: CountText(
              int.tryParse(value) ?? 0,
              format: (n) => int.tryParse(value) == null ? value : '$n',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.1),
            ),
          ),
          Text(
            label,
            style: text.labelSmall?.copyWith(fontSize: 11, height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// The selected day's week (mockup 06): the blue circle slides to the chosen day; type-colored dots.
class _DayStrip extends ConsumerWidget {
  const _DayStrip({required this.selected});
  final DateTime selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final start = addDays(selected, -((selected.weekday - firstWeekday(context) + 7) % 7));
    final items = ref.watch(rangeProvider((from: start, to: addDays(start, 6)))) ?? const <DayItem>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.m, 0, Space.m, Space.s),
      child: SlidingCells(
        count: 7,
        selected: selected.difference(start).inDays,
        height: 74,
        // Fixed rows: 16 weekday + 4 + 40 circle + 4 + 6 dots + 4.
        inset: const EdgeInsets.only(top: 20, bottom: 14),
        highlight: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: c.accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
          ),
        ),
        cell: (context, i) {
          final day = addDays(start, i);
          final kinds = items.where((x) => x.day == day && !x.resolved).map((x) => x.reminder.kind).toSet();
          final isSel = day == selected;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ref.read(homeProvider.notifier).setDate(day),
            child: Column(
              children: [
                SizedBox(height: 16, child: Text(f.weekdayNarrow(day), style: text.labelSmall)),
                const SizedBox(height: Space.xs),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: Motion.standard,
                      style: text.titleMedium!.copyWith(
                        color: isSel ? Colors.white : (day == today ? c.accent : c.textPrimary),
                      ),
                      child: Text('${day.day}', maxLines: 1),
                    ),
                  ),
                ),
                const SizedBox(height: Space.xs),
                SizedBox(
                  height: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final k in Kind.values.where(kinds.contains).take(3))
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(color: c.kind(k), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HourLine extends StatelessWidget {
  const _HourLine({required this.hour, this.hideLabel = false});
  final int hour;
  final bool hideLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    return Positioned(
      top: hour * _hourHeight,
      left: 0,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _gutter,
            child: hour == 0 || hideLabel
                ? null
                : Transform.translate(
                    offset: const Offset(0, -9),
                    child: Text(
                      f.time(DateTime.utc(2026, 1, 1, hour)).replaceAll(':00', ''),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
          ),
          Expanded(child: Container(height: 0.5, color: c.separator.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

/// Red now line with its time in a pill on the left (mockup 06).
class _NowLine extends StatelessWidget {
  const _NowLine({required this.zone});
  final String zone;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final now = instantToWall(DateTime.now().toUtc(), zone);
    final top = (now.hour * 60 + now.minute) / 60 * _hourHeight;
    return Positioned(
      top: top - 10,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: c.danger, borderRadius: BorderRadius.circular(Radii.chip)),
              child: Text(
                f.time(now).replaceAll(RegExp(r'\s?[AaPp]\.?[Mm]\.?$'), ''),
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(child: Container(height: 1.5, color: c.danger)),
          ],
        ),
      ),
    );
  }
}

/// Time-grid block (mockup 06): tinted fill, 3 dp type-color bar, item icon + title, time range,
/// a bell when it has alerts; faded + struck through when done.
class _Block extends StatelessWidget {
  const _Block({required this.item, required this.end, this.more = 0});
  final DayItem item;
  final DateTime end;
  final int more;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = item.reminder;
    final color = item.overdue ? c.danger : c.kind(r.kind);
    final done = item.resolved;
    final fill = color.withValues(alpha: done ? (dark ? 0.12 : 0.06) : (dark ? 0.24 : 0.12));
    final fg = done ? c.textSecondary : c.textPrimary;
    final range = item.end == null ? f.time(item.start) : l10n.timeRange(f.time(item.start), f.time(end));
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(Radii.row - 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openDetail(context, r, item.occurrenceKey),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: color.withValues(alpha: done ? 0.4 : 1)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.s, Space.xs, Space.s, Space.xs),
                child: LayoutBuilder(
                  builder: (_, box) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(glyphIcon(glyphFor(r)), size: 16, color: done ? c.textSecondary : color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              more > 0 ? '${r.title} · +$more' : r.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w700,
                                decoration: done ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (r.alertPlan.isNotEmpty && !done) Icon(AppIcons.alert, size: 15, color: color),
                        ],
                      ),
                      if (box.maxHeight > 40)
                        Text(range, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// All-day chip (mockup 06): type-tinted, item icon + title; overdue red; done faded.
class _AllDayChip extends StatelessWidget {
  const _AllDayChip({required this.label, required this.icon, required this.color, this.done = false, this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final deep = Color.lerp(color, Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, 0.2)!;
    return Material(
      color: color.withValues(alpha: done ? 0.06 : 0.14),
      borderRadius: BorderRadius.circular(Radii.row - 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.row - 2),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: deep),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(
                    color: deep,
                    fontWeight: FontWeight.w600,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
