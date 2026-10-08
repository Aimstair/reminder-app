/// S-13 Day view (Notion Calendar structure, Things 3 finish): all-day strip on top (VW-3, with
/// "Overdue (n)" on today, VW-5), hourly grid with a now line (VW-11), overlapping items side by side
/// (max 3, then "+N"), swipe between days (VW-9), tap an empty slot to capture there (VW-8).
/// The grid is reused by 3 Day / Week in v1.2.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../data/prefs_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../actions/occurrence_actions.dart';
import '../capture/capture_sheet.dart';
import '../digest/digest_card.dart';
import '../../ui/icons.dart';

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
    return PageView.builder(
      controller: _pages,
      onPageChanged: (i) => ref.read(homeProvider.notifier).setDate(addDays(_base, i - _origin)),
      itemBuilder: (_, i) => _DayPage(day: addDays(_base, i - _origin)),
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
    _scroll = ScrollController(initialScrollOffset: hour * _hourHeight);
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
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final isToday = day == today;
    final showCompleted = ref.watch(prefsRepoProvider).flag(PrefKeys.showCompleted, fallback: true);
    final all = (ref.watch(rangeProvider((from: day, to: day))) ?? const <DayItem>[])
        .where((i) => showCompleted || !i.resolved)
        .toList();
    final allDay = all.where((i) => i.allDay).toList();
    final timed = all.where((i) => !i.allDay).toList();
    final overdue = isToday
        ? (ref.watch(scheduleProvider) ?? const <ScheduleItem>[]).where((i) => i.overdue && i.start.isBefore(day)).toList()
        : const <ScheduleItem>[];

    return Column(
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, Space.s),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: isToday ? c.danger : null, shape: BoxShape.circle),
                child: Text('${day.day}',
                    style: text.titleLarge?.copyWith(color: isToday ? Colors.white : c.textPrimary)),
              ),
              const SizedBox(width: Space.m),
              Text(f.dayLong(day).replaceAll(RegExp(r',? \d+$'), ''), style: text.titleMedium),
            ],
          ),
        ),
        if (isToday) const DigestCard(),
        // All-day strip
        if (allDay.isNotEmpty || overdue.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, Space.s),
            padding: const EdgeInsets.all(Space.s),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.row)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: Space.xs, bottom: Space.xs),
                  child: Text(l10n.allDay.toUpperCase(), style: text.labelSmall),
                ),
                if (overdue.isNotEmpty) ...[
                  InkWell(
                    onTap: () => setState(() => _overdueOpen = !_overdueOpen),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: Space.xs),
                      child: Row(
                        children: [
                          Icon(_overdueOpen ? AppIcons.collapse : AppIcons.expand, color: c.danger, size: 18),
                          Text(l10n.overdueCount(overdue.length), style: text.bodyMedium?.copyWith(color: c.danger)),
                        ],
                      ),
                    ),
                  ),
                  if (_overdueOpen)
                    for (final o in overdue)
                      _AllDayChip(
                        title: o.reminder.title,
                        kind: o.reminder.kind,
                        overdue: true,
                        onTap: () => openDetail(context, o.reminder, o.occurrenceKey),
                      ),
                ],
                for (final i in allDay)
                  _AllDayChip(
                    title: i.reminder.title,
                    kind: i.reminder.kind,
                    done: i.resolved,
                    overdue: i.overdue,
                    onTap: () => openDetail(context, i.reminder, i.occurrenceKey),
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
                  children: [
                    for (var h = 0; h < 24; h++) _HourLine(hour: h),
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
                    ..._blocks(context, timed, box.maxWidth - _gutter - Space.s),
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
          out.add(Positioned(
            top: top,
            left: _gutter + ci * w,
            width: w - 2,
            height: math.max(height - 2, 22),
            child: _Block(item: i, more: hidden),
          ));
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

class _HourLine extends StatelessWidget {
  const _HourLine({required this.hour});
  final int hour;

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
            child: hour == 0
                ? null
                : Transform.translate(
                    offset: const Offset(0, -8),
                    child: Text(
                      f.time(DateTime.utc(2026, 1, 1, hour)).replaceAll(':00', ''),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
          ),
          Expanded(child: Container(height: 0.5, color: c.separator.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

class _NowLine extends StatelessWidget {
  const _NowLine({required this.zone});
  final String zone;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final now = instantToWall(DateTime.now().toUtc(), zone);
    final top = (now.hour * 60 + now.minute) / 60 * _hourHeight;
    return Positioned(
      top: top - 3,
      left: _gutter - 3,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: c.danger, shape: BoxShape.circle)),
            Expanded(child: Container(height: 1.5, color: c.danger)),
          ],
        ),
      ),
    );
  }
}

/// Time-grid block (design-direction "Calendar block style"): tinted fill, 3 dp type-color bar,
/// faded + struck through when done.
class _Block extends StatelessWidget {
  const _Block({required this.item, this.more = 0});
  final DayItem item;
  final int more;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = c.kind(item.reminder.kind);
    final done = item.resolved;
    final fill = color.withValues(alpha: done ? (dark ? 0.12 : 0.06) : (dark ? 0.24 : 0.12));
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openDetail(context, item.reminder, item.occurrenceKey),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: item.overdue ? c.danger : color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: LayoutBuilder(
                  builder: (_, box) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        more > 0 ? '${item.reminder.title} · +$more' : item.reminder.title,
                        maxLines: box.maxHeight > 36 ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: done ? c.textSecondary : c.textPrimary,
                          fontWeight: FontWeight.w600,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (box.maxHeight > 36)
                        Text(f.time(item.start), style: text.labelSmall, maxLines: 1),
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

class _AllDayChip extends StatelessWidget {
  const _AllDayChip({required this.title, required this.kind, this.done = false, this.overdue = false, this.onTap});
  final String title;
  final Kind kind;
  final bool done;
  final bool overdue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = c.kind(kind);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Material(
        color: color.withValues(alpha: done ? 0.06 : 0.14),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 5),
            child: Row(
              children: [
                Icon(kindIcon(kind), size: 14, color: overdue ? c.danger : color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: done ? c.textSecondary : (overdue ? c.danger : c.textPrimary),
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
