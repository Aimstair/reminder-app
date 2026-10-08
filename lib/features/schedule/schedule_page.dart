/// S-12 Schedule view: greeting + daily progress, week strip, home cards (Up next, occasion
/// spotlight), digest (S-41), then Overdue · Today · Tomorrow · This week · Later · {Month Year}
/// groups (VW-12). Swipe right = Done, swipe left = Reschedule.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../data/prefs_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/bell.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../actions/occurrence_actions.dart';
import '../digest/digest_card.dart';
import '../../ui/icons.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(scheduleProvider);
    if (items == null) return const Center(child: CircularProgressIndicator.adaptive());

    final l10n = AppLocalizations.of(context);
    final f = Fmt.of(context);
    final filters = ref.watch(filtersProvider);
    final sections = _sections(items, l10n, f, ref.watch(todayProvider));
    final progress = ref.watch(todayProgressProvider);
    final hasToday = items.any((i) => i.group == ScheduleGroup.today || i.group == ScheduleGroup.overdue);
    final digest = ref.watch(digestProvider);
    final upNext = _upNext(items, ref.watch(nowProvider).value);
    final spotlight = items
        .where((i) => i.reminder.kind == Kind.occasion && i.group != ScheduleGroup.overdue)
        .where((i) => i.times.anchor.difference(DateTime.now().toUtc()).inDays <= 14)
        .firstOrNull;

    return RefreshIndicator.adaptive(
      onRefresh: () => ref.read(servicesProvider).refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(done: progress.done, total: progress.total)),
          const SliverToBoxAdapter(child: _WeekStrip()),
          if (digest != null) const SliverToBoxAdapter(child: DigestCard()),
          if (items.isEmpty && progress.done == 0)
            SliverFillRemaining(
              hasScrollBody: false,
              child: filters.active
                  ? EmptyState(
                      title: l10n.filterEmpty,
                      action: l10n.actionClearFilters,
                      onAction: () => _clearFilters(ref),
                    )
                  : EmptyState(title: l10n.emptyNoneTitle, sub: l10n.emptyNoneSub, mood: BellMood.thinking),
            )
          else ...[
            if (upNext != null || spotlight != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
                  child: Column(
                    children: [
                      if (upNext != null) _UpNextCard(item: upNext),
                      if (spotlight != null && spotlight != upNext) ...[
                        if (upNext != null) const SizedBox(height: Space.m),
                        _SpotlightCard(item: spotlight),
                      ],
                    ],
                  ),
                ),
              ),
            if (!hasToday)
              SliverToBoxAdapter(
                child: progress.done > 0
                    ? EmptyState(title: l10n.allClearTitle, sub: l10n.allClearSub, compact: true, mood: BellMood.happy)
                    : EmptyState(title: l10n.emptyTodayTitle, sub: l10n.emptyTodaySub, compact: true),
              ),
            for (final s in sections) ...[
              SliverToBoxAdapter(child: SectionHeader(s.title, count: s.items.length, danger: s.overdue)),
              SliverToBoxAdapter(
                child: InsetGroup(children: [for (final i in s.items) _SwipeRow(item: i)]),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 96)), // room for the [+] button
          ],
        ],
      ),
    );
  }

  static Future<void> _clearFilters(WidgetRef ref) async {
    final p = ref.read(servicesProvider).prefs;
    await p.set(PrefKeys.hiddenKinds, const <String>[]);
    await p.set(PrefKeys.hiddenContexts, const <String>[]);
    await p.set(PrefKeys.hiddenCalendars, const <String>[]);
  }

  /// Next timed item starting within 12 hours.
  static ScheduleItem? _upNext(List<ScheduleItem> items, DateTime? now) {
    if (now == null) return null;
    return items
        .where((i) =>
            !i.overdue &&
            i.reminder.timing.type == TimingType.datetime &&
            i.times.anchor.isAfter(now) &&
            i.times.anchor.difference(now) < const Duration(hours: 12))
        .firstOrNull;
  }

  /// "Later" covers the rest of this month; after that, one header per month (VW-12).
  static List<({String title, bool overdue, List<ScheduleItem> items})> _sections(
    List<ScheduleItem> items,
    AppLocalizations l10n,
    Fmt f,
    DateTime today,
  ) {
    final out = <({String title, bool overdue, List<ScheduleItem> items})>[];
    for (final i in items) {
      final title = switch (i.group) {
        ScheduleGroup.overdue => l10n.groupOverdue,
        ScheduleGroup.today => l10n.groupToday,
        ScheduleGroup.tomorrow => l10n.groupTomorrow,
        ScheduleGroup.thisWeek => l10n.groupThisWeek,
        ScheduleGroup.later when i.start.year == today.year && i.start.month == today.month => l10n.groupLater,
        ScheduleGroup.later => f.monthYear(i.start),
      };
      if (out.isEmpty || out.last.title != title) {
        out.add((title: title, overdue: i.group == ScheduleGroup.overdue, items: []));
      }
      out.last.items.add(i);
    }
    return out;
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.done, required this.total});
  final int done, total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? l10n.greetingMorning
        : now.hour < 18
            ? l10n.greetingAfternoon
            : l10n.greetingEvening;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.m),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.dayLong(ref.watch(todayProvider)).toUpperCase(), style: text.labelSmall?.copyWith(letterSpacing: 0.6)),
                const SizedBox(height: Space.xs),
                Text(greeting, style: text.displaySmall),
              ],
            ),
          ),
          if (total > 0)
            Semantics(
              label: l10n.progressDone(done, total),
              child: SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: done / total),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => CircularProgressIndicator(
                        value: v,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        color: c.success,
                        backgroundColor: c.separator,
                      ),
                    ),
                    Text('$done/$total', style: text.labelSmall?.copyWith(color: c.textPrimary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Week strip with type-colored dots; tapping a day opens it in Day view.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final items = ref.watch(rangeProvider((from: today, to: addDays(today, 6)))) ?? const <DayItem>[];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.m),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(builder: (context) {
                final day = addDays(today, i);
                final kinds = items.where((x) => x.day == day && !x.resolved).map((x) => x.reminder.kind).toSet();
                final isToday = i == 0;
                return InkWell(
                  borderRadius: BorderRadius.circular(Radii.row),
                  onTap: () => ref.read(homeProvider.notifier).openDay(day),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.s),
                    child: Column(
                      children: [
                        Text(f.weekdayNarrow(day), style: text.labelSmall),
                        const SizedBox(height: Space.xs),
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: isToday ? c.accent : null, shape: BoxShape.circle),
                          child: Text(
                            '${day.day}',
                            style: text.bodyMedium?.copyWith(
                              color: isToday ? Colors.white : c.textPrimary,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        SizedBox(
                          height: 6,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final k in Kind.values.where(kinds.contains))
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
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

/// "Up next" countdown card tinted in the item's type color.
class _UpNextCard extends ConsumerWidget {
  const _UpNextCard({required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final color = c.kind(item.reminder.kind);
    final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();
    // Round up: 40 s away reads "in 1 min", never "in 0 min".
    final mins = (item.times.anchor.difference(now).inSeconds / 60).ceil().clamp(0, 9999);
    final countdown = mins < 60 ? l10n.relMinutes(mins) : l10n.relHours((mins / 60).round());
    final label = mins == 0 ? l10n.notifNow(f.time(item.start)) : l10n.notifBefore(countdown, f.time(item.start));
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(Radii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.card),
        onTap: () => openDetail(context, item.reminder, item.occurrenceKey),
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Row(
            children: [
              IconTile.kind(context, item.reminder.kind, size: 44),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: text.labelSmall?.copyWith(color: color, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(item.reminder.title, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(AppIcons.next, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Occasion spotlight: gift tile, days to go, "I'm prepared".
class _SpotlightCard extends ConsumerWidget {
  const _SpotlightCard({required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final r = item.reminder;
    final days = item.start.difference(ref.watch(todayProvider)).inDays;
    final prep = r.alertPlan.where((s) => s.offset.amount < 0).length;
    final prepared = item.state == OccurrenceState.prepared;
    return Material(
      borderRadius: BorderRadius.circular(Radii.card),
      clipBehavior: Clip.antiAlias,
      color: c.surface,
      child: InkWell(
        onTap: () => openDetail(context, r, item.occurrenceKey),
        child: Row(
          children: [
            Container(
              width: 92,
              height: 104,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.occasion, Color.lerp(c.occasion, c.event, 0.5)!],
                ),
              ),
              child: const Icon(AppIcons.gift, color: Colors.white, size: 44),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Space.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (days <= 0 ? l10n.groupToday : l10n.notifBefore(l10n.relDays(days), f.date(item.start)))
                          .toUpperCase(),
                      style: text.labelSmall?.copyWith(color: c.occasion, letterSpacing: 0.5),
                    ),
                    Text(r.title, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Space.xs),
                    if (prepared)
                      Text(l10n.statePrepared, style: text.bodySmall?.copyWith(color: c.success))
                    else if (prep > 0 && !r.isCalendarEvent)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                          onPressed: () => OccurrenceActions(context, ref).prepared(r, item.occurrenceKey),
                          icon: const Icon(AppIcons.task, size: 18),
                          label: Text(l10n.actionPrepared),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeRow extends ConsumerWidget {
  const _SwipeRow({required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final l10n = AppLocalizations.of(context);
    final r = item.reminder;
    final allDay = r.timing.type == TimingType.date;
    final time = allDay ? l10n.allDay : f.time(item.start);
    // Under Today / Tomorrow the header already says the day; elsewhere (Overdue, later groups)
    // say "Today · 9:00 AM" or "Mon, Oct 12 · 9:00 AM".
    final showDate = item.group != ScheduleGroup.today && item.group != ScheduleGroup.tomorrow;
    final when = showDate ? f.when(item.start, allDay: allDay, today: ref.watch(todayProvider)) : time;
    final row = ReminderRow(
      reminder: r,
      when: when,
      overdue: item.overdue,
      onTap: () => openDetail(context, r, item.occurrenceKey),
    );
    if (r.isCalendarEvent) return row;
    final actions = OccurrenceActions(context, ref);
    return Dismissible(
      key: ValueKey(item.occurrenceId),
      direction: r.completable ? DismissDirection.horizontal : DismissDirection.endToStart,
      background: Container(
        color: c.success,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: Space.xxl),
        child: const Icon(AppIcons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: c.meeting,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Space.xxl),
        child: const Icon(AppIcons.reschedule, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.endToStart) {
          await actions.reschedule(r, item.occurrenceKey);
          return false; // the list updates itself if the date changed
        }
        return true;
      },
      onDismissed: (_) => actions.done(r, item.occurrenceKey),
      child: row,
    );
  }
}
