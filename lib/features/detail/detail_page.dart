/// S-30 Reminder detail and S-31 Calendar event detail (+ S-32 Remind me) — built to mockup
/// `docs/design/mockups/04-occasion-detail.png` (DS11): pastel banner in the type color with back
/// link, Edit, chips, title + date line and the item's art; three stat cards overlapping it; a
/// Nudges timeline (Sent · Next · Day-of); notes; source card; big type-colored action at the bottom.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/home_shell.dart' show HomeShell;
import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/art.dart';
import '../../ui/format.dart';
import '../../ui/icons.dart';
import '../../ui/motion.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../actions/occurrence_actions.dart';
import '../attachments/attachments.dart';
import '../editor/editor_page.dart';
import '../pickers/pickers.dart' show pickAlerts;

/// One occurrence of one reminder, resolved for display.
class DetailData {
  const DetailData({
    required this.reminder,
    required this.key,
    this.occurrence,
    required this.times,
    required this.doneKeys,
  });
  final Reminder reminder;
  final DateTime key;
  final Occurrence? occurrence;
  final OccurrenceTimes times;

  /// Occurrence keys of this reminder that were completed (history card, DS13).
  final List<DateTime> doneKeys;

  OccurrenceState get state => occurrence?.state ?? OccurrenceState.pending;
}

final detailProvider = Provider.family<DetailData?, ({String id, DateTime key})>((ref, a) {
  final all = [...?ref.watch(allRemindersProvider).value, ...?ref.watch(calendarRemindersProvider).value];
  final r = all.where((x) => x.id == a.id).firstOrNull;
  if (r == null) return null;
  final saved = ref.watch(occurrencesProvider).value ?? const <String, Occurrence>{};
  final occ = saved[AlarmPlanner.occurrenceId(r.id, a.key)];
  final prefs = ref.watch(prefsProvider);
  final times = OccurrenceTimes.of(r, occ?.overrideStart ?? a.key, prefs, overrideEnd: occ?.overrideEnd);
  final doneKeys = [
    for (final o in saved.values)
      if (o.reminderId == r.id && o.state == OccurrenceState.done) o.occurrenceKey,
  ]..sort((x, y) => y.compareTo(x));
  return DetailData(reminder: r, key: a.key, occurrence: occ, times: times, doneKeys: doneKeys);
});

