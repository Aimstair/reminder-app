/// S-30 Reminder detail and S-31 Calendar event detail (+ S-32 Remind me). Colored banner header in
/// the type color with overlapping stat cards (DS11).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../actions/occurrence_actions.dart';
import '../editor/editor_page.dart';

/// One occurrence of one reminder, resolved for display.
class DetailData {
  const DetailData({required this.reminder, required this.key, this.occurrence, required this.times});
  final Reminder reminder;
  final DateTime key;
  final Occurrence? occurrence;
  final OccurrenceTimes times;

  OccurrenceState get state => occurrence?.state ?? OccurrenceState.pending;
}

final detailProvider = Provider.family<DetailData?, ({String id, DateTime key})>((ref, a) {
  final all = [
    ...?ref.watch(allRemindersProvider).value,
    ...?ref.watch(calendarRemindersProvider).value,
  ];
  final r = all.where((x) => x.id == a.id).firstOrNull;
  if (r == null) return null;
  final occ = ref.watch(occurrencesProvider).value?[AlarmPlanner.occurrenceId(r.id, a.key)];
  final prefs = ref.watch(prefsProvider);
  final times = OccurrenceTimes.of(r, occ?.overrideStart ?? a.key, prefs, overrideEnd: occ?.overrideEnd);
  return DetailData(reminder: r, key: a.key, occurrence: occ, times: times);
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
      return Scaffold(appBar: AppBar(), body: EmptyState(title: l10n.errGeneric));
    }
    final r = d.reminder;
    final c = AppColors.of(context);
    final color = c.kind(r.kind);
    final f = Fmt.of(context);
    final prefs = ref.watch(prefsProvider);
    final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();
    final device = prefs.deviceTimeZone;
    final allDay = r.timing.type == TimingType.date;
    final startLocal = allDay ? dateOnly(d.times.start) : instantToWall(d.times.anchor, device);
    final endLocal = !allDay && d.times.end.isAfter(d.times.anchor) ? instantToWall(d.times.end, device) : null;
    final overdue = d.times.isOverdue(r, d.state, now);
    final state = d.times.shouldPass(r, d.state, now) ? OccurrenceState.passed : d.state;
    final resolved = state.isResolved;
    // A pending snooze says when it rings again, even if the item is already past due (NTF-4).
    final snoozedUntil = state == OccurrenceState.snoozed && (d.occurrence?.snoozedUntil?.isAfter(now) ?? false)
        ? d.occurrence!.snoozedUntil!
        : null;
    final actions = OccurrenceActions(context, ref);
    final zone = r.timing.timeZone;
    final otherZone = !allDay && zone != null && zone != device;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 210,
            backgroundColor: color,
            foregroundColor: Colors.white,
            actions: [
              if (!r.isCalendarEvent && !resolved)
                IconButton(
                  tooltip: l10n.actionEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => openEditor(context, ref, r, d.key),
                ),
              if (!r.isCalendarEvent)
                IconButton(
                  tooltip: l10n.actionDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    if (await actions.delete(r, d.key) && context.mounted) context.pop();
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _Banner(reminder: r, color: color),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -Space.l),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.l),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: l10n.detailWhen,
                        value: allDay ? f.date(startLocal) : '${f.date(startLocal)}\n${f.time(startLocal)}',
                      ),
                    ),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: _StatCard(
                        label: l10n.detailStatus,
                        value: snoozedUntil != null
                            ? l10n.stateSnoozedUntil(f.time(instantToWall(snoozedUntil, device)))
                            : f.state(state, overdue: overdue),
                        color: snoozedUntil != null ? c.warning : (overdue ? c.danger : (resolved ? c.success : null)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_duplicate(ref, r, d) case final dup?)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: Space.s),
                child: _DuplicateBanner(reminder: r, event: dup),
              ),
            ),
          SliverToBoxAdapter(
            child: InsetGroup(
              indent: 56,
              children: [
                FormRow(
                  icon: Icons.schedule_rounded,
                  color: c.accent,
                  label: l10n.detailWhen,
                  value: f.when(startLocal, allDay: allDay, end: endLocal),
                ),
                if (otherZone)
                  FormRow(
                    icon: Icons.public_rounded,
                    color: c.meeting,
                    label: l10n.detailTimeZone,
                    value: l10n.zoneNote(f.time(d.occurrence?.overrideStart ?? d.key), Fmt.city(zone)), // TIM-6
                  ),
                FormRow(
                  icon: Icons.repeat_rounded,
                  color: c.meeting,
                  label: l10n.rowRepeat,
                  value: f.repeat(r.rrule, r.repeatMode),
                ),
                FormRow(
                  icon: Icons.notifications_active_outlined,
                  color: c.warning,
                  label: l10n.rowAlerts,
                  value: f.alerts(d.occurrence?.overrideAlertPlan ?? r.alertPlan),
                  onTap: r.isCalendarEvent ? () => remindMeFlow(context, ref, r) : null,
                ),
                if (r.nagInterval != null)
                  FormRow(
                    icon: Icons.replay_rounded,
                    color: c.success,
                    label: l10n.rowNag,
                    value: l10n.nagEvery(f.duration(r.nagInterval!)),
                  ),
                if (r.isCalendarEvent)
                  FormRow(
                    icon: Icons.calendar_today_outlined,
                    color: c.event,
                    label: l10n.detailFromCalendar(ref.read(servicesProvider).calendar.calendarFor(r)?.name ?? ''),
                  ),
                if (r.source is ContactSource) _ContactRow(source: r.source as ContactSource),
              ],
            ),
          ),
          if ((r.notes ?? '').isNotEmpty) ...[
            SliverToBoxAdapter(child: GroupCaption(l10n.detailNotes)),
            SliverToBoxAdapter(
              child: InsetGroup(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Space.l),
                    child: SelectableText(r.notes!, style: Theme.of(context).textTheme.bodyLarge),
                  ),
                ],
              ),
            ),
          ],
          if (r.isCalendarEvent) ...[
            SliverToBoxAdapter(child: GroupCaption(l10n.fieldType)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.l),
                child: SegmentedButton<Kind>(
                  showSelectedIcon: false,
                  segments: [
                    for (final k in Kind.values) ButtonSegment(value: k, label: Text(f.kind(k))),
                  ],
                  selected: {r.kind},
                  onSelectionChanged: (s) => ref.read(servicesProvider).calendar.correct(r, kind: s.first), // CAL-5
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(child: _Actions(data: d, state: state, overdue: overdue)),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxxl)),
        ],
      ),
    );
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

