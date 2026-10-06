/// S-20 Capture sheet (FL-2): iOS-form layout — Cancel · New reminder · Save, input card, Details rows
/// parsed live from the text, Nag switch, Type and Personal/Work segmented controls.
/// Chip pickers (S-21), voice and templates come later.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/tokens.dart';

Future<void> showCaptureSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  builder: (_) => const CaptureSheet(),
);

class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  final _input = TextEditingController();
  final _example = Random().nextInt(5);
  ParseResult? _parsed;

  // Manual overrides (CAP-11: a field the user set stays as set while typing).
  Kind? _kind;
  ReminderContext? _context;
  bool? _nag;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(_reparse);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _reparse() {
    final text = _input.text.trim();
    if (text.isEmpty) return setState(() => _parsed = null);
    final prefs = ref.read(prefsProvider);
    final now = instantToWall(DateTime.now().toUtc(), prefs.defaultTimeZone);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final parser = ReminderParser(
      ParseContext(
        now: now,
        defaultTimeZone: prefs.defaultTimeZone,
        locale: locale,
        dayTimeHour: prefs.dayTime.hour,
        dayTimeMinute: prefs.dayTime.minute,
      ),
    );
    setState(() => _parsed = parser.parse(text));
  }

  /// The parse result with the user's manual choices applied.
  ParseResult? get _effective {
    final p = _parsed;
    if (p == null) return null;
    final kind = _kind ?? p.kind;
    return ParseResult(
      title: p.title,
      timing: p.timing,
      kind: kind,
      context: _context ?? p.context,
      flags: p.flags,
      rrule: p.rrule,
      repeatMode: p.repeatMode,
      alerts: _kind != null && _kind != p.kind ? null : p.alerts, // new type → its default plan
      nag: (_nag ?? (p.nag != null)) ? (p.nag ?? '2h') : null, // PRS-27 default interval
    );
  }

  Future<void> _save() async {
    final p = _effective;
    if (p == null || !canSave(p) || _saving) return;
    setState(() => _saving = true);
    final services = ref.read(servicesProvider);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final r = reminderFromParse(
      p,
      meta: await services.reminders.newMeta(),
      prefs: ref.read(prefsProvider),
      rawInput: _input.text.trim(),
    );
    await services.service.create(r);
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.snackSaved(_whenText(r, l10n))),
          action: SnackBarAction(label: l10n.actionUndo, onPressed: () => services.service.delete(r.id)),
        ),
      );
  }

  String _whenText(Reminder r, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMEd(locale).format(r.timing.start);
    return r.timing.type == TimingType.date ? date : '$date, ${DateFormat.jm(locale).format(r.timing.start)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final p = _effective;
    final savable = p != null && canSave(p) && !_saving;
    final examples = [l10n.captureEx1, l10n.captureEx2, l10n.captureEx3, l10n.captureEx4, l10n.captureEx5];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cancel · New reminder · Save
            Row(
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
                Expanded(child: Text(l10n.newReminder, style: text.titleMedium, textAlign: TextAlign.center)),
                TextButton(
                  onPressed: savable ? _save : null,
                  child: Text(l10n.actionSave, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: Space.s),
            _Card(
              child: TextField(
                controller: _input,
                autofocus: true,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                style: text.bodyLarge,
                decoration: InputDecoration(
                  hintText: examples[_example],
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(Space.l),
                ),
              ),
            ),
            if (p != null) ...[
              if (_hint(p, l10n) case final hint?)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
                  child: Text(hint, style: text.bodySmall?.copyWith(color: c.warning)),
                ),
              const SizedBox(height: Space.l),
              _Card(
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      color: c.danger,
                      label: l10n.rowDate,
                      value: _date(p),
                      flagged: p.flags.contains(ParseFlag.dateMissing) || p.flags.contains(ParseFlag.ambiguousDate),
                    ),
                    const Divider(indent: 56),
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      color: c.accent,
                      label: l10n.rowTime,
                      value: _time(p, l10n),
                      flagged: p.flags.contains(ParseFlag.ambiguousTime) || p.flags.contains(ParseFlag.timeInPast),
                    ),
                    const Divider(indent: 56),
                    _DetailRow(
                      icon: Icons.repeat_rounded,
                      color: c.meeting,
                      label: l10n.rowRepeat,
                      value: _repeat(p, l10n),
                    ),
                    const Divider(indent: 56),
                    _DetailRow(
                      icon: Icons.notifications_active_outlined,
                      color: c.warning,
                      label: l10n.rowAlerts,
                      value: _alerts(p, l10n),
                    ),
                    if (p.kind == Kind.task) ...[
                      const Divider(indent: 56),
                      SwitchListTile.adaptive(
                        contentPadding: const EdgeInsets.symmetric(horizontal: Space.m),
                        secondary: _IconTile(icon: Icons.replay_rounded, color: c.success),
                        title: Text(l10n.rowNag, style: text.bodyLarge),
                        value: p.nag != null,
                        onChanged: (v) => setState(() => _nag = v),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Space.l),
              SegmentedButton<Kind>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: Kind.task, label: Text(l10n.typeTask)),
                  ButtonSegment(value: Kind.meeting, label: Text(l10n.typeMeeting)),
                  ButtonSegment(value: Kind.event, label: Text(l10n.typeEvent)),
                  ButtonSegment(value: Kind.occasion, label: Text(l10n.typeOccasion)),
                ],
                selected: {p.kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: Space.m),
              SegmentedButton<ReminderContext>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: ReminderContext.personal, label: Text(l10n.ctxPersonal)),
                  ButtonSegment(value: ReminderContext.work, label: Text(l10n.ctxWork)),
                ],
                selected: {p.context},
                onSelectionChanged: (s) => setState(() => _context = s.first),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _hint(ParseResult p, AppLocalizations l10n) {
    if (p.flags.contains(ParseFlag.titleMissing) || p.title.trim().isEmpty) return l10n.hintTitleMissing;
    if (p.flags.contains(ParseFlag.dateMissing) || p.timing == null) return l10n.hintDateMissing;
    if (p.flags.contains(ParseFlag.timeInPast)) return l10n.hintTimeInPast;
    if (p.flags.contains(ParseFlag.ambiguousTime)) return l10n.hintAmbiguousTime(_time(p, l10n));
    if (p.flags.contains(ParseFlag.ambiguousDate)) return l10n.hintAmbiguousDate(_date(p));
    if (p.flags.contains(ParseFlag.pastDateRolled)) return l10n.hintPastDateRolled(_date(p));
    return null;
  }

  String _date(ParseResult p) {
    final t = p.timing;
    if (t == null) return '—';
    return DateFormat.yMMMEd(Localizations.localeOf(context).toString()).format(parseWall(t.start));
  }

  String _time(ParseResult p, AppLocalizations l10n) {
    final t = p.timing;
    if (t == null) return '—';
    if (t.type == TimingType.date) return l10n.allDay;
    final locale = Localizations.localeOf(context).toString();
    final start = DateFormat.jm(locale).format(parseWall(t.start));
    final end = t.end == null ? '' : ' – ${DateFormat.jm(locale).format(parseWall(t.end!))}';
    return '$start$end${t.tz != null ? ' (${t.tz!.split('/').last.replaceAll('_', ' ')})' : ''}';
  }

  String _repeat(ParseResult p, AppLocalizations l10n) {
    final rule = p.rrule;
    if (rule == null) return l10n.repeatNever;
    final parts = {for (final kv in rule.split(';').map((e) => e.split('='))) kv[0]: kv.length > 1 ? kv[1] : ''};
    final interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
    final every = interval != 1
        ? l10n.repeatCustom
        : switch (parts['FREQ']) {
            'DAILY' => l10n.repeatDaily,
            'WEEKLY' when parts['BYDAY'] == 'MO,TU,WE,TH,FR' => l10n.repeatWeekdays,
            'WEEKLY' => l10n.repeatWeekly,
            'MONTHLY' => l10n.repeatMonthly,
            'YEARLY' => l10n.repeatYearly,
            _ => l10n.repeatCustom,
          };
    return p.repeatMode == RecurrenceMode.afterCompletion ? l10n.repeatAfterDone(every) : every;
  }

  String _alerts(ParseResult p, AppLocalizations l10n) {
    final t = p.timing;
    final plan = p.alerts?.map(AlertOffset.parse).toList() ??
        defaultAlertPlan(p.kind, t?.type ?? TimingType.date).map((s) => s.offset).toList();
    if (plan.isEmpty) return l10n.alertNone;
    String one(AlertOffset o) {
      if (o.amount == 0) return l10n.alertAtTime;
      final n = o.amount.abs();
      final rel = switch (o.unit) {
        OffsetUnit.minutes => l10n.relMinutes(n),
        OffsetUnit.hours => l10n.relHours(n),
        OffsetUnit.days => l10n.relDays(n),
        OffsetUnit.weeks => l10n.relWeeks(n),
        OffsetUnit.months => l10n.relMonths(n),
      };
      return o.amount < 0 ? l10n.alertBefore(rel) : rel;
    }

    return plan.map(one).join(', ');
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(Radii.row),
    child: Material(color: AppColors.of(context).bgGrouped, child: child),
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
    child: Icon(icon, color: Colors.white, size: 18),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.flagged = false,
  });
  final IconData icon;
  final Color color;
  final String label, value;
  final bool flagged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.m),
      child: Row(
        children: [
          _IconTile(icon: icon, color: color),
          const SizedBox(width: Space.m),
          Text(label, style: text.bodyLarge),
          const SizedBox(width: Space.m),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: flagged ? c.warning : null),
            ),
          ),
        ],
      ),
    );
  }
}
