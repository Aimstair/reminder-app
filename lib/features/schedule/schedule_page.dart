/// S-12 Schedule view — built to mockup `docs/design/mockups/02-schedule-home.png` (DS11, DS12):
/// accent date line + greeting + progress ring, week strip, filter chips, Up next + occasion cards
/// side by side, digest (S-41), then Overdue · Today · Tomorrow · This week · Later · {Month Year}
/// groups (VW-12) of rows with a round checkbox and the item's icon tile. Swipe right = Done,
/// swipe left = Reschedule.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../data/prefs_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/bell.dart';
import '../../ui/format.dart';
import '../../ui/icons.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../actions/occurrence_actions.dart';
import '../digest/digest_card.dart';
import '../month/month_view.dart' show firstWeekday, showMiniMonth;

/// Quick filter chips on Schedule (mockup 02). Session-only; the drawer filters (VW-2) still apply.
enum QuickFilter { all, personal, work, occasions, events, meetings }

class QuickFilterNotifier extends Notifier<QuickFilter> {
  @override
  QuickFilter build() => QuickFilter.all;
  void set(QuickFilter f) => state = f;
}

final quickFilterProvider = NotifierProvider<QuickFilterNotifier, QuickFilter>(QuickFilterNotifier.new);

bool _passes(QuickFilter f, Reminder r) => switch (f) {
  QuickFilter.all => true,
  QuickFilter.personal => r.context == ReminderContext.personal,
  QuickFilter.work => r.context == ReminderContext.work,
  QuickFilter.occasions => r.kind == Kind.occasion,
  QuickFilter.events => r.kind == Kind.event,
  QuickFilter.meetings => r.kind == Kind.meeting,
};

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(scheduleProvider);
    if (all == null) return const Center(child: CircularProgressIndicator.adaptive());

    final l10n = AppLocalizations.of(context);
    final f = Fmt.of(context);
    final quick = ref.watch(quickFilterProvider);
    final items = all.where((i) => _passes(quick, i.reminder)).toList();
    final filters = ref.watch(filtersProvider);
    final today = ref.watch(todayProvider);
    final sections = _sections(items, l10n, f, today);
    final progress = ref.watch(todayProgressProvider);
    final hasToday = items.any((i) => i.group == ScheduleGroup.today || i.group == ScheduleGroup.overdue);
    final digest = ref.watch(digestProvider);
    final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();
    final upNext = _upNext(items, now);
    final spotlight = items
        .where((i) => i.reminder.kind == Kind.occasion && i.group != ScheduleGroup.overdue)
        .where((i) => i.start.difference(today).inDays <= 14)
        .firstOrNull;

    return RefreshIndicator.adaptive(
      onRefresh: () => ref.read(servicesProvider).refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(done: progress.done, total: progress.total)),
          const SliverToBoxAdapter(child: _WeekStrip()),
          const SliverToBoxAdapter(child: _FilterChips()),
          if (digest != null) const SliverToBoxAdapter(child: DigestCard()),
          if (all.isEmpty && progress.done == 0)
            SliverFillRemaining(
              hasScrollBody: false,
              child: filters.active
                  ? EmptyState(title: l10n.filterEmpty, action: l10n.actionClearFilters, onAction: () => _clearFilters(ref))
                  : EmptyState(title: l10n.emptyNoneTitle, sub: l10n.emptyNoneSub, mood: BellMood.thinking),
            )
          else ...[
            if (upNext != null || spotlight != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (upNext != null) Expanded(child: _UpNextCard(item: upNext)),
                        if (upNext != null && spotlight != null && spotlight != upNext) const SizedBox(width: Space.m),
                        if (spotlight != null && spotlight != upNext) Expanded(child: _OccasionCard(item: spotlight)),
                      ],
                    ),
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
              SliverToBoxAdapter(
                child: _GroupHeader(
                  title: s.title,
                  count: s.items.length,
                  danger: s.overdue,
                  meta: s.overdue && s.items.any((i) => i.reminder.nagInterval != null)
                      ? l10n.sectionNagging
                      : (s.today && progress.done > 0 ? l10n.sectionDoneCount(progress.done) : null),
                ),
              ),
              SliverToBoxAdapter(child: InsetGroup(children: [for (final i in s.items) _SwipeRow(item: i)])),
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
    ref.read(quickFilterProvider.notifier).set(QuickFilter.all);
  }

  /// Next timed item starting within 12 hours.
  static ScheduleItem? _upNext(List<ScheduleItem> items, DateTime now) => items
      .where((i) =>
          !i.overdue &&
          i.reminder.timing.type == TimingType.datetime &&
          i.times.anchor.isAfter(now) &&
          i.times.anchor.difference(now) < const Duration(hours: 12))
      .firstOrNull;

  /// "Later" covers the rest of this month; after that, one header per month (VW-12).
  static List<({String title, bool overdue, bool today, List<ScheduleItem> items})> _sections(
    List<ScheduleItem> items,
    AppLocalizations l10n,
    Fmt f,
    DateTime today,
  ) {
    final out = <({String title, bool overdue, bool today, List<ScheduleItem> items})>[];
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
        out.add((title: title, overdue: i.group == ScheduleGroup.overdue, today: i.group == ScheduleGroup.today, items: []));
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
    final today = ref.watch(todayProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? l10n.greetingMorning : (hour < 18 ? l10n.greetingAfternoon : l10n.greetingEvening);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, Space.m),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tap the date for the mini month (S-18).
                InkWell(
                  borderRadius: BorderRadius.circular(Radii.chip),
                  onTap: () async {
                    final d = await showMiniMonth(context, today);
                    if (d != null) ref.read(homeProvider.notifier).openDay(d);
                  },
                  child: Text(
                    f.dayLong(today).toUpperCase(),
                    style: text.labelLarge?.copyWith(color: c.accent, fontWeight: FontWeight.w600, letterSpacing: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(greeting, style: text.displaySmall),
              ],
            ),
          ),
          if (total > 0) _ProgressRing(done: done, total: total),
        ],
      ),
    );
  }
}

