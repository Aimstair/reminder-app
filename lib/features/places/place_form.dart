/// S-25 Place reminder form (mockup 13): the same iOS form as capture (DS11) — title + voice, place,
/// Arrive / Leave, Active (any day · on a date · repeats), hours, remind me (first / every time),
/// Personal / Work, notes, links & files. Opened from the Places screen (LOC-3), an event (LOC-11) or
/// a parsed place phrase (LOC-16).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/icons.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../actions/occurrence_actions.dart' show pickDateTime;
import '../attachments/attachments.dart';
import '../pickers/pickers.dart';
import 'background_explainer.dart';
import 'place_format.dart';
import 'place_picker_page.dart';

/// Opens S-25. [editing] edits a place reminder; otherwise a new one at [place].
Future<void> showPlaceForm(
  BuildContext context, {
  Place? place,
  Reminder? editing,
  String? title,
  DateTime? date,
  ClockTime? hoursFrom,
  ClockTime? hoursTo,
  bool arrive = true,
  bool leave = false,
  LinkedEvent? linked,
}) => showAppSheet<void>(
  context,
  (_) => PlaceForm(
    place: place,
    editing: editing,
    title: title,
    date: date,
    hoursFrom: hoursFrom,
    hoursTo: hoursTo,
    arrive: arrive,
    leave: leave,
    linked: linked,
  ),
  expand: true,
);

class PlaceForm extends ConsumerStatefulWidget {
  const PlaceForm({
    super.key,
    this.place,
    this.editing,
    this.title,
    this.date,
    this.hoursFrom,
    this.hoursTo,
    this.arrive = true,
    this.leave = false,
    this.linked,
  });

  final Place? place;
  final Reminder? editing;
  final String? title;
  final DateTime? date;
  final ClockTime? hoursFrom;
  final ClockTime? hoursTo;
  final bool arrive;
  final bool leave;
  final LinkedEvent? linked;