class DetailPage extends ConsumerWidget {
  const DetailPage({super.key, required this.reminderId, required this.occurrenceKey});
  final String reminderId;
  final DateTime occurrenceKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(detailProvider((id: reminderId, key: occurrenceKey)));
    final l10n = AppLocalizations.of(context);
    if (d == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(title: l10n.errGeneric),
      );
    }
    final r = d.reminder;
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final prefs = ref.watch(prefsProvider);
    final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();
    final today = ref.watch(todayProvider);
    final device = prefs.deviceTimeZone;
    final allDay = r.timing.type == TimingType.date;
    final startLocal = allDay ? dateOnly(d.times.start) : instantToWall(d.times.anchor, device);
    final overdue = d.times.isOverdue(r, d.state, now);
    final state = d.times.shouldPass(r, d.state, now) ? OccurrenceState.passed : d.state;
    final resolved = state.isResolved;
    final zone = r.timing.timeZone;
    final otherZone = !allDay && zone != null && zone != device;
    final plan = d.occurrence?.overrideAlertPlan ?? r.alertPlan;

    // Stat cards: time to go · nudges sent · history (DS13) or status.
    final planner = AlarmPlanner(prefs: prefs, text: (_) => (title: '', body: ''));
    final fires = [for (final s in plan) (stage: s, at: planner.fireTime(r, d.times, s))]
      ..sort((a, b) => a.at.compareTo(b.at));
    final sent = fires.where((x) => !x.at.isAfter(now)).length;
    final days = dateOnly(startLocal).difference(today).inDays;
    final yearly = (r.rrule ?? '').contains('FREQ=YEARLY');
    final doneCount = d.doneKeys.length;

    return Scaffold(
      backgroundColor: c.bgGrouped,
      body: CustomScrollView(
        slivers: [
          // Banner and stat cards in one box so the cards paint over the banner's bottom edge.
          SliverToBoxAdapter(
            child: Column(
              children: [
                _Banner(data: d, startLocal: startLocal, allDay: allDay),
                Transform.translate(
                  offset: const Offset(0, -Space.xxxl),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.l),
                    child: Row(
                      children: [
                        Expanded(
                          child: days > 0 && !resolved
                              ? _StatCard(value: '$days', label: l10n.statDaysToGo(days), color: c.kind(r.kind))
                              : overdue && days < 0
                              ? _StatCard(value: '${-days}', label: l10n.statDaysLate(-days), color: c.danger)
                              : _StatCard(
                                  value: allDay ? l10n.groupToday : f.time(startLocal),
                                  label: allDay ? l10n.allDay.toLowerCase() : l10n.groupToday.toLowerCase(),
                                  color: c.kind(r.kind),
                                  small: true,
                                ),
                        ),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: r.kind == Kind.bill && r.amount != null
                              ? _StatCard(value: f.money(r.amount!), label: l10n.statAmount, color: c.bill, small: true)
                              : _StatCard(value: '$sent', suffix: '/${fires.length}', label: l10n.statNudgesSent),
                        ),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: r.repeats
                              ? _StatCard(
                                  value: '$doneCount',
                                  label: yearly ? l10n.statYearsDone(doneCount) : l10n.statTimesDone(doneCount),
                                  color: c.success,
                                )
                              : _StatCard(
                                  value: f.state(state, overdue: overdue),
                                  label: l10n.statStatus,
                                  color: overdue ? c.danger : (resolved ? c.success : null),
                                  small: true,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_duplicate(ref, r, d) case final dup?)
            SliverToBoxAdapter(
              child: _DuplicateBanner(reminder: r, event: dup),
            ),
          SliverToBoxAdapter(
            child: _NudgesCard(
              reminder: r,
              fires: fires,
              now: now,
              allDay: allDay,
              prepared: state == OccurrenceState.prepared,
              onChange: r.isCalendarEvent
                  ? () => remindMeFlow(context, ref, r)
                  : (resolved ? null : () => _changeAlerts(context, ref, r, plan)),
            ),
          ),
          if (otherZone)
            SliverToBoxAdapter(
              child: _InfoCard(
                icon: AppIcons.timeZone,
                text: l10n.zoneNote(f.time(d.occurrence?.overrideStart ?? d.key), Fmt.city(zone)), // TIM-6
              ),
            ),
          if ((r.notes ?? '').isNotEmpty)
            SliverToBoxAdapter(
              child: _InfoCard(icon: AppIcons.notes, text: r.notes!, links: true), // ATT-5
            ),
          if (r.attachments.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
                child: AttachmentList(attachments: r.attachments), // ATT-4
              ),
            ),
          if (r.source is ContactSource)
            SliverToBoxAdapter(
              child: _ContactCard(reminder: r, doneKeys: d.doneKeys),
            )
          else if (r.isCalendarEvent)
            SliverToBoxAdapter(
              child: _InfoCard(
                icon: AppIcons.calendar,
                text: l10n.detailFromCalendar(ref.read(servicesProvider).calendar.calendarFor(r)?.name ?? ''),
              ),
            ),
          if (r.isCalendarEvent) ...[
            SliverToBoxAdapter(child: GroupCaption(l10n.fieldType)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.l),
                child: SegmentedPills<Kind>(
                  items: [
                    for (final k in Kind.values)
                      if (k != Kind.bill) (value: k, label: f.kind(k), dot: c.kind(k)),
                  ],
                  selected: r.kind,
                  onChanged: (k) => ref.read(servicesProvider).calendar.correct(r, kind: k), // CAL-5
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxxl)),
        ],
      ),
      bottomNavigationBar: _Actions(data: d, state: state, overdue: overdue),
    );
  }

  /// Change the alert plan from the Nudges card (S-21g); repeating items keep it for the series.
  static Future<void> _changeAlerts(BuildContext context, WidgetRef ref, Reminder r, List<AlertStage> plan) async {
    final v = await pickAlerts(context, plan);
    if (v == null) return;
    await ref.read(servicesProvider).service.edit(r.copyWith(alertPlan: v));
  }

  /// CAL-9: manual reminder that looks like an imported event.
  CalendarEvent? _duplicate(WidgetRef ref, Reminder r, DetailData d) {
    if (r.isCalendarEvent) return null;
    final s = ref.read(servicesProvider);
    if (s.prefs.stringSet('dup_kept').contains(r.id)) return null;
    return findDuplicate(r, d.times.anchor, s.calendar.events);
  }
}

/// S-32 + S-34: add alerts to an imported event (CAL-6), asking the scope for a series.
Future<void> remindMeFlow(BuildContext context, WidgetRef ref, Reminder r) async {
  final plan = await showRemindMe(context, r.alertPlan);
  if (plan == null || !context.mounted) return;
  var series = false;
  final event = ref.read(servicesProvider).calendar.eventFor(r);
  if (event?.recurring ?? false) {
    final l10n = AppLocalizations.of(context);
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.scopeRemindTitle),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.scopeThisEvent)),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.scopeAllEvents)),
        ],
      ),
    );
    if (choice == null) return;
    series = choice;
  }
  final s = ref.read(servicesProvider);
  await s.calendar.remindMe(r, plan, series: series);
  await s.service.resync();
}

