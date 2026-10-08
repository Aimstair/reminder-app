/// "All clear" full screen (DS12) — built to mockup `docs/design/mockups/10-all-clear.png`: green
/// header with rays and the bell, factual stats (DS10: completed · on time · missed alerts), today in
/// review, coming up, Plan tomorrow. Shown when the last of today's tasks is done.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/bell.dart';
import '../../ui/format.dart';
import '../../ui/icons.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../actions/occurrence_actions.dart';

Future<void> showAllClear(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const AllClearPage()));

class AllClearPage extends ConsumerWidget {
  const AllClearPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(prefsProvider);
    final zone = prefs.deviceTimeZone;
    final today = ref.watch(todayProvider);
    final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();
    final saved = ref.watch(occurrencesProvider).value ?? const <String, Occurrence>{};
    final byId = {
      for (final r in [...?ref.watch(allRemindersProvider).value, ...?ref.watch(calendarRemindersProvider).value])
        r.id: r,
    };

    // Today in review: occurrences completed today, with how late each was (day granularity).
    final done = [
      for (final o in saved.values)
        if (o.state == OccurrenceState.done &&
            o.resolvedAt != null &&
            dateOnly(instantToWall(o.resolvedAt!, zone)) == today)
          if (byId[o.reminderId] case final r?)
            (reminder: r, occ: o, times: OccurrenceTimes.of(r, o.overrideStart ?? o.occurrenceKey, prefs)),
    ]..sort((a, b) => a.occ.resolvedAt!.compareTo(b.occ.resolvedAt!));
    final onTime = done.where((d) => !d.occ.resolvedAt!.isAfter(d.times.due)).length;
    final missed = ref.watch(missedCountProvider).value ?? 0;

    final schedule = ref.watch(scheduleProvider) ?? const <ScheduleItem>[];
    final tomorrow = schedule.where((i) => i.group == ScheduleGroup.tomorrow).toList();
    final occasion = schedule
        .where((i) => i.reminder.kind == Kind.occasion && !i.overdue && i.start.difference(today).inDays <= 14)
        .firstOrNull;
    final planner = AlarmPlanner(prefs: prefs, text: (_) => (title: '', body: ''));
    final nextNudge = occasion?.reminder.alertPlan
        .map((s) => planner.fireTime(occasion.reminder, occasion.times, s))
        .where((t) => t.isAfter(now))
        .fold<DateTime?>(null, (a, t) => a == null || t.isBefore(a) ? t : a);

    final green = c.success;
    final deepGreen = Color.lerp(green, dark ? Colors.white : Colors.black, 0.45)!;

