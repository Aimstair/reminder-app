/// S-12 Schedule view: greeting + daily progress, then Overdue · Today · Tomorrow · This week · Later ·
/// {Month Year} groups (VW-12). Swipe right = Done with Undo (OCC-5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../native/alarm_gateway.dart';
import '../../ui/tokens.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(scheduleProvider);
    if (items == null) return const Center(child: CircularProgressIndicator.adaptive());

    final l10n = AppLocalizations.of(context);
    final sections = _sections(items, l10n, Localizations.localeOf(context).toString());
    final progress = ref.watch(todayProgressProvider);
    final hasToday = items.any((i) => i.group == ScheduleGroup.today || i.group == ScheduleGroup.overdue);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header(done: progress.done, total: progress.total)),
        if (items.isEmpty && progress.done == 0)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _Empty(title: l10n.emptyNoneTitle, sub: l10n.emptyNoneSub),
          )
        else ...[
          if (!hasToday)
            SliverToBoxAdapter(
              child: progress.done > 0
                  ? _Empty(title: l10n.allClearTitle, sub: l10n.allClearSub, compact: true)
                  : _Empty(title: l10n.emptyTodayTitle, sub: l10n.emptyTodaySub, compact: true),
            ),
          for (final s in sections) ...[
            SliverToBoxAdapter(child: _GroupHeader(title: s.title, count: s.items.length, danger: s.overdue)),
            SliverToBoxAdapter(child: _Group(items: s.items)),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 96)), // room for the [+] button
        ],
      ],
    );
  }

  /// "Later" covers the rest of this month; after that, one header per month (VW-12).
  static List<({String title, bool overdue, List<ScheduleItem> items})> _sections(
    List<ScheduleItem> items,
    AppLocalizations l10n,
    String locale,
  ) {
    final out = <({String title, bool overdue, List<ScheduleItem> items})>[];
    final now = DateTime.now();
    for (final i in items) {
      final title = switch (i.group) {
        ScheduleGroup.overdue => l10n.groupOverdue,
        ScheduleGroup.today => l10n.groupToday,
        ScheduleGroup.tomorrow => l10n.groupTomorrow,
        ScheduleGroup.thisWeek => l10n.groupThisWeek,
        ScheduleGroup.later when i.start.year == now.year && i.start.month == now.month => l10n.groupLater,
        ScheduleGroup.later => DateFormat.yMMMM(locale).format(i.start),
      };
      if (out.isEmpty || out.last.title != title) {
        out.add((title: title, overdue: i.group == ScheduleGroup.overdue, items: []));
      }
      out.last.items.add(i);
    }
    return out;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.done, required this.total});
  final int done, total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.greetingMorning
        : hour < 18
            ? l10n.greetingAfternoon
            : l10n.greetingEvening;
    final date = DateFormat.MMMMEEEEd(Localizations.localeOf(context).toString()).format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.l),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date.toUpperCase(), style: text.labelSmall?.copyWith(letterSpacing: 0.6)),
                const SizedBox(height: Space.xs),
                Text(greeting, style: text.displaySmall),
              ],
            ),
          ),
          if (total > 0)
            Semantics(
              label: l10n.progressDone(done, total),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: done / total,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      color: c.success,
                      backgroundColor: c.separator,
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

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.count, required this.danger});
  final String title;
  final int count;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l + Space.xs, Space.l, Space.l, Space.s),
      child: Row(
        children: [
          Text(title, style: text.titleMedium?.copyWith(color: danger ? c.danger : null)),
          const SizedBox(width: Space.s),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: (danger ? c.danger : c.textSecondary).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Radii.chip),
            ),
            child: Text('$count', style: text.labelSmall?.copyWith(color: danger ? c.danger : null)),
          ),
        ],
      ),
    );
  }
}

/// Inset grouped list (rounded card, hairline separators).
class _Group extends StatelessWidget {
  const _Group({required this.items});
  final List<ScheduleItem> items;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.row),
        child: Material(
          color: c.surface,
          child: Column(
            children: [
              for (var n = 0; n < items.length; n++) ...[
                if (n > 0) const Divider(indent: 64),
                _Row(item: items[n]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.item});
  final ScheduleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final r = item.reminder;
    final color = c.kind(r.kind);

    final dated = r.timing.type == TimingType.date;
    final time = dated ? l10n.allDay : DateFormat.jm(locale).format(item.start);
    final showDate = item.group != ScheduleGroup.today && item.group != ScheduleGroup.tomorrow;
    final when = showDate ? '${DateFormat.MMMEd(locale).format(item.start)} · $time' : time;

    final row = InkWell(
      onTap: () {}, // S-30 reminder detail — next step
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.m),
        child: Row(
          children: [
            // Icon tile tinted in the type color (DS11)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Radii.row - 2),
              ),
              child: Icon(kindIcon(r.kind), color: color, size: 22),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title, style: text.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          when,
                          style: text.bodyMedium?.copyWith(color: item.overdue ? c.danger : null),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (r.rrule != null) ...[
                        const SizedBox(width: Space.xs),
                        Icon(Icons.repeat_rounded, size: 14, color: c.textSecondary),
                      ],
                      if (r.context == ReminderContext.work) ...[
                        const SizedBox(width: Space.xs),
                        Icon(Icons.work_outline_rounded, size: 14, color: c.textSecondary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!r.completable) return row;
    return Dismissible(
      key: ValueKey(item.occurrenceId),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: c.success,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: Space.xxl),
        child: const Icon(Icons.check_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _done(context, ref),
      child: row,
    );
  }

  Future<void> _done(BuildContext context, WidgetRef ref) async {
    final service = ref.read(servicesProvider).service;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await service.act(item.reminder.id, item.occurrenceKey, JournalActionType.done);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.snackDone),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: l10n.actionUndo,
            onPressed: () => service.act(item.reminder.id, item.occurrenceKey, JournalActionType.undo),
          ),
        ),
      );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.sub, this.compact = false});
  final String title, sub;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Space.xxxl, vertical: compact ? Space.l : Space.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for the bell mascot (Rive, DS8/DS9)
          Icon(Icons.notifications_none_rounded, size: compact ? 36 : 72, color: c.accent.withValues(alpha: 0.7)),
          const SizedBox(height: Space.m),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: Space.xs),
          Text(sub, style: text.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