/// Pastel header (mockup 04): back link · Edit, type/context chips, title, date line, the item's art.
class _Banner extends ConsumerWidget {
  const _Banner({required this.data, required this.startLocal, required this.allDay});
  final DetailData data;
  final DateTime startLocal;
  final bool allDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = data.reminder;
    final color = c.kind(r.kind);
    final deep = Color.lerp(color, dark ? Colors.white : Colors.black, 0.3)!;
    final resolved = data.state.isResolved;
    final actions = OccurrenceActions(context, ref);
    final when = allDay ? f.date(startLocal) : '${f.date(startLocal)} · ${f.time(startLocal)}';
    final line = r.rrule == null ? when : '$when · ${f.repeat(r.rrule, r.repeatMode)}';
    final art = r.kind == Kind.occasion ? AppIcons.giftSolid : glyphIcon(glyphFor(r));
    final top = MediaQuery.paddingOf(context).top;
    // The whole tinted area (status bar included) clips the decoration, so the circle is cut only by
    // the banner's own edges.
    return ClipRect(
      child: Container(
        color: Color.alphaBlend(color.withValues(alpha: dark ? 0.24 : 0.14), c.surface),
        padding: const EdgeInsets.only(bottom: Space.xxxl + Space.l),
        child: Stack(
          clipBehavior: Clip.none, // the outer ClipRect cuts the circle at the banner edges
          children: [
            // Soft circle with the item's art centered in it, on the right.
            Positioned(
              right: -36,
              top: top + 36,
              child: Container(
                width: 188,
                height: 188,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Floating(child: Icon(art, size: 84, color: color)),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: deep),
                        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                        icon: const Icon(AppIcons.previous, size: 20),
                        label: Text(
                          HomeShell.viewName(l10n, ref.read(homeProvider).view),
                          style: text.titleMedium?.copyWith(color: deep),
                        ),
                      ),
                      const Spacer(),
                      if (!r.isCalendarEvent && !resolved)
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: deep),
                          onPressed: () => openEditor(context, ref, r, data.key),
                          child: Text(l10n.actionEdit, style: text.titleMedium?.copyWith(color: deep)),
                        ),
                      if (!r.isCalendarEvent)
                        IconButton(
                          tooltip: l10n.actionDelete,
                          color: deep,
                          icon: const Icon(AppIcons.delete),
                          onPressed: () async {
                            // Router captured first: the page rebuilds without this button once
                            // the reminder is gone, so [context] is unmounted after the await.
                            final router = GoRouter.of(context);
                            if (await actions.delete(r, data.key)) {
                              router.canPop() ? router.pop() : router.go('/');
                            }
                          },
                        ),
                      const SizedBox(width: Space.xs),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.l, Space.l, 140, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: Space.s,
                          children: [
                            _Chip(text: f.typeOf(r).toUpperCase(), color: deep), // SUB-1
                            _Chip(text: f.context(r.context).toUpperCase(), color: c.textSecondary),
                          ],
                        ),
                        const SizedBox(height: Space.m),
                        Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.headlineLarge),
                        const SizedBox(height: Space.xs),
                        Text(
                          line,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLarge?.copyWith(color: deep),
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
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: AppColors.of(context).surface, borderRadius: BorderRadius.circular(Radii.chip)),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: 0.4),
    ),
  );
}

