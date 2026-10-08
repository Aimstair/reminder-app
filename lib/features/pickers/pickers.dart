/// S-21 field pickers (small sheets): repeat (incl. after completion), time zone, alert plan, nag.
/// Used by the capture sheet (fields chosen here lock, CAP-11) and the full editor (S-22).
library;

import 'package:flutter/material.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../detail/detail_page.dart' show alertSortKey, pickOffset;
import '../../ui/icons.dart';

typedef RepeatChoice = ({String? rrule, RecurrenceMode mode});

/// S-21f. [start] gives the weekday / day of month for weekly and monthly rules.
Future<RepeatChoice?> pickRepeat(
  BuildContext context, {
  required String? current,
  required RecurrenceMode mode,
  required DateTime start,
  required bool completable,
}) =>
    showAppSheet<RepeatChoice>(
      context,
      (ctx) => _RepeatSheet(current: current, mode: mode, start: start, completable: completable),
    );

class _RepeatSheet extends StatefulWidget {
  const _RepeatSheet({required this.current, required this.mode, required this.start, required this.completable});
  final String? current;
  final RecurrenceMode mode;
  final DateTime start;
  final bool completable;

  @override
  State<_RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<_RepeatSheet> {
  late String? _rule = widget.current;
  late bool _afterDone = widget.mode == RecurrenceMode.afterCompletion;
  int _interval = 2;
  String _unit = 'WEEKLY';

  static const _codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = Fmt.of(context);
    final c = AppColors.of(context);
    final wd = _codes[widget.start.weekday - 1];
    final options = <(String, String?)>[
      (l10n.repeatNever, null),
      (l10n.repeatDaily, 'FREQ=DAILY'),
      (l10n.repeatWeekdays, 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'),
      (f.repeat('FREQ=WEEKLY;BYDAY=$wd', RecurrenceMode.fixed), 'FREQ=WEEKLY;BYDAY=$wd'),
      (l10n.everyWeeks(2), 'FREQ=WEEKLY;INTERVAL=2;BYDAY=$wd'),
      (l10n.repeatMonthly, 'FREQ=MONTHLY;BYMONTHDAY=${widget.start.day}'),
      (l10n.repeatLastBusinessDay, 'FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1'), // REC-5
      (l10n.repeatYearly, 'FREQ=YEARLY;BYMONTH=${widget.start.month};BYMONTHDAY=${widget.start.day}'),
    ];
    final customRule = 'FREQ=$_unit;INTERVAL=$_interval${_unit == 'WEEKLY' ? ';BYDAY=$wd' : ''}';
    final known = options.any((o) => o.$2 == _rule);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetBar(
          title: l10n.rowRepeat,
          left: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
          right: TextButton(
            onPressed: () => Navigator.pop(context, (
              rrule: _rule,
              // REC-10: after completion only for completable types; meetings/events stay fixed.
              mode: _rule != null && _afterDone && widget.completable ? RecurrenceMode.afterCompletion : RecurrenceMode.fixed,
            )),
            child: Text(l10n.pickerDone),
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              InsetGroup(
                indent: Space.l,
                color: c.bgGrouped,
                children: [
                  for (final (label, rule) in options)
                    ListTile(
                      title: Text(label),
                      trailing: _rule == rule ? Icon(AppIcons.check, color: c.accent) : null,
                      onTap: () => setState(() => _rule = rule),
                    ),
                  ListTile(
                    title: Text(l10n.repeatCustom),
                    subtitle: Text(f.repeat(customRule, RecurrenceMode.fixed)),
                    trailing: !known && _rule != null ? Icon(AppIcons.check, color: c.accent) : null,
                    onTap: () => setState(() => _rule = customRule),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _interval > 1 ? () => setState(() => _interval--) : null,
                      icon: const Icon(AppIcons.minus),
                    ),
                    SizedBox(width: 40, child: Text('$_interval', textAlign: TextAlign.center)),
                    IconButton.filledTonal(
                      onPressed: () => setState(() => _interval++),
                      icon: const Icon(AppIcons.add),
                    ),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _unit,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 'DAILY', child: Text(l10n.everyDays(_interval))),
                          DropdownMenuItem(value: 'WEEKLY', child: Text(l10n.everyWeeks(_interval))),
                          DropdownMenuItem(value: 'MONTHLY', child: Text(l10n.everyMonths(_interval))),
                          DropdownMenuItem(value: 'YEARLY', child: Text(l10n.everyYears(_interval))),
                        ],
                        onChanged: (v) => setState(() {
                          _unit = v!;
                          _rule = 'FREQ=$_unit;INTERVAL=$_interval${_unit == 'WEEKLY' ? ';BYDAY=$wd' : ''}';
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.completable)
                Padding(
                  padding: const EdgeInsets.all(Space.l),
                  child: InsetGroup(
                    margin: EdgeInsets.zero,
                    color: c.bgGrouped,
                    children: [
                      SwitchRow(
                        label: l10n.repeatAfterDoneToggle, // REC-6
                        value: _afterDone,
                        onChanged: _rule == null ? null : (v) => setState(() => _afterDone = v),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Space.l),
            ],
          ),
        ),
      ],
    );
  }
}

/// S-21c: searchable IANA zone list.
Future<String?> pickTimeZone(BuildContext context, String current) =>
    showAppSheet<String>(context, (ctx) => _ZoneSheet(current: current), expand: true);

class _ZoneSheet extends StatefulWidget {
  const _ZoneSheet({required this.current});
  final String current;

  @override
  State<_ZoneSheet> createState() => _ZoneSheetState();
}

class _ZoneSheetState extends State<_ZoneSheet> {
  final _all = timeZoneNames();
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final now = DateTime.now().toUtc();
    final q = _q.toLowerCase().replaceAll(' ', '_');
    final list = _q.isEmpty ? _all : _all.where((z) => z.toLowerCase().contains(q)).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.zoneSearch,
              prefixIcon: const Icon(AppIcons.search),
              filled: true,
              fillColor: c.bgGrouped,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.row), borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final z = list[i];
              return ListTile(
                title: Text(Fmt.city(z)),
                subtitle: Text(z),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(f.time(instantToWall(now, z)), style: Theme.of(context).textTheme.bodyMedium),
                    if (z == widget.current) ...[const SizedBox(width: Space.s), Icon(AppIcons.check, color: c.accent)],
                  ],
                ),
                onTap: () => Navigator.pop(context, z),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// S-21g: edit an alert plan (ALR-1, ALR-4 max 10, ALR-7 may be empty).
Future<List<AlertStage>?> pickAlerts(BuildContext context, List<AlertStage> current) =>
    showAppSheet<List<AlertStage>>(context, (ctx) => _AlertsSheet(initial: current));

class _AlertsSheet extends StatefulWidget {
  const _AlertsSheet({required this.initial});
  final List<AlertStage> initial;

