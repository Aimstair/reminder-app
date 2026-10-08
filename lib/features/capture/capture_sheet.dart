/// S-20 Capture sheet (FL-2…5): iOS-form layout — Cancel · New reminder · Save, input card with voice
/// and template tag, template chips when empty (TPL-1), Details rows parsed live (tap → S-21 picker,
/// which locks that field, CAP-11), Nag switch, Type and Personal/Work segmented controls, a
/// one-line "first alert" summary. Opened from [+], Day/Month taps, the tile, widget and share sheet.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../actions/occurrence_actions.dart';
import '../pickers/pickers.dart';
import '../setup/permission_flow.dart';

/// [at]: a time slot (Day view, VW-8) — date and time locked. [day]: a date (Month long-press).
/// [text]: shared text (S-63, CAP-12).
Future<void> showCaptureSheet(BuildContext context, {DateTime? at, DateTime? day, String? text}) async {
  var withAlerts = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (_) => CaptureSheet(at: at, day: day, text: text, onSavedWithAlerts: () => withAlerts = true),
  );
  if (withAlerts && context.mounted) await runPermissionFlowOnce(context);
}

class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key, this.at, this.day, this.text, this.onSavedWithAlerts});
  final VoidCallback? onSavedWithAlerts;
  final DateTime? at;
  final DateTime? day;
  final String? text;

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _example = Random().nextInt(5);
  ParseResult? _parsed;
  String? _notes;
  Template? _template;
  bool _saving = false;
  bool _listening = false;

  // CAP-11 locks: a field set by hand stays as set while typing.
  DateTime? _lockDate;
  ClockTime? _lockTime;
  bool? _lockAllDay;
  String? _lockZone;
  Kind? _lockKind;
  ReminderContext? _lockContext;
  RepeatChoice? _lockRepeat;
  List<AlertStage>? _lockAlerts;
  bool? _lockNag;

  @override
  void initState() {
    super.initState();
    _input.addListener(_reparse);
    // A hardware Enter key saves (like the keyboard's Done) instead of adding a line break;
    // Shift+Enter still breaks the line.
    _focus.onKeyEvent = (_, e) {
      final enter = e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter;
      if (!enter || HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
      if (e is KeyDownEvent) _save();
      return KeyEventResult.handled;
    };
    if (widget.at case final at?) {
      _lockDate = dateOnly(at);
      _lockTime = ClockTime(at.hour, at.minute);
      _lockAllDay = false;
    } else if (widget.day case final d?) {
      _lockDate = dateOnly(d);
    }
    if (widget.text case final shared?) {
      final split = splitSharedText(shared); // CAP-12
      _input.text = split.input;
      _notes = split.notes;
    }

  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  DateTime get _nowWall => instantToWall(DateTime.now().toUtc(), ref.read(prefsProvider).defaultTimeZone);

  void _reparse() {
    final text = _input.text.trim();
    if (text.isEmpty) return setState(() => _parsed = null);
    final prefs = ref.read(prefsProvider);
    final parser = ReminderParser(
      ParseContext(
        now: _nowWall,
        defaultTimeZone: prefs.defaultTimeZone,
        locale: Localizations.localeOf(context).toLanguageTag(),
        dayTimeHour: prefs.dayTime.hour,
        dayTimeMinute: prefs.dayTime.minute,
      ),
    );
    var p = parser.parse(text);
    if (_template case final t?) p = applyTemplate(t, p, input: text, now: _nowWall);
    setState(() => _parsed = p);
  }

  /// The parse result with templates and the user's locks applied.
  ParseResult? get _effective {
    final p = _parsed;
    if (p == null) return null;
    var timing = p.timing;
    final flags = {...p.flags};
    if (_lockDate != null || _lockTime != null || _lockAllDay != null || _lockZone != null) {
      final base = timing ?? ParsedTiming(type: TimingType.date, start: formatWallDate(addDays(dateOnly(_nowWall), 1)));
      final parsedStart = parseWall(base.start);
      final date = _lockDate ?? dateOnly(parsedStart);
      final allDay = _lockAllDay ?? (_lockTime == null && base.type == TimingType.date);
      if (allDay) {
        timing = ParsedTiming(type: TimingType.date, start: formatWallDate(date));
      } else {
        final t = _lockTime ??
            (base.type == TimingType.datetime
                ? ClockTime(parsedStart.hour, parsedStart.minute)
                : ref.read(prefsProvider).dayTime);
        final start = DateTime.utc(date.year, date.month, date.day, t.hour, t.minute);
        final duration = base.end == null ? null : parseWall(base.end!).difference(parsedStart);
        timing = ParsedTiming(
          type: TimingType.datetime,
          start: formatWallDateTime(start),
          end: duration == null ? null : formatWallDateTime(start.add(duration)),
          tz: _lockZone ?? base.tz,
        );
      }
      if (_lockDate != null) {
        flags
          ..remove(ParseFlag.dateMissing)
          ..remove(ParseFlag.ambiguousDate)
          ..remove(ParseFlag.pastDateRolled);
      }
      if (_lockTime != null) flags.remove(ParseFlag.ambiguousTime);
    }
    final kind = _lockKind ?? p.kind;
    return ParseResult(
      title: p.title,
      timing: timing,
      kind: kind,
      context: _lockContext ?? p.context,
      flags: flags,
      rrule: _lockRepeat != null ? _lockRepeat!.rrule : p.rrule,
      repeatMode: _lockRepeat?.mode ?? p.repeatMode,
      // A type chosen by hand brings its own default plan, unless alerts were set too.
      alerts: _lockAlerts != null
          ? [for (final s in _lockAlerts!) s.offset.toString()]
          : (_lockKind != null && _lockKind != p.kind ? null : p.alerts),
      nag: switch (_lockNag) {
        true => p.nag ?? '2h',
        false => null,
        null => p.nag,
      },
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
    final f = Fmt.of(context);
    try {
      var r = reminderFromParse(
        p,
        meta: await services.reminders.newMeta(),
        prefs: ref.read(prefsProvider),
        rawInput: _input.text.trim(), // CAP-8
      );
      r = r.copyWith(notes: () => _notes, templateId: () => _template?.id);
      if (!r.completable && r.repeatMode == RecurrenceMode.afterCompletion) {
        r = r.copyWith(repeatMode: RecurrenceMode.fixed); // REC-10
      }
      await services.service.create(r);
      navigator.pop();
      final when = r.timing.type == TimingType.date ? f.date(r.timing.start) : f.when(r.timing.start, allDay: false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.snackSaved(when)),
            duration: const Duration(seconds: 5),
            persist: false,
            action: SnackBarAction(label: l10n.actionUndo, onPressed: () => services.service.delete(r.id)),
          ),
        );
      // PRM-6: permissions on the first save with alerts — on the screen below the sheet.
      if (r.alertPlan.isNotEmpty) widget.onSavedWithAlerts?.call();
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.errSave)));
    }
  }

  /// TPL-2/TPL-4: a template locks type, repeat and alerts; another replaces them.
  void _setTemplate(Template t) {
    setState(() {
      _template = t;
      _lockKind = null;
      _lockRepeat = null;
      _lockAlerts = null;
      _lockNag = null;
    });
    _reparse();
    _focus.requestFocus();
  }

  Future<void> _voice() async {
    final s = ref.read(servicesProvider);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_listening) {
      await s.voice.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    final ok = await s.voice.listen(
      onText: (t) {
        if (mounted && t.isNotEmpty) _input.text = t;
      },
      onDone: (t) {
        if (!mounted) return;
        setState(() => _listening = false);
        if (t.trim().isEmpty) messenger.showSnackBar(SnackBar(content: Text(l10n.errSpeech)));
        // CAP-7: voice never saves directly — the preview stays for review.
      },
    );
    if (!ok && mounted) {
      setState(() => _listening = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.errVoice)));
    }
  }

  String _placeholder(AppLocalizations l10n) => switch (_template) {
    Template.birthday => l10n.tplPhBirthday,
    Template.billDue => l10n.tplPhBill,
    Template.renewal => l10n.tplPhRenewal,
    Template.freeTrial => l10n.tplPhTrial,
    Template.nightOut => l10n.tplPhNightOut,
    Template.appointment => l10n.tplPhAppointment,
    null => [l10n.captureEx1, l10n.captureEx2, l10n.captureEx3, l10n.captureEx4, l10n.captureEx5][_example],
  };

  static String templateLabel(AppLocalizations l10n, Template t) => switch (t) {
    Template.birthday => l10n.tplBirthday,
    Template.billDue => l10n.tplBill,
    Template.renewal => l10n.tplRenewal,
    Template.freeTrial => l10n.tplTrial,
    Template.nightOut => l10n.tplNightOut,
    Template.appointment => l10n.tplAppointment,
  };

  static IconData templateIcon(Template t) => switch (t) {
    Template.birthday => Icons.cake_outlined,
    Template.billDue => Icons.receipt_long_outlined,
    Template.renewal => Icons.autorenew_rounded,
    Template.freeTrial => Icons.timer_outlined,
    Template.nightOut => Icons.local_bar_outlined,
    Template.appointment => Icons.medical_services_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final p = _effective;
    final savable = p != null && canSave(p) && !_saving;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetBar(
              title: l10n.newReminder,
              left: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
              right: TextButton(
                onPressed: savable ? _save : null,
                child: Text(l10n.actionSave, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: Space.s),
            // Input card: text + voice + removable template tag
            Material(
              color: c.bgGrouped,
              borderRadius: BorderRadius.circular(Radii.row),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_template case final t?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Space.m, Space.m, Space.m, 0),
                      child: InputChip(
                        avatar: Icon(templateIcon(t), size: 18),
                        label: Text(templateLabel(l10n, t)),
                        onDeleted: () {
                          setState(() => _template = null);
                          _reparse();
                        },
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          focusNode: _focus,
                          autofocus: widget.text == null || _input.text.isEmpty,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _save(),
                          style: text.bodyLarge,
                          decoration: InputDecoration(
                            hintText: _placeholder(l10n),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(Space.l),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.actionSpeak,
                        onPressed: _voice,
                        icon: Icon(
                          _listening ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
                          color: _listening ? c.danger : c.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_notes != null && widget.text != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 16, color: c.textSecondary),
                    const SizedBox(width: Space.xs),
                    Text(l10n.captureSharedInNotes, style: text.bodySmall),
                  ],
                ),
              ),
            if (_listening)
              Padding(
                padding: const EdgeInsets.only(top: Space.s),
                child: Text(l10n.listening, style: text.bodySmall, textAlign: TextAlign.center),
              ),
            // TPL-1: template chips while the input is empty.
            if (p == null && _template == null) ...[
              const SizedBox(height: Space.l),
              Wrap(
                spacing: Space.s,
                runSpacing: Space.s,
                children: [
                  for (final t in Template.values)
                    ActionChip(
                      avatar: Icon(templateIcon(t), size: 18),
                      label: Text(templateLabel(l10n, t)),
                      onPressed: () => _setTemplate(t),
                    ),
                ],
              ),
            ],
            if (p != null) ...[
              if (_hint(p, l10n, f) case final hint?)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
                  child: Text(hint, style: text.bodySmall?.copyWith(color: c.warning)),
                ),
              const SizedBox(height: Space.l),
              InsetGroup(
                margin: EdgeInsets.zero,
                indent: 56,
                color: c.bgGrouped,
                children: [
                  FormRow(
                    icon: Icons.calendar_today_rounded,
                    color: c.danger,
                    label: l10n.rowDate,
                    value: _date(p, f),
                    flagged: p.flags.contains(ParseFlag.dateMissing) || p.flags.contains(ParseFlag.ambiguousDate),
                    onTap: () async {
                      final start = p.timing == null ? _nowWall : parseWall(p.timing!.start);
                      final d = await pickDateTime(context, start, withTime: false);
                      if (d != null) setState(() => _lockDate = d);
                    },
                  ),
                  FormRow(
                    icon: Icons.schedule_rounded,
                    color: c.accent,
                    label: l10n.rowTime,
                    value: _time(p, l10n, f),
                    flagged: p.flags.contains(ParseFlag.ambiguousTime) || p.flags.contains(ParseFlag.timeInPast),
                    onTap: () => _pickTime(p),
                  ),
                  if (p.timing?.type == TimingType.datetime)
                    FormRow(
                      icon: Icons.public_rounded,
                      color: c.meeting,
                      label: l10n.rowTimeZone,
                      value: Fmt.city(p.timing!.tz ?? ref.read(prefsProvider).defaultTimeZone),
                      onTap: () async {
                        final z = await pickTimeZone(context, p.timing!.tz ?? ref.read(prefsProvider).defaultTimeZone);
                        if (z != null) setState(() => _lockZone = z);
                      },
                    ),
                  FormRow(
                    icon: Icons.repeat_rounded,
                    color: c.meeting,
                    label: l10n.rowRepeat,
                    value: f.repeat(p.rrule, p.repeatMode ?? RecurrenceMode.fixed),
                    onTap: () async {
                      final start = p.timing == null ? _nowWall : parseWall(p.timing!.start);
                      final v = await pickRepeat(
                        context,
                        current: p.rrule,
                        mode: p.repeatMode ?? RecurrenceMode.fixed,
                        start: start,
                        completable: p.kind == Kind.task || p.kind == Kind.occasion,
                      );
                      if (v != null) setState(() => _lockRepeat = v);
                    },
                  ),
                  FormRow(
                    icon: Icons.notifications_active_outlined,
                    color: c.warning,
                    label: l10n.rowAlerts,
                    value: f.alerts(_plan(p)),
                    onTap: () async {
                      final v = await pickAlerts(context, _plan(p));
                      if (v != null) setState(() => _lockAlerts = v);
                    },
                  ),
                  if (p.kind == Kind.task || p.kind == Kind.occasion)
                    SwitchRow(
                      icon: Icons.replay_rounded,
                      color: c.success,
                      label: l10n.rowNag,
                      value: p.nag != null,
                      onChanged: (v) => setState(() => _lockNag = v),
                    ),
                ],
              ),
              if (_firstAlert(p, f) case final first?)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
                  child: Text(first, style: text.bodySmall),
                ),
              const SizedBox(height: Space.l),
              SegmentedButton<Kind>(
                showSelectedIcon: false,
                segments: [for (final k in Kind.values) ButtonSegment(value: k, label: Text(f.kind(k)))],
                selected: {p.kind},
                onSelectionChanged: (s) => setState(() => _lockKind = s.first),
              ),
              const SizedBox(height: Space.m),
              SegmentedButton<ReminderContext>(
                showSelectedIcon: false,
                segments: [for (final x in ReminderContext.values) ButtonSegment(value: x, label: Text(f.context(x)))],
                selected: {p.context},
                onSelectionChanged: (s) => setState(() => _lockContext = s.first),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(ParseResult p) async {
    final t = p.timing;
    final start = t == null ? _nowWall : parseWall(t.start);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: t?.type == TimingType.datetime ? start.hour : 9, minute: start.minute),
    );
    if (picked != null) {
      setState(() {
        _lockTime = ClockTime(picked.hour, picked.minute);
        _lockAllDay = false;
      });
    }
  }

  List<AlertStage> _plan(ParseResult p) =>
      p.alerts?.map((o) => AlertStage(AlertOffset.parse(o))).toList() ??
      ref.read(prefsProvider).alertPlanFor(p.kind, p.timing?.type ?? TimingType.date);

  /// One-line "first alert" summary.
  String? _firstAlert(ParseResult p, Fmt f) {
    if (p.timing == null || !canSave(p)) return null;
    final prefs = ref.read(prefsProvider);
    final now = DateTime.now().toUtc();
    final r = reminderFromParse(
      p,
      meta: RecordMeta(id: 'preview', createdAt: now, updatedAt: now, deviceId: ''),
      prefs: prefs,
    );
    final alarms = AlarmPlanner(prefs: prefs, text: (_) => (title: '', body: ''))
        .plan([r], const {}, now)
        .where((a) => !a.key.contains(':nag'))
        .toList();
    if (alarms.isEmpty) return null;
    final first = instantToWall(alarms.first.fireAt, prefs.deviceTimeZone);
    return '${f.l10n.rowAlerts}: ${f.when(first, allDay: false, today: dateOnly(instantToWall(now, prefs.deviceTimeZone)))}';
  }

  String? _hint(ParseResult p, AppLocalizations l10n, Fmt f) {
    if (p.flags.contains(ParseFlag.titleMissing) || p.title.trim().isEmpty) return l10n.hintTitleMissing;
    if (p.flags.contains(ParseFlag.dateMissing) || p.timing == null) return l10n.hintDateMissing;
    if (p.flags.contains(ParseFlag.timeInPast)) return l10n.hintTimeInPast;
    if (p.flags.contains(ParseFlag.ambiguousTime)) return l10n.hintAmbiguousTime(_time(p, l10n, f));
    if (p.flags.contains(ParseFlag.ambiguousDate)) return l10n.hintAmbiguousDate(_date(p, f));
    if (p.flags.contains(ParseFlag.pastDateRolled)) return l10n.hintPastDateRolled(_date(p, f));
    return null;
  }

  String _date(ParseResult p, Fmt f) {
    final t = p.timing;
    if (t == null || p.flags.contains(ParseFlag.dateMissing)) return '—';
    return f.date(parseWall(t.start));
  }

  String _time(ParseResult p, AppLocalizations l10n, Fmt f) {
    final t = p.timing;
    if (t == null) return '—';
    if (t.type == TimingType.date) return l10n.allDay;
    final start = f.time(parseWall(t.start));
    final end = t.end == null ? '' : ' – ${f.time(parseWall(t.end!))}';
    return '$start$end';
  }
}