/// Overlapping stat card (mockup 04): big number (optionally "/n"), small label.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, this.suffix, this.color, this.small = false});
  final String value;
  final String? suffix;
  final String label;
  final Color? color;

  /// Words instead of a number ("Today", "Overdue") — a smaller size so they fit.
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    // One value size for all three cards so they line up; long words shrink to fit.
    final big = text.headlineMedium?.copyWith(color: color ?? c.textPrimary, fontSize: small ? 20 : 24);
    return Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(Space.m + 2, Space.m, Space.m, Space.m),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card + 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: value,
                style: big,
                children: [
                  if (suffix != null)
                    TextSpan(
                      text: suffix,
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              maxLines: 1,
            ),
          ),
          Text(label, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Nudges timeline (mockup 04): one row per alert stage — dot + line, "1 week before", its date,
/// a badge (Sent · Next · Day-of); nag line when on; "Change" opens the alert picker.
class _NudgesCard extends StatelessWidget {
  const _NudgesCard({
    required this.reminder,
    required this.fires,
    required this.now,
    required this.allDay,
    required this.prepared,
    this.onChange,
  });
  final Reminder reminder;
  final List<({AlertStage stage, DateTime at})> fires;
  final DateTime now;
  final bool allDay;
  final bool prepared;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final color = c.kind(reminder.kind);
    final zone = ProviderScope.containerOf(context, listen: false).read(prefsProvider).deviceTimeZone;
    final nextIndex = fires.indexWhere((x) => x.at.isAfter(now));
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.nudgesTitle.toUpperCase(),
                style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              const Spacer(),
              if (onChange != null)
                TextButton(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                  onPressed: onChange,
                  child: Text(l10n.actionChange, style: text.titleSmall?.copyWith(color: c.accent)),
                ),
            ],
          ),
          if (fires.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.s),
              child: Text(l10n.alertNone, style: text.bodyMedium),
            ),
          for (var i = 0; i < fires.length; i++)
            _NudgeRow(
              title: () {
                final s = f.offset(fires[i].stage.offset, allDay: allDay);
                return s[0].toUpperCase() + s.substring(1);
              }(),
              sub: [
                f.when(instantToWall(fires[i].at, zone), allDay: false),
                if (reminder.kind == Kind.occasion && fires[i].stage.offset.amount == 0)
                  l10n.ringsEvenIfPrepared, // OCC-3
              ].join(' · '),
              badge: !fires[i].at.isAfter(now)
                  ? (l10n.badgeSent, c.success)
                  : i == nextIndex && !(prepared && fires[i].stage.isPrep)
                  ? (l10n.badgeNext, color)
                  : reminder.kind == Kind.occasion && fires[i].stage.offset.amount == 0
                  ? (l10n.badgeDayOf, c.textSecondary)
                  : null,
              sentDot: !fires[i].at.isAfter(now),
              nextDot: i == nextIndex,
              color: color,
              first: i == 0,
              last: i == fires.length - 1,
            ),
          if (reminder.nagInterval != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.s),
              child: Text(l10n.nagThen(f.duration(reminder.nagInterval!)), style: text.bodyMedium), // ALR-9
            ),
        ],
      ),
    );
  }
}

class _NudgeRow extends StatelessWidget {
  const _NudgeRow({
    required this.title,
    required this.sub,
    required this.badge,
    required this.sentDot,
    required this.nextDot,
    required this.color,
    required this.first,
    required this.last,
  });
  final String title;
  final String sub;
  final (String, Color)? badge;
  final bool sentDot;
  final bool nextDot;
  final Color color;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final dot = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: sentDot ? color : Colors.transparent,
        border: Border.all(color: sentDot || nextDot ? color : c.separator, width: 2.5),
      ),
      child: sentDot ? const Icon(AppIcons.check, size: 14, color: Colors.white) : null,
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: Space.m,
                  color: first ? Colors.transparent : (sentDot ? color : c.separator),
                ),
                dot,
                Expanded(
                  child: Container(width: 2, color: last ? Colors.transparent : (sentDot ? color : c.separator)),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.m),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: Space.s, bottom: Space.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  Text(sub, style: text.bodyMedium),
                ],
              ),
            ),
          ),
          if (badge case (final label, final bc))
            Padding(
              padding: const EdgeInsets.only(top: Space.s + 2, left: Space.s),
              child: Align(
                alignment: Alignment.topRight,
                child: MiniChip(label, color: bc),
              ),
            ),
        ],
      ),
    );
  }
}