/// "2/6 done" ring (mockup 02): green arc on a track, count + "done" inside.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.done, required this.total});
  final int done, total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: l10n.progressDone(done, total),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 54,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: done / total),
                duration: Motion.emphasized,
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  color: c.success,
                  backgroundColor: c.separator.withValues(alpha: 0.35),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$done/$total', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.1)),
                Text(l10n.ringDone, style: text.labelSmall?.copyWith(height: 1.1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Week strip (mockup 02): the current week; today is a filled rounded square; type-colored dots.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final start = addDays(today, -((today.weekday - firstWeekday(context) + 7) % 7));
    final items = ref.watch(rangeProvider((from: start, to: addDays(start, 6)))) ?? const <DayItem>[];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.m),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(builder: (context) {
                final day = addDays(start, i);
                final kinds = items.where((x) => x.day == day && !x.resolved).map((x) => x.reminder.kind).toSet();
                final isToday = day == today;
                final fg = isToday ? Colors.white : c.textPrimary;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: isToday ? c.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.card),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Radii.card),
                      onTap: () => ref.read(homeProvider.notifier).openDay(day),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.s),
                        child: Column(
                          children: [
                            Text(f.weekdayNarrow(day), style: text.labelSmall?.copyWith(color: isToday ? Colors.white70 : null)),
                            const SizedBox(height: 2),
                            Text('${day.day}', style: text.titleLarge?.copyWith(color: fg, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
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
                                      decoration: BoxDecoration(
                                        color: isToday ? Colors.white.withValues(alpha: 0.9) : c.kind(k),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

/// Filter chips (mockup 02): All · Personal · Work · Occasions · Events · Meetings.
class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final current = ref.watch(quickFilterProvider);
    final chips = <(QuickFilter, String, Color?)>[
      (QuickFilter.all, l10n.filterAll, null),
      (QuickFilter.personal, f.context(ReminderContext.personal), c.task),
      (QuickFilter.work, f.context(ReminderContext.work), c.meeting),
      (QuickFilter.occasions, l10n.filterOccasions, c.occasion),
      (QuickFilter.events, l10n.filterEvents, c.event),
      (QuickFilter.meetings, l10n.filterMeetings, c.meeting),
    ];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.s),
        itemBuilder: (_, i) {
          final (value, label, dot) = chips[i];
          final selected = value == current;
          final bg = selected ? (dark ? Colors.white : Colors.black) : c.surface;
          final fg = selected ? (dark ? Colors.black : Colors.white) : c.textPrimary;
          return Material(
            color: bg,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => ref.read(quickFilterProvider.notifier).set(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.l),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dot != null) ...[
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                      const SizedBox(width: Space.s),
                    ],
                    Text(label, style: text.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// "Up next" card (mockup 02): type-tinted, filled icon tile, "in 45 min" pill, title, time range.
class _UpNextCard extends ConsumerWidget {
  const _UpNextCard({required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final r = item.reminder;
    final color = c.kind(r.kind);
    final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();
    // Round up: 40 s away reads "in 1 min", never "in 0 min".
    final mins = (item.times.anchor.difference(now).inSeconds / 60).ceil().clamp(0, 9999);
    final countdown = mins == 0
        ? l10n.notifNow(f.time(item.start))
        : l10n.inTime(mins < 60 ? l10n.relMinutes(mins) : l10n.relHours((mins / 60).round()));
    final zone = ref.watch(prefsProvider).deviceTimeZone;
    final end = item.times.end.isAfter(item.times.anchor) ? instantToWall(item.times.end, zone) : null;
    return _HomeCard(
      tint: color,
      onTap: () => openDetail(context, r, item.occurrenceKey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon: glyphIcon(glyphFor(r)), color: color, size: 44, filled: true),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 3),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.chip)),
                child: Text(countdown, style: text.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Spacer(),
          Text(l10n.upNext.toUpperCase(), style: text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(r.title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(end == null ? f.time(item.start) : l10n.timeRange(f.time(item.start), f.time(end)), style: text.bodyMedium),
        ],
      ),
    );
  }
}

/// Occasion card (mockup 02): pink, gift, "in 6 days", prep progress, "I'm prepared".
class _OccasionCard extends ConsumerWidget {
  const _OccasionCard({required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final r = item.reminder;
    final today = ref.watch(todayProvider);
    final days = item.start.difference(today).inDays;
    final prepared = item.state == OccurrenceState.prepared;
    // One segment per alert stage; filled once its day has come (prep nudges, then the day).
    final stages = r.alertPlan;
    final reached = stages.where((s) => !_stageDay(item.start, s.offset).isAfter(today)).length;
    return _HomeCard(
      tint: c.occasion,
      onTap: () => openDetail(context, r, item.occurrenceKey),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -4, top: -6, child: Icon(AppIcons.giftSolid, size: 60, color: c.occasion)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 52),
              Text(
                (days <= 0 ? l10n.groupToday : l10n.inTime(l10n.relDays(days))).toUpperCase(),
                style: text.labelSmall?.copyWith(color: c.occasion, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(r.title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: Space.s),
              if (stages.isNotEmpty)
                Row(
                  children: [
                    for (var i = 0; i < stages.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: i < reached || prepared ? c.occasion : c.separator.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: Space.s),
              if (prepared)
                Text(l10n.statePrepared, style: text.labelLarge?.copyWith(color: c.occasion, fontWeight: FontWeight.w600))
              else if (!r.isCalendarEvent && r.alertPlan.any((s) => s.offset.amount < 0))
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.occasion,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: Space.l),
                  ),
                  onPressed: () => OccurrenceActions(context, ref).prepared(r, item.occurrenceKey), // OCC-3
                  child: Text(l10n.actionPrepared),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static DateTime _stageDay(DateTime day, AlertOffset o) => switch (o.unit) {
    OffsetUnit.minutes || OffsetUnit.hours => day,
    OffsetUnit.days => addDays(day, o.amount),
    OffsetUnit.weeks => addDays(day, o.amount * 7),
    OffsetUnit.months => DateTime.utc(day.year, day.month + o.amount, day.day),
  };
}

/// Rounded card tinted in a type color (home cards, mockup 02).
class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.tint, required this.child, this.onTap});
  final Color tint;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Color.alphaBlend(tint.withValues(alpha: dark ? 0.22 : 0.12), AppColors.of(context).surface),
      borderRadius: BorderRadius.circular(Radii.card + 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 168),
          child: Padding(padding: const EdgeInsets.all(Space.l), child: child),
        ),
      ),
    );
  }
}

/// Group header (mockup 02): title, count badge, and a quiet note on the right ("Nagging", "2 done").
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.count, this.danger = false, this.meta});
  final String title;
  final int count;
  final bool danger;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final color = danger ? c.danger : c.textPrimary;
    final badge = danger ? c.danger : c.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.l, Space.s),
      child: Row(
        children: [
          Text(title, style: text.titleLarge?.copyWith(color: color)),
          const SizedBox(width: Space.s),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 1),
            decoration: BoxDecoration(color: badge.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(Radii.chip)),
            child: Text('$count', style: text.labelLarge?.copyWith(color: badge, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          if (meta != null) Text(meta!, style: text.bodyMedium),
        ],
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
    final today = ref.watch(todayProvider);
    final actions = OccurrenceActions(context, ref);
    final row = ReminderRow(
      reminder: r,
      when: _when(item, l10n, f, today),
      overdue: item.overdue,
      nagLabel: r.nagInterval == null ? null : l10n.nagEvery(_short(l10n, r.nagInterval!)), // ALR-9
      onTap: () => openDetail(context, r, item.occurrenceKey),
      onCheck: r.completable && !r.isCalendarEvent ? () => actions.done(r, item.occurrenceKey) : null,
    );
    if (r.isCalendarEvent) return row;
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

  /// Subline (mockup 02): overdue → "Due yesterday" / "Due Sat" / "Due Oct 3"; Today/Tomorrow → time;
  /// later → "Mon, Oct 12 · 9:00 AM".
  static String _when(ScheduleItem i, AppLocalizations l10n, Fmt f, DateTime today) {
    final allDay = i.reminder.timing.type == TimingType.date;
    if (i.overdue) {
      final day = dateOnly(i.start);
      final ago = today.difference(day).inDays;
      final rel = ago <= 0
          ? (allDay ? l10n.groupToday.toLowerCase() : f.time(i.start))
          : ago == 1
              ? l10n.dayYesterday
              : ago < 7
                  ? f.weekdayShort(day)
                  : f.date(day, today: today);
      return l10n.dueWhen(rel);
    }
    if (i.group == ScheduleGroup.today || i.group == ScheduleGroup.tomorrow) {
      return allDay ? l10n.allDay : f.time(i.start);
    }
    return f.when(i.start, allDay: allDay, today: today);
  }

  static String _short(AppLocalizations l10n, Duration d) =>
      d.inMinutes % 60 == 0 ? l10n.hoursShort(d.inHours) : l10n.minutesShort(d.inMinutes);
}
