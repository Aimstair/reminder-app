/// S-22 Full editor: type badge, title, date/time/end, zone, type, context, repeat, alerts, nag until
/// done, and notes, links & files (ATT-1).
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
import '../../native/platform_gateway.dart';
import '../../ui/art.dart';
import '../../ui/motion.dart';
import '../actions/occurrence_actions.dart';
import '../attachments/attachments.dart';
import '../pickers/pickers.dart';
import '../../ui/icons.dart';

/// Opens the editor for occurrence [key] of [r] and saves the result.
Future<void> openEditor(BuildContext context, WidgetRef ref, Reminder r, DateTime key) async {
  final edited = await Navigator.of(context).push<Reminder>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => EditorPage(reminder: r, occurrenceKey: key),
    ),
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
      e = e.copyWith(
        source: ContactSource(contactId: s0.contactId, field: s0.field, userEditedDate: true),
      ); // CON-6
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
  late BillKind _billKind = widget.reminder.billKind; // BIL-1
  late SubKind? _sub = widget.reminder.subKind; // SUB-1
  late Money? _amount = widget.reminder.amount; // BIL-2
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
  late List<Attachment> _attachments = widget.reminder.attachments;
  late final PlatformGateway? _platform = ref.read(servicesProvider).platform;
  bool _saved = false;

  @override
  void dispose() {
    // ATT-6: files picked here but not saved. Removed files stay on disk: a split series may share them.
    if (!_saved) {
      for (final a in _attachments) {
        if (a.kind == AttachmentKind.file && !widget.reminder.attachments.contains(a)) {
          _platform?.deleteAttachment(a).catchError((_) {});
        }
      }
    }
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _completable => _kind == Kind.task || _kind == Kind.occasion || _kind == Kind.bill;

  /// Nagging fits payments, not subscriptions or trials (BIL-3).
  bool get _canNag => _completable && !(_kind == Kind.bill && _billKind != BillKind.payment);

  Reminder _build() {
    final start = _allDay ? dateOnly(_start) : _start;
    final end = _allDay || _end == null || !_end!.isAfter(start) ? null : _end;
    return widget.reminder.copyWith(
      title: _title.text.trim(),
      notes: () => _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      attachments: _attachments,
      amount: () => _kind == Kind.bill ? _amount : null,
      billKind: _billKind,
      subKind: () => _sub?.kind == _kind ? _sub : null,
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
      nagInterval: () => _canNag ? _nag : null, // ALR-9
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
            onPressed: valid
                ? () {
                    _saved = true;
                    Navigator.pop(context, _build());
                  }
                : null,
            child: Text(l10n.actionSave, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xxxl),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: Space.s, bottom: Space.l),
                child: AnimatedSwitcher(
                  duration: reduceMotion(context) ? Duration.zero : Motion.standard,
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                  child: GlyphBadge(
                    key: ValueKey((_kind, _sub)),
                    icon: SubKind.of(_kind).isEmpty
                        ? kindIcon(_kind)
                        : subKindIcon(_sub?.kind == _kind ? _sub : null, _kind),
                    color: c.kind(_kind),
                    size: 64,
                  ),
                ),
              ),
            ),
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
                    final v = await pickRepeat(
                      context,
                      current: _rrule,
                      mode: _mode,
                      start: _start,
                      completable: _completable,
                    );
                    if (v != null) setState(() => (_rrule = v.rrule, _mode = v.mode));
                  },
                ),
                FormRow(
                  icon: AppIcons.alerts,
                  color: c.warning,
                  label: l10n.rowAlerts,
                  value: f.alerts(_alerts, allDay: _allDay),
                  onTap: () async {
                    final v = await pickAlerts(context, _alerts);
                    if (v != null) setState(() => _alerts = v);
                  },
                ),
                if (_canNag)
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
              child: SegmentedPills<Kind>(
                items: [for (final k in Kind.values) (value: k, label: f.kind(k), dot: c.kind(k))],
                selected: _kind,
                onChanged: (k) => setState(() {
                  _kind = k;
                  // SUB-1: a subtype that doesn't fit the new type gives way to a fresh guess (SUB-2).
                  if (_sub?.kind != k) _sub = guessSubKind(k, _title.text);
                }),
              ),
            ),
            AnimatedSize(
              duration: Motion.standard,
              curve: Curves.easeOutCubic,
              child: SubKind.of(_kind).isEmpty
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
                      child: SubKindChips(
                        key: ValueKey(_kind),
                        kind: _kind,
                        selected: _sub?.kind == _kind ? _sub : null,
                        onChanged: (s) => setState(() => _sub = s),
                      ),
                    ),
            ),
            // BIL-1 / BIL-2: bill kind and amount.
            AnimatedSize(
              duration: Motion.standard,
              curve: Curves.easeOutCubic,
              child: _kind != Kind.bill
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      children: [
                        const SizedBox(height: Space.m),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Space.l),
                          child: SegmentedPills<BillKind>(
                            items: [for (final b in BillKind.values) (value: b, label: f.billKind(b), dot: null)],
                            selected: _billKind,
                            onChanged: (b) => setState(() => _billKind = b),
                          ),
                        ),
                        const SizedBox(height: Space.m),
                        InsetGroup(
                          indent: 56,
                          children: [
                            FormRow(
                              icon: AppIcons.bill,
                              color: c.bill,
                              label: l10n.rowAmount,
                              value: _amount == null ? l10n.amountAdd : f.money(_amount!),
                              onTap: () async {
                                final v = await pickAmount(context, _amount);
                                if (v != null) setState(() => _amount = v.amount);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: Space.m),
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
    );
  }
}