/// White rounded card with page margins (mockup 04).
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
    child: Container(
      padding: const EdgeInsets.all(Space.l),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(Radii.card + 4),
      ),
      child: child,
    ),
  );
}

/// Icon + text card (notes, time zone note, calendar source).
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text, this.links = false});
  final IconData icon;
  final String text;

  /// Notes: selectable, with tappable web links (ATT-5).
  final bool links;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final style = Theme.of(context).textTheme.bodyLarge;
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c.textSecondary),
          const SizedBox(width: Space.m),
          Expanded(
            child: links ? LinkifiedText(text, style: style) : Text(text, style: style),
          ),
        ],
      ),
    );
  }
}

/// "From Contacts" card (mockup 04): initial avatar, history of completed years; CON-6 when the
/// contact is gone.
class _ContactCard extends ConsumerWidget {
  const _ContactCard({required this.reminder, required this.doneKeys});
  final Reminder reminder;
  final List<DateTime> doneKeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final source = reminder.source as ContactSource;
    final years = {for (final k in doneKeys) k.year}.toList();
    final initial = reminder.title.trim().isEmpty ? '?' : reminder.title.trim()[0].toUpperCase();
    return FutureBuilder<bool>(
      future: ref.read(servicesProvider).contacts.contactExists(source.contactId),
      builder: (context, snap) => _Card(
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: c.event.withValues(alpha: 0.3),
              child: Text(initial, style: text.titleMedium?.copyWith(color: Color.lerp(c.event, Colors.black, 0.45))),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.fromContacts, style: text.titleMedium),
                  if (!(snap.data ?? true))
                    Text(l10n.contactRemoved, style: text.bodyMedium) // CON-6
                  else if (years.isNotEmpty)
                    Text(l10n.historyDoneIn(years.join(', ')), style: text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CAL-9 banner: Merge / Keep both. Merge = the reminder's alerts become an overlay on the event,
/// then the manual reminder is deleted. Never automatic.
class _DuplicateBanner extends ConsumerWidget {
  const _DuplicateBanner({required this.reminder, required this.event});
  final Reminder reminder;
  final CalendarEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.read(servicesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
      child: Material(
        color: AppColors.of(context).accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.row),
        child: Padding(
          padding: const EdgeInsets.all(Space.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.dupBanner),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => s.prefs.set('dup_kept', [...s.prefs.stringSet('dup_kept'), reminder.id]),
                    child: Text(l10n.actionKeepBoth),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      final router = GoRouter.of(context); // deleting unmounts this banner
                      final ev = reminderFromEvent(event, overlays: const [], deviceId: '');
                      await s.calendar.remindMe(ev, reminder.alertPlan, series: false);
                      await s.service.delete(reminder.id);
                      router.canPop() ? router.pop() : router.go('/');
                    },
                    child: Text(l10n.actionMerge),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom actions (mockup 04): one big type-colored button — I'm prepared (occasion with prep),
/// Done, Remind me (calendar) or Mark as not done — then Reschedule · Skip / Skip this year.
class _Actions extends ConsumerWidget {
  const _Actions({required this.data, required this.state, required this.overdue});
  final DetailData data;
  final OccurrenceState state;
  final bool overdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final r = data.reminder;
    final color = c.kind(r.kind);
    final a = OccurrenceActions(context, ref);
    final open = state == OccurrenceState.pending || state == OccurrenceState.snoozed;
    final hasPrep = r.alertPlan.any((s) => s.offset.amount < 0);
    final yearly = (r.rrule ?? '').contains('FREQ=YEARLY');

    Widget primary(String label, IconData? icon, VoidCallback onTap, {Color? bg}) => SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: bg ?? color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
          textStyle: text.titleMedium,
        ),
        onPressed: onTap,
        icon: icon == null ? null : Icon(icon),
        label: Text(label),
      ),
    );
    Widget secondary(String label, Color fg, VoidCallback onTap) => Expanded(
      child: SizedBox(
        height: 50,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: c.surface,
            foregroundColor: fg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
            textStyle: text.titleMedium,
          ),
          onPressed: onTap,
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );

    final children = <Widget>[];
    if (r.isCalendarEvent) {
      children.add(primary(l10n.actionRemindMe, AppIcons.alerts, () => remindMeFlow(context, ref, r)));
    } else if (state == OccurrenceState.done || state == OccurrenceState.skipped) {
      children.add(
        primary(
          l10n.actionMarkNotDone, // OCC-5
          AppIcons.undo,
          () => ref.read(servicesProvider).service.setState(r.id, data.key, OccurrenceState.pending),
          bg: c.textSecondary,
        ),
      );
    } else if (state != OccurrenceState.passed) {
      final trial = r.kind == Kind.bill && r.billKind == BillKind.trial;
      final subscription = r.kind == Kind.bill && r.billKind == BillKind.subscription;
      if (trial) {
        // BIL-5: decide before the trial ends.
        final f = Fmt.of(context);
        final when = f.date(data.key);
        children.add(
          Text(
            r.amount == null ? l10n.trialDecide(when) : l10n.trialDecideAmount(when, f.money(r.amount!)),
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
        );
        children.add(
          primary(l10n.actionKeepIt, AppIcons.renewal, () async {
            final yearly = await _askCadence(context);
            if (yearly == null) return;
            await a.keepTrial(r, data.key, yearly: yearly);
            if (context.mounted && context.canPop()) context.pop();
          }),
        );
      } else if (r.kind == Kind.occasion && open && hasPrep) {
        children.add(primary(l10n.actionPrepared, AppIcons.check, () => a.prepared(r, data.key))); // OCC-3
      } else if (r.kind == Kind.bill) {
        // BIL-1: Paid / Got it.
        children.add(
          primary(subscription ? l10n.actionGotIt : l10n.actionPaid, AppIcons.check, () async {
            await a.done(r, data.key);
            if (context.mounted && context.canPop()) context.pop();
          }),
        );
      } else if (r.completable) {
        children.add(
          primary(l10n.actionDone, AppIcons.check, () async {
            await a.done(r, data.key);
            if (context.mounted && context.canPop()) context.pop();
          }),
        );
      }
      children.add(
        Row(
          children: [
            secondary(
              l10n.actionReschedule,
              c.accent,
              () => a.reschedule(r, data.key, currentStart: data.occurrence?.overrideStart),
            ),
            if (trial || subscription) ...[
              const SizedBox(width: Space.m),
              secondary(trial ? l10n.actionCancelledTrial : l10n.actionStopSubscription, c.danger, () async {
                trial ? await a.cancelTrial(r, data.key) : await a.stopSubscription(r, data.key);
                if (context.mounted && context.canPop()) context.pop();
              }),
            ] else if (r.completable || r.repeats) ...[
              const SizedBox(width: Space.m),
              secondary(yearly ? l10n.actionSkipYear : l10n.actionSkip, c.textPrimary, () async {
                await a.skip(r, data.key);
                if (context.mounted && context.canPop()) context.pop();
              }),
            ],
          ],
        ),
      );
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: Space.m), children[i]],
          ],
        ),
      ),
    );
  }
}

