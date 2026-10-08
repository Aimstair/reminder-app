/// S-12 Schedule view — built to mockup `docs/design/mockups/02-schedule-home.png` (DS11, DS12):
/// accent date line + greeting + progress ring, week strip, filter chips, Up next + occasion cards
/// side by side, digest (S-41), then Overdue · Today · Tomorrow · This week · Later · {Month Year}
/// groups (VW-12) of rows with a round checkbox and the item's icon tile. Swipe right = Done,
/// swipe left = Reschedule.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../data/prefs_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/bell.dart';
import '../../ui/format.dart';
import '../../ui/money_format.dart';
import '../../ui/art.dart';
import '../../ui/icons.dart';
import '../../ui/motion.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../actions/occurrence_actions.dart';
import '../attachments/attachments.dart' show openAttachment;
import '../digest/digest_card.dart';
import '../month/month_view.dart' show firstWeekday, showMiniMonth;

/// Quick filter chips on Schedule (mockup 02). Session-only; the drawer filters (VW-2) still apply.
enum QuickFilter { all, personal, work, bills, occasions, events, meetings }

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
  QuickFilter.bills => r.kind == Kind.bill, // BIL-6
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
    // VW-15: the next meeting within 7 days and the next occasion within 30.
    final upNext = _nextMeeting(items, now);
    final spotlight = items
        .where((i) => i.reminder.kind == Kind.occasion && i.group != ScheduleGroup.overdue && !i.state.isResolved)
        .where((i) => i.start.difference(today).inDays <= 30)
        .firstOrNull;

    return RefreshIndicator.adaptive(
      onRefresh: () => ref.read(servicesProvider).refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(done: progress.done, total: progress.total),
          ),
          const SliverToBoxAdapter(child: _WeekStrip()),
          const SliverToBoxAdapter(child: _FilterChips()),
          if (quick == QuickFilter.bills) const SliverToBoxAdapter(child: _BillsSummaryCard()),
          if (digest != null) const SliverToBoxAdapter(child: DigestCard()),
          if (all.isEmpty && progress.done == 0)
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
                  // Fixed height: both cards line up whatever their text (titles truncate).
                  child: SizedBox(
                    height: _HomeCard.height,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (upNext != null) Expanded(child: _MeetingCard(item: upNext)),
                        if (upNext != null && spotlight != null) const SizedBox(width: Space.m),
                        if (spotlight != null) Expanded(child: _OccasionCard(item: spotlight)),
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
            for (final (n, s) in sections.indexed) ...[
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
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  index: n,
                  child: InsetGroup(
                    indent: ReminderRow.dividerIndent,
                    children: [for (final i in s.items) _SwipeRow(key: ValueKey(i.occurrenceId), item: i)],
                  ),
                ),
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
    ref.read(quickFilterProvider.notifier).set(QuickFilter.all);
  }

  /// VW-15: the next meeting that hasn't ended and starts within 7 days (one in progress counts).
  static ScheduleItem? _nextMeeting(List<ScheduleItem> items, DateTime now) => items
      .where(
        (i) =>
            i.reminder.kind == Kind.meeting &&
            i.reminder.timing.type == TimingType.datetime &&
            !i.state.isResolved &&
            (i.times.anchor.isAfter(now) || i.times.end.isAfter(now)) &&
            i.times.anchor.difference(now) < const Duration(days: 7),
      )
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
        out.add((
          title: title,
          overdue: i.group == ScheduleGroup.overdue,
          today: i.group == ScheduleGroup.today,
          items: [],
        ));
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
      padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.m),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: c.accent, fontWeight: FontWeight.w600, letterSpacing: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(greeting, style: text.displaySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (total > 0) ...[const SizedBox(width: Space.m), _ProgressRing(done: done, total: total)],
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
                CountText(
                  done,
                  format: (n) => '$n/$total',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.1),
                ),
                Text(l10n.ringDone, style: text.labelSmall?.copyWith(fontSize: 10, height: 1.1)),
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
              child: Builder(
                builder: (context) {
                  final day = addDays(start, i);
                  final kinds = items.where((x) => x.day == day && !x.resolved).map((x) => x.reminder.kind).toSet();
                  final isToday = day == today;
                  final fg = isToday ? Colors.white : c.textPrimary;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Pressable(
                      scale: 0.92,
                      onTap: () => ref.read(homeProvider.notifier).openDay(day),
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: isToday ? c.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(Radii.card),
                          boxShadow: isToday
                              ? [
                                  BoxShadow(
                                    color: c.accent.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              f.weekdayNarrow(day),
                              style: text.labelSmall?.copyWith(color: isToday ? Colors.white70 : null),
                            ),
                            const SizedBox(height: 2),
                            Text('${day.day}', style: text.headlineSmall?.copyWith(color: fg)),
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
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Filter chips (mockup 02): All · Personal · Work · Bills · Occasions · Events · Meetings.
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
      (QuickFilter.bills, l10n.filterBills, c.bill),
      (QuickFilter.occasions, l10n.filterOccasions, c.occasion),
      (QuickFilter.events, l10n.filterEvents, c.event),
      (QuickFilter.meetings, l10n.filterMeetings, c.meeting),
    ];
    final index = chips.indexWhere((x) => x.$1 == current);
    // The dark pill slides to the chosen chip; labels cross-fade their color.
    return SizedBox(
      height: 52,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
        child: SlidingHighlightRow(
          selected: index,
          highlight: DecoratedBox(
            decoration: ShapeDecoration(color: dark ? Colors.white : Colors.black, shape: const StadiumBorder()),
          ),
          children: [
            for (final (value, label, dot) in chips)
              Pressable(
                scale: 0.94,
                onTap: () => ref.read(quickFilterProvider.notifier).set(value),
                child: AnimatedContainer(
                  duration: Motion.standard,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: Space.l),
                  decoration: ShapeDecoration(
                    color: value == current ? c.surface.withValues(alpha: 0) : c.surface,
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dot != null) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: Space.s),
                      ],
                      AnimatedDefaultTextStyle(
                        duration: Motion.standard,
                        style: text.titleSmall!.copyWith(
                          color: value == current ? (dark ? Colors.black : Colors.white) : c.textPrimary,
                        ),
                        child: Text(label, maxLines: 1),
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

/// Meeting card (VW-15, mockup 02): the next meeting within 7 days — subtype tile, countdown pill,
/// "Up next" / "Now", title, time range, and a footer: Join for a video call with a link, else the subtype.
class _MeetingCard extends ConsumerWidget {
  const _MeetingCard({required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final r = item.reminder;
    final color = c.meeting;
    final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();
    final today = ref.watch(todayProvider);
    final started = !item.times.anchor.isAfter(now);
    final zone = ref.watch(prefsProvider).deviceTimeZone;
    final end = item.times.end.isAfter(item.times.anchor) ? instantToWall(item.times.end, zone) : null;
    final days = dateOnly(item.start).difference(today).inDays;
    // Round up: 40 s away reads "in 1 min", never "in 0 min".
    final mins = (item.times.anchor.difference(now).inSeconds / 60).ceil();
    final countdown = started
        ? l10n.homeNowPill
        : days == 0
        ? l10n.inTime(mins < 60 ? l10n.relMinutes(mins) : l10n.relHours((mins / 60).round()))
        : days == 1
        ? l10n.dayTomorrow
        : f.weekdayShort(item.start);
    final sub = r.subKind?.kind == Kind.meeting ? r.subKind : guessSubKind(Kind.meeting, r.title);
    // VW-15: the first link attachment, else the first web address in the notes.
    final link =
        r.attachments.where((a) => a.kind == AttachmentKind.link).firstOrNull ??
        switch (findLinks(r.notes ?? '').firstOrNull) {
          final l? => Attachment.link(l.url),
          null => null,
        };
    return _HomeCard(
      tint: color,
      onTap: () => openDetail(context, r, item.occurrenceKey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon: subKindIcon(sub, Kind.meeting), color: color, size: 40, filled: true),
              const SizedBox(width: Space.s),
              Expanded(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 3),
                    decoration: BoxDecoration(
                      color: started ? color : c.surface,
                      borderRadius: BorderRadius.circular(Radii.chip),
                    ),
                    child: Text(
                      countdown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(
                        color: started ? Colors.white : color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            (started ? l10n.homeNow : l10n.upNext).toUpperCase(),
            maxLines: 1,
            style: text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            r.title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            end == null ? f.time(item.start) : l10n.timeRange(f.time(item.start), f.time(end)),
            style: text.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Space.s),
          SizedBox(
            height: 30,
            child: sub == SubKind.video && link != null
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size(0, 30),
                      shape: const StadiumBorder(),
                      textStyle: text.titleSmall,
                      padding: const EdgeInsets.symmetric(horizontal: Space.m),
                    ),
                    onPressed: () => openAttachment(context, ref, link), // ATT-4
                    icon: const Icon(AppIcons.video, size: 16),
                    label: Text(l10n.actionJoin, maxLines: 1),
                  )
                : Row(
                    children: [
                      Icon(subKindIcon(sub, Kind.meeting), size: 15, color: c.textSecondary),
                      const SizedBox(width: Space.xs),
                      Flexible(
                        child: Text(
                          sub == null ? f.kind(Kind.meeting) : f.subKind(sub),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Occasion card (VW-15, mockup 02): color and illustration by subtype, "In 6 days", prep progress,
/// "I'm prepared".
class _OccasionCard extends ConsumerWidget {
  const _OccasionCard({required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final r = item.reminder;
    final sub = r.subKind?.kind == Kind.occasion ? r.subKind : null;
    final color = c.occasionSub(sub);
    final today = ref.watch(todayProvider);
    final days = item.start.difference(today).inDays;
    final prepared = item.state == OccurrenceState.prepared;
    // One segment per alert stage; filled once its day has come (prep nudges, then the day).
    final stages = r.alertPlan;
    final reached = stages.where((s) => !_stageDay(item.start, s.offset).isAfter(today)).length;
    return _HomeCard(
      tint: color,
      onTap: () => openDetail(context, r, item.occurrenceKey),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -4,
            top: -6,
            child: ExcludeSemantics(
              child: Floating(
                amplitude: 3,
                child: _OccasionArt(sub: sub, title: r.title, color: color),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                (days <= 0 ? l10n.groupToday : l10n.inTime(l10n.relDays(days))).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                r.title,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
                            color: i < reached || prepared ? color : c.separator.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              const Spacer(),
              if (prepared)
                Text(l10n.statePrepared, maxLines: 1, style: text.titleSmall?.copyWith(color: color))
              else if (!r.isCalendarEvent && r.alertPlan.any((s) => s.offset.amount < 0))
                SizedBox(
                  height: 30,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size(0, 30),
                      shape: const StadiumBorder(),
                      textStyle: text.titleSmall,
                      padding: const EdgeInsets.symmetric(horizontal: Space.m),
                    ),
                    onPressed: () => OccurrenceActions(context, ref).prepared(r, item.occurrenceKey), // OCC-3
                    child: Text(l10n.actionPrepared, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
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

/// DS16 occasion illustrations, drawn from filled icons: gift · two hearts · a holiday picture ·
/// lotus · confetti. Each has a small companion shape so it reads as a picture, not an icon.
class _OccasionArt extends StatelessWidget {
  const _OccasionArt({required this.sub, required this.title, required this.color});
  final SubKind? sub;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final light = Color.lerp(color, Colors.white, 0.45)!;
    final (IconData main, Color mainColor, IconData? extra, Color extraColor) = switch (sub) {
      SubKind.birthday => (AppIcons.giftSolid, color, AppIcons.sparkleSolid, c.holiday),
      SubKind.anniversary => (AppIcons.heartSolid, color, AppIcons.heartSolid, light),
      SubKind.holiday => _holiday(c),
      SubKind.memorial => (AppIcons.lotusSolid, color, null, light),
      _ => (AppIcons.confettiSolid, color, AppIcons.sparkleSolid, c.holiday),
    };
    return SizedBox(
      width: 76,
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: 0, top: 4, child: Icon(main, size: 60, color: mainColor)),
          if (extra != null)
            Positioned(
              left: 0,
              top: sub == SubKind.anniversary ? 26 : 0,
              child: Transform.rotate(
                angle: sub == SubKind.anniversary ? -0.35 : 0,
                child: Icon(extra, size: sub == SubKind.anniversary ? 30 : 22, color: extraColor),
              ),
            ),
        ],
      ),
    );
  }

  /// Christmas → tree, New Year → champagne, Halloween → ghost, Easter → egg; any other holiday → star.
  (IconData, Color, IconData?, Color) _holiday(AppColors c) {
    final t = title.toLowerCase();
    bool has(List<String> w) => w.any(t.contains);
    if (has(['christmas', 'xmas'])) return (AppIcons.treeSolid, c.success, AppIcons.starSolid, c.holiday);
    if (has(['new year'])) return (AppIcons.champagneSolid, c.holiday, AppIcons.sparkleSolid, c.occasion);
    if (has(['halloween'])) return (AppIcons.ghostSolid, c.textSecondary, AppIcons.starSolid, c.event);
    if (has(['easter'])) return (AppIcons.eggSolid, c.purple, AppIcons.sparkleSolid, c.holiday);
    return (AppIcons.starSolid, c.holiday, AppIcons.sparkleSolid, c.event);
  }
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
    return FadeSlideIn(
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.all(Space.l),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Color.alphaBlend(tint.withValues(alpha: dark ? 0.22 : 0.12), AppColors.of(context).surface),
            borderRadius: BorderRadius.circular(Radii.card + 4),
          ),
          child: child,
        ),
      ),
    );
  }

  static const height = 184.0;
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
      // Title + badge fill an Expanded on the left, so the capped note always sits on the right edge
      // (a loose Flexible keeps its unused share and would leave the note short of the edge).
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: Space.s),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 1),
                  decoration: BoxDecoration(
                    color: badge.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                  child: Text('$count', style: text.titleSmall?.copyWith(color: badge)),
                ),
              ],
            ),
          ),
          if (meta != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Padding(
                padding: const EdgeInsets.only(left: Space.s),
                child: Text(meta!, style: text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwipeRow extends ConsumerStatefulWidget {
  const _SwipeRow({super.key, required this.item});
  final ScheduleItem item;

  @override
  ConsumerState<_SwipeRow> createState() => _SwipeRowState();
}

class _SwipeRowState extends ConsumerState<_SwipeRow> with TickerProviderStateMixin {
  /// VW-16: the burst around the checkbox, then the row folding away.
  late final _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final _fold = AnimationController(vsync: this, duration: Motion.standard, value: 1);
  bool _ticked = false;

  ScheduleItem get item => widget.item;

  @override
  void dispose() {
    _burst.dispose();
    _fold.dispose();
    super.dispose();
  }

  /// VW-16: fill + burst, strike through, fold away — then record Done (which offers Undo).
  Future<void> _tick() async {
    if (_ticked) return;
    final actions = OccurrenceActions(context, ref);
    final still = reduceMotion(context);
    setState(() => _ticked = true);
    if (!still) {
      await _burst.forward(from: 0);
      if (!mounted) return;
      await _fold.animateTo(0, curve: Curves.easeInCubic);
    }
    await actions.done(item.reminder, item.occurrenceKey);
    // Done leaves the list a moment later; if the row is still here, it wasn't recorded — show it again.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _ticked = false);
    _fold.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final l10n = AppLocalizations.of(context);
    final r = item.reminder;
    final today = ref.watch(todayProvider);
    final actions = OccurrenceActions(context, ref);
    final row = Stack(
      children: [
        ReminderRow(
          reminder: r,
          when: _when(item, l10n, f, today),
          overdue: item.overdue,
          done: _ticked,
          nagLabel: r.nagInterval == null ? null : l10n.nagEvery(_short(l10n, r.nagInterval!)), // ALR-9
          onTap: () => openDetail(context, r, item.occurrenceKey),
          onCheck: r.completable && !r.isCalendarEvent ? _tick : null,
        ),
        // Centered on the checkbox: 4 row padding + 8 touch padding + 12 half circle.
        Positioned(
          left: 24 - _TickBurst.size / 2,
          top: ReminderRow.rowHeight / 2 - _TickBurst.size / 2,
          child: IgnorePointer(
            child: _TickBurst(animation: _burst, color: c.kind(r.kind)),
          ),
        ),
      ],
    );
    if (r.isCalendarEvent) return row;
    final swipe = Dismissible(
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
    return SizeTransition(
      sizeFactor: _fold,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: _fold, child: swipe),
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

/// BIL-6: "Due this month" total and how many bills are unpaid, shown with the Bills filter.
class _BillsSummaryCard extends ConsumerWidget {
  const _BillsSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final today = ref.watch(todayProvider);
    final monthEnd = DateTime.utc(today.year, today.month + 1, 0);
    final items = ref.watch(rangeProvider((from: today, to: monthEnd))) ?? const <DayItem>[];
    final s = billsSummary(items, preferred: deviceCurrency());
    final total = s.totals.isEmpty ? null : f.money(s.totals.first);
    final more = s.totals.skip(1).map(f.money).join(' + ');
    return FadeSlideIn(
      child: Container(
        height: 88,
        margin: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
        padding: const EdgeInsets.symmetric(horizontal: Space.l),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card)),
        child: Row(
          children: [
            GlyphBadge(icon: AppIcons.bill, color: c.bill, size: 48),
            const SizedBox(width: Space.m + 2),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.unpaid > 0)
                    Text(l10n.billsDueMonth, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    s.unpaid == 0 ? l10n.billsNothingDue : (total ?? l10n.billsUnpaid(s.unpaid)),
                    style: s.unpaid == 0 || total == null ? text.titleMedium : text.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (more.isNotEmpty)
                    Text('+ $more', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (s.unpaid > 0 && total != null) ...[
              const SizedBox(width: Space.s),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  l10n.billsUnpaid(s.unpaid),
                  style: text.bodyMedium?.copyWith(color: c.warning),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// VW-16: a ring and eight dots bursting out of a ticked checkbox, fading as they go.
class _TickBurst extends AnimatedWidget {
  const _TickBurst({required Animation<double> animation, required this.color}) : super(listenable: animation);
  final Color color;

  static const size = 64.0;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    if (t == 0 || t == 1) return const SizedBox(width: size, height: size);
    return CustomPaint(size: const Size.square(size), painter: _BurstPainter(t, color));
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final out = Curves.easeOutCubic.transform(t);
    final fade = 1 - Curves.easeIn.transform(t);
    canvas.drawCircle(
      center,
      12 + 10 * out,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * fade
        ..color = color.withValues(alpha: 0.5 * fade),
    );
    final dot = Paint()..color = color.withValues(alpha: fade);
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4 + pi / 8;
      final d = 14 + 16 * out;
      canvas.drawCircle(center + Offset(cos(a) * d, sin(a) * d), (i.isEven ? 2.8 : 2.0) * fade + 0.4, dot);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t || old.color != color;
}