  @override
  ConsumerState<PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends ConsumerState<PlaceForm> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late List<Attachment> _attachments;
  Place? _place;
  late bool _arrive;
  late bool _leave;
  late PlaceActive _active;
  late DateTime _date;
  String? _rrule;
  ClockTime? _from;
  ClockTime? _to;
  late PlaceRemind _remind;
  late ReminderContext _context;
  late bool _paused;
  LinkedEvent? _linked;
  var _listening = false;
  var _saving = false;
  final _hint = DateTime.now().millisecond % 3;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    final t = e?.place;
    final today = DateTime.now();
    _title = TextEditingController(text: e?.title ?? widget.title ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _attachments = e?.attachments ?? const [];
    _place = widget.place ?? (t == null ? null : ref.read(servicesProvider).places.byId[t.placeId]);
    _arrive = t?.onArrive ?? widget.arrive;
    _leave = t?.onLeave ?? widget.leave;
    _active = t?.active ?? (widget.date != null ? PlaceActive.onDate : PlaceActive.anyDay);
    _date = e != null ? dateOnly(e.timing.start) : (widget.date ?? DateTime.utc(today.year, today.month, today.day));
    _rrule = e?.rrule;
    _from = t?.hoursFrom ?? widget.hoursFrom;
    _to = t?.hoursTo ?? widget.hoursTo;
    _remind = t?.remind ?? PlaceRemind.firstTime;
    _context = e?.context ?? ReminderContext.personal;
    _paused = t?.paused ?? false;
    _linked = t?.linkedEvent ?? widget.linked;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _valid => _title.text.trim().isNotEmpty && _place != null && (_arrive || _leave);

  /// What will be saved — also feeds the summary line.
  Reminder _draft(RecordMeta meta) => Reminder(
    meta: meta,
    title: _title.text.trim(),
    notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    attachments: _attachments,
    kind: Kind.place,
    context: _context,
    // LOC-4: the timing date is the active date (on a date / repeats) or just the day it was made (any day).
    timing: Timing(type: TimingType.date, start: _date),
    alertPlan: const [],
    rrule: _active == PlaceActive.repeats ? (_rrule ?? 'FREQ=WEEKLY') : null,
    status: widget.editing?.status ?? ReminderStatus.active,
    source: widget.editing?.source ?? const ManualSource(),
    rawInput: widget.editing?.rawInput,
    place: PlaceTrigger(
      placeId: _place?.id ?? '',
      onArrive: _arrive || !_leave,
      onLeave: _leave,
      active: _active,
      hoursFrom: _from,
      hoursTo: _from == null ? null : _to,
      remind: _remind,
      paused: _paused,
      linkedEvent: _linked,
    ),
  );

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final s = ref.read(servicesProvider);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final e = widget.editing;
    final firstEver = e == null && (ref.read(placeRemindersProvider) ?? const []).isEmpty;
    if (e != null) {
      await s.service.edit(_draft(e.meta));
    } else {
      final r = _draft(await s.reminders.newMeta());
      await s.service.create(r);
      showUndoSnackOn(
        messenger,
        l10n.placeFormSaved(_place!.name),
        undoLabel: l10n.actionUndo,
        onUndo: () => unawaited(s.service.delete(r.id)),
      );
    }
    nav.pop();
    // PRM-9: after the first place reminder, explain "Allow all the time" if it isn't on yet.
    final status = await s.places.refreshStatus();
    if (firstEver && !status.background && nav.mounted) {
      await showBackgroundExplainer(nav.context, openSettings: s.places.gateway.openAppLocationSettings);
    }
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
        if (mounted && t.isNotEmpty) setState(() => _title.text = t);
      },
      onDone: (t) {
        if (!mounted) return;
        setState(() => _listening = false);
        if (t.trim().isEmpty) messenger.showSnackBar(SnackBar(content: Text(l10n.errSpeech)));
      },
    );
    if (!ok && mounted) {
      setState(() => _listening = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.errVoice)));
    }
  }

  Future<void> _pickPlace() async {
    final p = await pickPlace(context, editing: null);
    if (p != null && mounted) setState(() => _place = p);
  }

  Future<void> _pickDate() async {
    final d = await pickDateTime(context, _date, withTime: false);
    if (d != null && mounted) setState(() => _date = dateOnly(d));
  }

  Future<void> _pickRepeat() async {
    final choice = await pickRepeat(
      context,
      current: _rrule ?? 'FREQ=WEEKLY',
      mode: RecurrenceMode.fixed,
      start: _date,
      completable: false, // LOC-4: fixed repeats only
    );
    if (choice != null && mounted) {
      setState(() => _rrule = choice.rrule);
      if (choice.rrule == null) setState(() => _active = PlaceActive.onDate);
    }
  }

  Future<void> _pickHours() async {
    final l10n = AppLocalizations.of(context);
    final result = await showAppSheet<({ClockTime? from, ClockTime? to})>(
      context,
      (ctx) => _HoursSheet(from: _from, to: _to, l10n: l10n),
    );
    if (result != null && mounted) {
      setState(() {
        _from = result.from;
        _to = result.to;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final today = dateOnly(DateTime.now());
    final place = _place;
    final hints = [l10n.placeFormHint1, l10n.placeFormHint2, l10n.placeFormHint3];
    final draft = _draft(RecordMeta(id: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), deviceId: ''));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.l),
          child: SheetBar(
            title: widget.editing == null ? l10n.placeFormNew : l10n.placeFormEdit,
            left: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
            right: FilledButton(onPressed: _valid && !_saving ? _save : null, child: Text(l10n.actionSave)),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Space.xl),
            children: [
              if (_linked != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
                  child: Text(
                    l10n.placeFormFor(_linked!.title, f.when(_linked!.start, allDay: false, today: today)),
                    style: text.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: Space.s),
              // Input card (mockup 13): title + mic.
              InsetGroup(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.s, Space.s),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _title,
                            autofocus: widget.editing == null,
                            textCapitalization: TextCapitalization.sentences,
                            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: _linked != null ? l10n.placeFormHintEvent : hints[_hint],
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: l10n.actionSpeak,
                          onPressed: _voice,
                          icon: Icon(_listening ? AppIcons.stop : AppIcons.mic, color: c.accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              GroupCaption(l10n.placeFormCaptionPlace),
              InsetGroup(
                children: [
                  FormRow(
                    icon: place == null ? AppIcons.place : placeIcon(place.icon, solid: true),
                    color: place == null ? c.textSecondary : c.place(place.color),
                    label: place?.name ?? l10n.placeFormChoose,
                    subtitle: place == null
                        ? null
                        : [f.distance(place.radiusMeters.toDouble()), if (place.address?.isNotEmpty ?? false) place.address!]
                              .join(' · '),
                    onTap: _pickPlace,
                  ),
                ],
              ),
              GroupCaption(l10n.placeFormCaptionTrigger),
              InsetGroup(
                children: [
                  SwitchRow(
                    icon: AppIcons.arrive,
                    color: c.memorial,
                    label: l10n.placeTriggerArrive,
                    value: _arrive,
                    onChanged: (v) => setState(() => _arrive = v),
                  ),
                  SwitchRow(
                    icon: AppIcons.leave,
                    color: c.event,
                    label: l10n.placeTriggerLeave,
                    value: _leave,
                    onChanged: (v) => setState(() => _leave = v),
                  ),
                ],
              ),
              if (!_arrive && !_leave)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.xxxl, Space.s, Space.l, 0),
                  child: Text(l10n.placeFormNeedTrigger, style: text.bodySmall?.copyWith(color: c.warning)),
                ),
              GroupCaption(l10n.placeFormCaptionWhen),
              InsetGroup(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Space.m),
                    child: SegmentedPills<PlaceActive>(
                      items: [
                        (value: PlaceActive.anyDay, label: l10n.placeActiveAny, dot: null),
                        (value: PlaceActive.onDate, label: l10n.placeActiveDate, dot: null),
                        (value: PlaceActive.repeats, label: l10n.placeActiveRepeats, dot: null),
                      ],
                      selected: _active,
                      onChanged: (a) => setState(() {
                        _active = a;
                        if (a == PlaceActive.repeats && _rrule == null) {
                          _rrule = 'FREQ=WEEKLY;BYDAY=${const ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'][_date.weekday - 1]}';
                        }
                      }),
                    ),
                  ),
                  if (_active != PlaceActive.anyDay)
                    FormRow(
                      icon: AppIcons.calendar,
                      color: c.danger,
                      label: l10n.rowDate,
                      value: f.date(_date, today: today),
                      onTap: _pickDate,
                    ),
                  if (_active == PlaceActive.repeats)
                    FormRow(
                      icon: AppIcons.repeat,
                      color: c.textSecondary,
                      label: l10n.rowRepeat,
                      value: f.repeat(_rrule, RecurrenceMode.fixed, start: _date),
                      onTap: _pickRepeat,
                    ),
                  FormRow(
                    icon: AppIcons.time,
                    color: c.accent,
                    label: l10n.placeFormHours,
                    value: f.hours(draft.place!),
                    onTap: _pickHours,
                  ),
                  FormRow(
                    icon: AppIcons.alert,
                    color: c.meeting,
                    label: l10n.placeFormRemindMe,
                    subtitle: _remind == PlaceRemind.everyTime ? l10n.placeFormEveryTimeHint : null,
                    trailing: SizedBox(
                      width: 176,
                      child: SegmentedPills<PlaceRemind>(
                        items: [
                          (value: PlaceRemind.firstTime, label: l10n.placeFormFirstTime, dot: null),
                          (value: PlaceRemind.everyTime, label: l10n.placeFormEveryTime, dot: null),
                        ],
                        selected: _remind,
                        onChanged: (v) => setState(() => _remind = v),
                      ),
                    ),
                  ),
                  if (widget.editing != null)
                    SwitchRow(
                      icon: AppIcons.pause,
                      color: c.grey,
                      label: l10n.placeFormPaused,
                      value: _paused,
                      onChanged: (v) => setState(() => _paused = v),
                    ),
                ],
              ),
              if (place != null && (_arrive || _leave))
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.xxxl, Space.s, Space.l, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(AppIcons.place, size: 14, color: c.textSecondary),
                      ),
                      const SizedBox(width: Space.xs + 2),
                      Expanded(child: Text(f.placeSummary(draft, place, today: today), style: text.bodySmall)),
                    ],
                  ),
                ),
              const SizedBox(height: Space.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.l),
                child: SegmentedPills<ReminderContext>(
                  items: [for (final x in ReminderContext.values) (value: x, label: f.context(x), dot: null)],
                  selected: _context,
                  onChanged: (x) => setState(() => _context = x),
                ),
              ),
              GroupCaption(l10n.attachTitle),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.l),
                child: AttachmentsEditor(
                  notes: _notes,
                  attachments: _attachments,
                  onChanged: (v) => setState(() => _attachments = v),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// LOC-5 hours: Any time · Between, with From / To.
class _HoursSheet extends StatefulWidget {
  const _HoursSheet({required this.from, required this.to, required this.l10n});
  final ClockTime? from;
  final ClockTime? to;
  final AppLocalizations l10n;

  @override
  State<_HoursSheet> createState() => _HoursSheetState();
}

class _HoursSheetState extends State<_HoursSheet> {
  late bool _between = widget.from != null;
  late ClockTime _from = widget.from ?? const ClockTime(9, 0);
  late ClockTime _to = widget.to ?? const ClockTime(17, 0);

  Future<void> _pick(bool from) async {
    final current = from ? _from : _to;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: current.hour, minute: current.minute));
    if (t == null || !mounted) return;
    setState(() => from ? _from = ClockTime(t.hour, t.minute) : _to = ClockTime(t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    String time(ClockTime t) => f.time(DateTime.utc(2000, 1, 1, t.hour, t.minute));
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            child: SheetBar(
              title: l10n.placeFormHours,
              left: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
              right: FilledButton(
                onPressed: () => Navigator.pop(context, (from: _between ? _from : null, to: _between ? _to : null)),
                child: Text(l10n.actionDone),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
            child: SegmentedPills<bool>(
              items: [
                (value: false, label: l10n.placeHoursAny, dot: null),
                (value: true, label: l10n.placeHoursBetween, dot: null),
              ],
              selected: _between,
              onChanged: (v) => setState(() => _between = v),
            ),
          ),
          if (_between) ...[
            const SizedBox(height: Space.s),
            InsetGroup(
              children: [
                FormRow(icon: AppIcons.time, color: c.accent, label: l10n.placeFormFrom, value: time(_from), onTap: () => _pick(true)),
                FormRow(icon: AppIcons.endTime, color: c.accent, label: l10n.placeFormTo, value: time(_to), onTap: () => _pick(false)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