  @override
  State<_AlertsSheet> createState() => _AlertsSheetState();
}

class _AlertsSheetState extends State<_AlertsSheet> {
  late final List<AlertStage> _plan = [...widget.initial];

  static const _quick = [
    AlertOffset.zero,
    AlertOffset(-10, OffsetUnit.minutes),
    AlertOffset(-1, OffsetUnit.hours),
    AlertOffset(-1, OffsetUnit.days),
    AlertOffset(-2, OffsetUnit.days),
    AlertOffset(-1, OffsetUnit.weeks),
    AlertOffset(-1, OffsetUnit.months),
  ];

  void _add(AlertOffset o) {
    if (_plan.length >= 10 || _plan.any((s) => s.offset == o)) return;
    setState(() => _plan
      ..add(AlertStage(o))
      ..sort((a, b) => alertSortKey(a).compareTo(alertSortKey(b))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = Fmt.of(context);
    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetBar(
          title: l10n.rowAlerts,
          left: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
          right: TextButton(onPressed: () => Navigator.pop(context, _plan), child: Text(l10n.pickerDone)),
        ),
        if (_plan.isEmpty)
          Padding(padding: const EdgeInsets.all(Space.l), child: Text(l10n.alertNone))
        else
          InsetGroup(
            indent: Space.l,
            color: c.bgGrouped,
            children: [
              for (final s in _plan)
                ListTile(
                  leading: Icon(AppIcons.alert, color: c.warning),
                  title: Text(s.label == 'start_by' ? '${l10n.startBy} · ${f.offset(s.offset)}' : f.offset(s.offset)),
                  trailing: IconButton(
                    icon: Icon(AppIcons.remove, color: c.danger),
                    onPressed: () => setState(() => _plan.remove(s)),
                  ),
                ),
            ],
          ),
        const SizedBox(height: Space.m),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.l),
          child: Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final o in _quick)
                if (!_plan.any((s) => s.offset == o))
                  ActionChip(label: Text(f.offset(o)), avatar: const Icon(AppIcons.add, size: 18), onPressed: () => _add(o)),
              ActionChip(
                label: Text(l10n.remindCustom),
                avatar: const Icon(AppIcons.custom, size: 18),
                onPressed: () async {
                  final o = await pickOffset(context);
                  if (o != null) _add(o);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
      ],
    );
  }
}

/// ALR-9 nag interval: off, 30 min, 1 h, 2 h (default), 4 h.
Future<Duration?> pickNag(BuildContext context, Duration? current) async {
  final l10n = AppLocalizations.of(context);
  final f = Fmt.of(context);
  const options = [Duration(minutes: 30), Duration(hours: 1), Duration(hours: 2), Duration(hours: 4)];
  final picked = await showAppSheet<Duration>(
    context,
    (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.rowNag, style: Theme.of(ctx).textTheme.titleMedium),
        const SizedBox(height: Space.s),
        ListTile(
          title: Text(l10n.nagOff),
          trailing: current == null ? const Icon(AppIcons.check) : null,
          onTap: () => Navigator.pop(ctx, Duration.zero),
        ),
        for (final d in options)
          ListTile(
            title: Text(l10n.nagEvery(f.duration(d))),
            trailing: current == d ? const Icon(AppIcons.check) : null,
            onTap: () => Navigator.pop(ctx, d),
          ),
        const SizedBox(height: Space.l),
      ],
    ),
  );
  return picked;
}