/// BIL-5 "How often will it charge?" → true = yearly, false = monthly, null = cancelled.
Future<bool?> _askCadence(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final c = AppColors.of(context);
  return showAppSheet<bool>(
    context,
    (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.trialKeepTitle, style: Theme.of(ctx).textTheme.titleMedium),
        const SizedBox(height: Space.m),
        InsetGroup(
          indent: 56,
          color: c.bgGrouped,
          children: [
            ChoiceRow(
              icon: AppIcons.calendarCheck,
              color: c.success,
              label: l10n.repeatMonthly,
              selected: false,
              onTap: () => Navigator.pop(ctx, false),
            ),
            ChoiceRow(
              icon: AppIcons.star,
              color: c.occasion,
              label: l10n.repeatYearly,
              selected: false,
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
      ],
    ),
  );
}

/// S-32 Remind me picker: presets (multi-select) + custom.
Future<List<AlertStage>?> showRemindMe(BuildContext context, List<AlertStage> current) {
  return showAppSheet<List<AlertStage>>(context, (ctx) => _RemindMeSheet(initial: current));
}

class _RemindMeSheet extends StatefulWidget {
  const _RemindMeSheet({required this.initial});
  final List<AlertStage> initial;

  @override
  State<_RemindMeSheet> createState() => _RemindMeSheetState();
}

class _RemindMeSheetState extends State<_RemindMeSheet> {
  static const _presets = [
    AlertOffset(-10, OffsetUnit.minutes),
    AlertOffset(-1, OffsetUnit.hours),
    AlertOffset(-1, OffsetUnit.days),
  ];
  late final Set<String> _chosen = {for (final s in widget.initial) s.offset.toString()};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = Fmt.of(context);
    final c = AppColors.of(context);
    final labels = [l10n.remind10m, l10n.remind1h, l10n.remind1d];
    final custom = _chosen.where((o) => !_presets.any((p) => p.toString() == o)).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetBar(
          title: l10n.actionRemindMe,
          left: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
          right: TextButton(
            onPressed: () => Navigator.pop(
              context,
              [for (final o in _chosen) AlertStage(AlertOffset.parse(o))]
                ..sort((a, b) => _minutes(a.offset).compareTo(_minutes(b.offset))),
            ),
            child: Text(l10n.actionSave),
          ),
        ),
        InsetGroup(
          indent: Space.l,
          color: c.bgGrouped,
          children: [
            for (var i = 0; i < _presets.length; i++)
              CheckboxListTile(
                value: _chosen.contains(_presets[i].toString()),
                title: Text(labels[i]),
                onChanged: (v) => setState(() => v! ? _chosen.add('${_presets[i]}') : _chosen.remove('${_presets[i]}')),
              ),
            for (final o in custom)
              CheckboxListTile(
                value: true,
                title: Text(f.offset(AlertOffset.parse(o))),
                onChanged: (_) => setState(() => _chosen.remove(o)),
              ),
            ListTile(
              title: Text(l10n.remindCustom),
              trailing: const Icon(AppIcons.add),
              onTap: () async {
                final o = await pickOffset(context);
                if (o != null) setState(() => _chosen.add(o.toString()));
              },
            ),
          ],
        ),
        const SizedBox(height: Space.l),
      ],
    );
  }
}