    return Scaffold(
      backgroundColor: c.bgGrouped,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Green header with rays and the bell (mockup 10).
                ClipRect(
                  child: Container(
                    color: Color.alphaBlend(green.withValues(alpha: dark ? 0.2 : 0.16), c.surface),
                    padding: const EdgeInsets.only(bottom: Space.xxxl + Space.l),
                    child: SafeArea(
                      bottom: false,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _Rays(color: green.withValues(alpha: 0.18))),
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(foregroundColor: deepGreen),
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(AppIcons.previous, size: 20),
                                    label: Text(l10n.groupToday, style: text.titleMedium?.copyWith(color: deepGreen)),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: MaterialLocalizations.of(context).shareButtonLabel,
                                    color: deepGreen,
                                    icon: const Icon(AppIcons.share),
                                    onPressed: () =>
                                        ref.read(servicesProvider).platform?.shareText(l10n.allClearShare(done.length)),
                                  ),
                                ],
                              ),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: const Bell(size: 120, mood: BellMood.party),
                                  ),
                                  Positioned(
                                    right: 2,
                                    bottom: 6,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: green,
                                        borderRadius: BorderRadius.circular(Radii.row),
                                        border: Border.all(color: c.surface, width: 3),
                                      ),
                                      child: const Icon(AppIcons.check, color: Colors.white, size: 22),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Space.m),
                              Text(l10n.allClearTitle, style: text.displaySmall?.copyWith(color: deepGreen)),
                              const SizedBox(height: Space.xs),
                              Text(
                                l10n.allClearSubDay(f.weekdayLong(today)),
                                style: text.titleMedium?.copyWith(color: deepGreen, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -Space.xxxl),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.l),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Stat(value: '${done.length}', label: l10n.statCompleted, color: green),
                        ),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: _Stat(
                            value: '$onTime',
                            suffix: '/${done.length}',
                            label: l10n.statOnTime,
                            color: c.accent,
                          ),
                        ),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: _Stat(
                            value: '$missed',
                            label: l10n.statMissedAlerts,
                            color: missed > 0 ? c.danger : c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (done.isNotEmpty)
            SliverToBoxAdapter(
              child: _Card(
                title: l10n.todayInReview,
                trailing: l10n.sectionDoneCount(done.length),
                children: [
                  for (final (i, d) in done.indexed) ...[
                    if (i > 0) Divider(height: 1, color: c.separator.withValues(alpha: 0.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.s),
                      child: Row(
                        children: [
                          CheckCircle(color: c.kind(d.reminder.kind), checked: true),
                          const SizedBox(width: Space.m),
                          Expanded(
                            child: Text(
                              d.reminder.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyLarge?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          () {
                            final late = today.difference(dateOnly(instantToWall(d.times.due, zone))).inDays;
                            return late > 0 && d.occ.resolvedAt!.isAfter(d.times.due)
                                ? Text(l10n.lateBy(late), style: text.bodyMedium?.copyWith(color: c.danger))
                                : Text(f.time(instantToWall(d.occ.resolvedAt!, zone)), style: text.bodyMedium);
                          }(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (tomorrow.isNotEmpty || occasion != null)
            SliverToBoxAdapter(
              child: _Card(
                title: l10n.digestComingUp,
                children: [
                  if (tomorrow.isNotEmpty)
                    _ComingRow(
                      tile: IconTile(icon: AppIcons.day, color: c.accent),
                      title: l10n.tomorrowCount(tomorrow.length),
                      sub: tomorrow
                          .take(3)
                          .map(
                            (i) => i.reminder.timing.type == TimingType.date
                                ? i.reminder.title
                                : '${i.reminder.title} ${f.time(i.start)}',
                          )
                          .join(' · '),
                    ),
                  if (occasion != null)
                    _ComingRow(
                      tile: IconTile(icon: AppIcons.gift, color: c.occasion),
                      title: l10n.occasionInDays(
                        occasion.reminder.title,
                        l10n.relDays(occasion.start.difference(today).inDays),
                      ),
                      sub: [
                        if (nextNudge != null) l10n.nextNudgeOn(f.date(instantToWall(nextNudge, zone), today: today)),
                        if (occasion.state != OccurrenceState.prepared) l10n.notPreparedYet,
                      ].join(' · '),
                      action:
                          occasion.state == OccurrenceState.prepared ||
                              !occasion.reminder.alertPlan.any((s) => s.offset.amount < 0)
                          ? null
                          : ActionChip(
                              label: Text(l10n.statePrepared),
                              labelStyle: text.labelLarge?.copyWith(color: c.occasion, fontWeight: FontWeight.w600),
                              backgroundColor: c.occasion.withValues(alpha: 0.12),
                              side: BorderSide.none,
                              shape: const StadiumBorder(),
                              onPressed: () =>
                                  OccurrenceActions(context, ref).prepared(occasion.reminder, occasion.occurrenceKey),
                            ),
                    ),
                ],
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxxl)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.m),
          child: SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card + 4)),
                textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                Navigator.pop(context);
                ref.read(homeProvider.notifier).openDay(addDays(today, 1));
              },
              child: Text(l10n.actionPlanTomorrow),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color, this.suffix});
  final String value;
  final String? suffix;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      height: 92,
      padding: const EdgeInsets.all(Space.m),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card + 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              text: value,
              style: text.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w700),
              children: [
                if (suffix != null)
                  TextSpan(
                    text: suffix,
                    style: text.titleMedium?.copyWith(color: c.textSecondary),
                  ),
              ],
            ),
          ),
          Text(label, style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children, this.trailing});
  final String title;
  final String? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
      child: Container(
        padding: const EdgeInsets.all(Space.l),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card + 4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(title.toUpperCase(), style: text.labelLarge?.copyWith(color: c.textSecondary, letterSpacing: 0.6)),
                const Spacer(),
                if (trailing != null) Text(trailing!, style: text.bodyMedium),
              ],
            ),
            const SizedBox(height: Space.s),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ComingRow extends StatelessWidget {
  const _ComingRow({required this.tile, required this.title, required this.sub, this.action});
  final Widget tile;
  final String title;
  final String sub;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s),
      child: Row(
        children: [
          tile,
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                if (sub.isNotEmpty) Text(sub, style: text.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Soft sun rays behind the bell (mockup 10).
class _Rays extends CustomPainter {
  _Rays({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6 + math.pi / 12;
      final from = center + Offset(math.cos(a), math.sin(a)) * 110;
      final to = center + Offset(math.cos(a), math.sin(a)) * 420;
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(_Rays old) => old.color != color;
}