class _Banner extends StatelessWidget {
  const _Banner({required this.reminder, required this.color});
  final Reminder reminder;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final r = reminder;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.18)!],
        ),
      ),
      child: Stack(
        children: [
          // Large faint glyph as the illustration layer.
          Positioned(
            right: -24,
            bottom: -8,
            child: Icon(kindIcon(r.kind), size: 170, color: Colors.white.withValues(alpha: 0.16)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 56, Space.l, Space.xxxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Wrap(
                    spacing: Space.s,
                    children: [
                      _Chip(text: f.kind(r.kind)),
                      _Chip(text: f.context(r.context)),
                    ],
                  ),
                  const SizedBox(height: Space.s),
                  Text(
                    r.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(color: Colors.white, fontSize: 26),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(Radii.chip),
    ),
    child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Space.m),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: text.labelSmall),
          const SizedBox(height: 2),
          Text(value, style: text.titleMedium?.copyWith(color: color), maxLines: 2),
        ],
      ),
    );
  }
}

class _ContactRow extends ConsumerWidget {
  const _ContactRow({required this.source});
  final ContactSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<bool>(
      future: ref.read(servicesProvider).contacts.contactExists(source.contactId),
      builder: (context, snap) => (snap.data ?? true)
          ? const SizedBox.shrink()
          : FormRow(
              icon: Icons.person_off_outlined,
              color: AppColors.of(context).textSecondary,
              label: l10n.contactRemoved, // CON-6
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
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
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
                      final ev = reminderFromEvent(event, overlays: const [], deviceId: '');
                      await s.calendar.remindMe(ev, reminder.alertPlan, series: false);
                      await s.service.delete(reminder.id);
                      if (context.mounted) context.pop();
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

class _Actions extends ConsumerWidget {
  const _Actions({required this.data, required this.state, required this.overdue});
  final DetailData data;
  final OccurrenceState state;
  final bool overdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final r = data.reminder;
    final a = OccurrenceActions(context, ref);
    final open = state == OccurrenceState.pending || state == OccurrenceState.snoozed;
    final buttons = <Widget>[];

    if (r.isCalendarEvent) {
      buttons.add(_wide(FilledButton.icon(
        onPressed: () => remindMeFlow(context, ref, r),
        icon: const Icon(Icons.notifications_active_outlined),
        label: Text(l10n.actionRemindMe),
      )));
    } else if (state == OccurrenceState.done || state == OccurrenceState.skipped) {
      buttons.add(_wide(OutlinedButton(
        onPressed: () => ref.read(servicesProvider).service.setState(r.id, data.key, OccurrenceState.pending),
        child: Text(l10n.actionMarkNotDone), // OCC-5
      )));
    } else if (state != OccurrenceState.passed) {
      if (r.completable) {
        buttons.add(_wide(FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: c.success),
          onPressed: () async {
            await a.done(r, data.key);
            if (context.mounted && context.canPop()) context.pop();
          },
          icon: const Icon(Icons.check_rounded),
          label: Text(l10n.actionDone),
        )));
      }
      if (r.kind == Kind.occasion && open && r.alertPlan.any((s) => s.offset.amount < 0)) {
        buttons.add(_wide(FilledButton.tonalIcon(
          onPressed: () => a.prepared(r, data.key), // OCC-3
          icon: const Icon(Icons.card_giftcard_rounded),
          label: Text(l10n.actionPrepared),
        )));
      }
      buttons.add(Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => a.reschedule(r, data.key, currentStart: data.occurrence?.overrideStart),
              icon: const Icon(Icons.event_repeat_rounded),
              label: Text(l10n.actionReschedule),
            ),
          ),
          if (r.completable || r.repeats) ...[
            const SizedBox(width: Space.m),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await a.skip(r, data.key);
                  if (context.mounted && context.canPop()) context.pop();
                },
                icon: const Icon(Icons.skip_next_rounded),
                label: Text(l10n.actionSkip),
              ),
            ),
          ],
        ],
      ));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.l, 0),
      child: Column(
        children: [
          for (final b in buttons) Padding(padding: const EdgeInsets.only(bottom: Space.m), child: b),
        ],
      ),
    );
  }

  static Widget _wide(Widget b) => SizedBox(width: double.infinity, height: 50, child: b);
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
            onPressed: () => Navigator.pop(context, [
              for (final o in _chosen) AlertStage(AlertOffset.parse(o)),
            ]..sort((a, b) => _minutes(a.offset).compareTo(_minutes(b.offset)))),
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
              trailing: const Icon(Icons.add_rounded),
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
              icon: const Icon(Icons.remove_rounded),
            ),
            SizedBox(width: 56, child: Text('$_amount', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)),
            IconButton.filledTonal(
              onPressed: _amount < 99 ? () => setState(() => _amount++) : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: Space.m),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.l),
          child: SegmentedButton<OffsetUnit>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: OffsetUnit.minutes, label: Text(l10n.relMinutes(_amount).replaceAll('$_amount ', ''))),
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