/// Approximate minutes of an offset, for sorting.
int _minutes(AlertOffset o) =>
    o.amount *
    switch (o.unit) {
      OffsetUnit.minutes => 1,
      OffsetUnit.hours => 60,
      OffsetUnit.days => 1440,
      OffsetUnit.weeks => 10080,
      OffsetUnit.months => 43200,
    };

int alertSortKey(AlertStage s) => _minutes(s.offset);

/// Custom alert offset: amount + unit, before or at.
Future<AlertOffset?> pickOffset(BuildContext context) {
  return showAppSheet<AlertOffset>(context, (ctx) => const _OffsetPicker());
}

class _OffsetPicker extends StatefulWidget {
  const _OffsetPicker();

  @override
  State<_OffsetPicker> createState() => _OffsetPickerState();
}

class _OffsetPickerState extends State<_OffsetPicker> {
  int _amount = 1;
  OffsetUnit _unit = OffsetUnit.days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = Fmt.of(context);
    final c = AppColors.of(context);
    final preview = AlertOffset(-_amount, _unit);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetBar(
          title: l10n.remindCustom,
          left: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
          right: TextButton(onPressed: () => Navigator.pop(context, preview), child: Text(l10n.pickerDone)),
        ),
        Text(f.offset(preview), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: c.accent)),
        const SizedBox(height: Space.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: _amount > 1 ? () => setState(() => _amount--) : null,
              icon: const Icon(AppIcons.minus),
            ),
            SizedBox(
              width: 56,
              child: Text('$_amount', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton.filledTonal(
              onPressed: _amount < 99 ? () => setState(() => _amount++) : null,
              icon: const Icon(AppIcons.add),
            ),
          ],
        ),
        const SizedBox(height: Space.m),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.l),
          child: SegmentedButton<OffsetUnit>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: OffsetUnit.minutes,
                label: Text(l10n.relMinutes(_amount).replaceAll('$_amount ', '')),
              ),
              ButtonSegment(value: OffsetUnit.hours, label: Text(l10n.relHours(_amount).replaceAll('$_amount ', ''))),
              ButtonSegment(value: OffsetUnit.days, label: Text(l10n.relDays(_amount).replaceAll('$_amount ', ''))),
              ButtonSegment(value: OffsetUnit.weeks, label: Text(l10n.relWeeks(_amount).replaceAll('$_amount ', ''))),
              ButtonSegment(value: OffsetUnit.months, label: Text(l10n.relMonths(_amount).replaceAll('$_amount ', ''))),
            ],
            selected: {_unit},
            onSelectionChanged: (s) => setState(() => _unit = s.first),
          ),
        ),
        const SizedBox(height: Space.xl),
      ],
    );
  }
}
