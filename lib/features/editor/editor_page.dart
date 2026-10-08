/// S-22 Full editor: title, notes, date/time/end, zone, type, context, repeat, alerts, nag until done.
/// Saving a repeating reminder asks "This one / This and future" (REC-11, S-34).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../actions/occurrence_actions.dart';
import '../pickers/pickers.dart';
import '../../ui/icons.dart';

/// Opens the editor for occurrence [key] of [r] and saves the result.
Future<void> openEditor(BuildContext context, WidgetRef ref, Reminder r, DateTime key) async {
  final edited = await Navigator.of(context).push<Reminder>(
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => EditorPage(reminder: r, occurrenceKey: key)),
  );
  if (edited == null || !context.mounted) return;
  final s = ref.read(servicesProvider);
  if (r.rrule != null && r.repeatMode == RecurrenceMode.fixed && edited.rrule == r.rrule) {
    final scope = await askScope(context, delete: false);
    if (scope == null) return;
    await s.service.editScoped(r, edited, key, scope);
  } else {
    // One-time, after-completion, or the repeat rule itself changed: the whole reminder.
    var e = edited;
    final s0 = e.source;
    if (s0 is ContactSource && e.timing.start != r.timing.start) {
      e = e.copyWith(source: ContactSource(contactId: s0.contactId, field: s0.field, userEditedDate: true)); // CON-6
    }
    await s.service.edit(e);
  }
}

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key, required this.reminder, required this.occurrenceKey});
  final Reminder reminder;
  final DateTime occurrenceKey;

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  late final _title = TextEditingController(text: widget.reminder.title);
  late final _notes = TextEditingController(text: widget.reminder.notes ?? '');
  late Kind _kind = widget.reminder.kind;
  late ReminderContext _context = widget.reminder.context;
  late bool _allDay = widget.reminder.timing.type == TimingType.date;
  late DateTime _start = widget.reminder.timing.start;
  late DateTime? _end = widget.reminder.timing.end;
  late String _zone = widget.reminder.timing.timeZone ?? ref.read(prefsProvider).defaultTimeZone;
  late bool _zoneManual = widget.reminder.timing.timeZoneSetManually;
  late String? _rrule = widget.reminder.rrule;
  late RecurrenceMode _mode = widget.reminder.repeatMode;
  late List<AlertStage> _alerts = widget.reminder.alertPlan;
  late Duration? _nag = widget.reminder.nagInterval;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _completable => _kind == Kind.task || _kind == Kind.occasion;

  Reminder _build() {
    final start = _allDay ? dateOnly(_start) : _start;
    final end = _allDay || _end == null || !_end!.isAfter(start) ? null : _end;
    return widget.reminder.copyWith(
      title: _title.text.trim(),
      notes: () => _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      kind: _kind,
      context: _context,
      timing: Timing(
        type: _allDay ? TimingType.date : TimingType.datetime,
        start: start,
        end: end,
        timeZone: _allDay ? null : _zone,
        timeZoneSetManually: !_allDay && _zoneManual,
      ),
      alertPlan: _alerts,
      rrule: () => _rrule,
      repeatMode: _completable ? _mode : RecurrenceMode.fixed, // REC-10
      nagInterval: () => _completable ? _nag : null, // ALR-9
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final valid = _title.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 96,
        leading: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
        title: Text(l10n.editorTitle),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: valid ? () => Navigator.pop(context, _build()) : null,
            child: Text(l10n.actionSave, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            const SizedBox(height: Space.s),
            InsetGroup(
              indent: Space.l,
              children: [
                TextField(
                  controller: _title,
                  style: text.bodyLarge,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.fieldTitle,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(Space.l),
                  ),
                ),
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 6,
                  style: text.bodyLarge,
                  decoration: InputDecoration(
                    hintText: l10n.fieldNotes,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(Space.l),
                  ),
                ),
              ],
            ),
            GroupCaption(l10n.detailWhen),
            InsetGroup(
              indent: 56,
              children: [
                SwitchRow(
                  label: l10n.fieldAllDay,
                  icon: AppIcons.day,
                  color: c.event,
                  value: _allDay,
                  onChanged: (v) => setState(() => _allDay = v),
                ),
                FormRow(
                  icon: AppIcons.calendar,
                  color: c.danger,
                  label: l10n.fieldStart,
                  value: _allDay ? f.date(_start) : '${f.date(_start)} · ${f.time(_start)}',
                  onTap: () async {
                    final v = await pickDateTime(context, _start, withTime: !_allDay);
                    if (v == null) return;
                    setState(() {
                      if (_end != null) _end = _end!.add(v.difference(_start));
                      _start = v;
                    });
                  },
                ),
                if (!_allDay) ...[
                  FormRow(
                    icon: AppIcons.endTime,
                    color: c.accent,
                    label: l10n.fieldEnd,
                    value: _end == null ? l10n.noEnd : f.time(_end!),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_end ?? _start.add(const Duration(hours: 1))),
                      );
                      if (t == null) return;
                      setState(() => _end = DateTime.utc(_start.year, _start.month, _start.day, t.hour, t.minute));
                    },
                    trailing: _end == null
                        ? null
                        : IconButton(
                            icon: const Icon(AppIcons.close, size: 18),
                            onPressed: () => setState(() => _end = null),
                          ),
                  ),
                  FormRow(
                    icon: AppIcons.timeZone,
                    color: c.meeting,
                    label: l10n.fieldTimeZone,
                    value: Fmt.city(_zone),
                    onTap: () async {
                      final z = await pickTimeZone(context, _zone);
                      if (z != null) setState(() => (_zone = z, _zoneManual = true));
                    },
                  ),
                ],
              ],
            ),
            GroupCaption(l10n.rowRepeat),
            InsetGroup(
              indent: 56,
              children: [
                FormRow(
                  icon: AppIcons.repeat,
                  color: c.meeting,
                  label: l10n.rowRepeat,
                  value: f.repeat(_rrule, _mode),
                  onTap: () async {
                    final v = await pickRepeat(context, current: _rrule, mode: _mode, start: _start, completable: _completable);
                    if (v != null) setState(() => (_rrule = v.rrule, _mode = v.mode));
                  },
                ),
                FormRow(
                  icon: AppIcons.alerts,
                  color: c.warning,
                  label: l10n.rowAlerts,
                  value: f.alerts(_alerts),
                  onTap: () async {
                    final v = await pickAlerts(context, _alerts);
                    if (v != null) setState(() => _alerts = v);
                  },
                ),
                if (_completable)
                  FormRow(
                    icon: AppIcons.nag,
                    color: c.success,
                    label: l10n.rowNag,
                    value: _nag == null ? l10n.nagOff : l10n.nagEvery(f.duration(_nag!)),
                    onTap: () async {
                      final v = await pickNag(context, _nag);
                      if (v != null) setState(() => _nag = v == Duration.zero ? null : v);
                    },
                  ),
              ],
            ),
            GroupCaption(l10n.fieldType),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: SegmentedButton<Kind>(
                showSelectedIcon: false,
                segments: [for (final k in Kind.values) ButtonSegment(value: k, label: Text(f.kind(k)))],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
            ),
            const SizedBox(height: Space.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: SegmentedButton<ReminderContext>(
                showSelectedIcon: false,
                segments: [
                  for (final x in ReminderContext.values) ButtonSegment(value: x, label: Text(f.context(x))),
                ],
                selected: {_context},
                onSelectionChanged: (s) => setState(() => _context = s.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
