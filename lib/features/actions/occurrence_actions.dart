/// Actions on one occurrence, shared by Schedule, Day, Month and detail (S-30, S-33, S-34):
/// Done / I'm prepared / Skip with Undo (OCC-5), Reschedule sheet, scope dialogs, delete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/app_services.dart';
import '../../app/providers.dart';
import '../../app/router.dart' show rootNavigatorKey;
import '../../data/prefs_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../native/alarm_gateway.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../celebrate/all_clear_page.dart';
import '../celebrate/celebration.dart';
import '../../ui/icons.dart';

/// Route to an occurrence's detail screen (S-30 / S-31).
String detailPath(String reminderId, DateTime occurrenceKey) =>
    '/item/${Uri.encodeComponent(reminderId)}/${formatWallDateTime(occurrenceKey).replaceAll(RegExp(r'[-T:]'), '')}';

void openDetail(BuildContext context, Reminder r, DateTime occurrenceKey) =>
    context.push(detailPath(r.id, occurrenceKey));

class OccurrenceActions {
  OccurrenceActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  AppLocalizations get l10n => AppLocalizations.of(context);

  /// Done (Task, Occasion) with sound, haptic, celebration and Undo.
  Future<void> done(Reminder r, DateTime key) async {
    final s = ref.read(servicesProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = this.l10n;
    final f = Fmt.of(context);
    final wasLastToday = _isLastOpenToday(r, key);
    final before = await s.service.act(r.id, key, JournalActionType.done);
    s.feedback.done(sound: s.prefs.current.completionSounds);

    // Copy (copy.md §7): repeat-after-completion shows the next date; occasions get a warm line.
    var message = l10n.snackDone;
    if (r.repeatMode == RecurrenceMode.afterCompletion && r.rrule != null) {
      final next = await s.reminders.byId(r.id);
      if (next != null) message = l10n.snackNext(f.date(next.timing.start));
    } else if (r.kind == Kind.occasion) {
      message = l10n.occasionDone;
    }
    // Celebrate first, then offer Undo: a celebration on top of the snackbar would hide Undo
    // until its 5 seconds were gone (OCC-5). Shown from the root navigator — a swiped row is
    // already gone from the list by now.
    final host = rootNavigatorKey.currentContext;
    if (host != null && host.mounted) {
      if (!s.prefs.flag(PrefKeys.firstDoneShown)) {
        await s.prefs.set(PrefKeys.firstDoneShown, true);
        if (host.mounted) await showCelebration(host, Celebration.firstDone);
      } else if (wasLastToday) {
        await showAllClear(host); // DS12: full screen
      }
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5), // OCC-5
        persist: false,
        action: SnackBarAction(
          label: l10n.actionUndo,
          onPressed: () => _undo(s, r, key, before),
        ),
      ));
  }

  // Takes the services captured when the action ran: Undo fires after a swiped row (and its ref)
  // is gone, so it must not read providers itself.
  Future<void> _undo(AppServices s, Reminder r, DateTime key, OccurrenceState before) async {
    if (r.repeatMode == RecurrenceMode.afterCompletion && r.rrule != null) {
      // REC-6 moved the series; put the start back too.
      await s.service.edit(r);
    }
    await s.service.setState(r.id, key, before);
  }

  bool _isLastOpenToday(Reminder r, DateTime key) {
    final items = ref.read(scheduleProvider) ?? const [];
    final today = items
        .where((i) => i.reminder.completable)
        .where((i) => i.group == ScheduleGroup.today || i.group == ScheduleGroup.overdue)
        .toList();
    return today.length == 1 && today.single.reminder.id == r.id && today.single.occurrenceKey == key;
  }

  Future<void> prepared(Reminder r, DateTime key) async {
    final s = ref.read(servicesProvider);
    final before = await s.service.act(r.id, key, JournalActionType.prepared);
    s.feedback.tap();
    if (context.mounted) {
      showUndoSnack(context, l10n.snackPrepared, undoLabel: l10n.actionUndo,
          onUndo: () => s.service.setState(r.id, key, before));
    }
  }

  Future<void> skip(Reminder r, DateTime key) async {
    final s = ref.read(servicesProvider);
    final before = await s.service.act(r.id, key, JournalActionType.skip);
    if (!context.mounted) return;
    var message = l10n.snackSkipped;
    if (r.repeatMode == RecurrenceMode.afterCompletion && r.rrule != null) {
      final next = await s.reminders.byId(r.id);
      if (next != null && context.mounted) message = l10n.snackSkippedNext(Fmt.of(context).date(next.timing.start));
    }
    if (context.mounted) {
      showUndoSnack(context, message, undoLabel: l10n.actionUndo, onUndo: () => _undo(s, r, key, before));
    }
  }

  /// S-33 Reschedule sheet (NTF-7).
  Future<void> reschedule(Reminder r, DateTime key, {DateTime? currentStart}) async {
    final s = ref.read(servicesProvider);
    final prefs = s.prefs.current;
    final zone = r.timing.type == TimingType.date ? prefs.deviceTimeZone : (r.timing.timeZone ?? prefs.defaultTimeZone);
    final nowWall = instantToWall(DateTime.now().toUtc(), zone);
    final start = currentStart ?? key;
    final keepTime = r.timing.type == TimingType.datetime;
    DateTime at(DateTime day, int h, int m) => DateTime.utc(day.year, day.month, day.day, h, m);
    final today = dateOnly(nowWall);
    final laterToday = nowWall.add(const Duration(hours: 3));
    final options = <(String, IconData, DateTime)>[
      if (laterToday.day == nowWall.day) (l10n.reschedLaterToday, AppIcons.time, at(today, laterToday.hour, 0)),
      if (nowWall.hour < 18) (l10n.reschedEvening, AppIcons.evening, at(today, 19, 0)),
      (l10n.reschedTomorrow, AppIcons.day,
          keepTime ? at(addDays(today, 1), start.hour, start.minute) : at(addDays(today, 1), prefs.dayTime.hour, prefs.dayTime.minute)),
      (l10n.reschedNextWeek, AppIcons.nextWeek,
          keepTime ? at(addDays(today, 7), start.hour, start.minute) : at(addDays(today, 7), prefs.dayTime.hour, 0)),
    ];
    final chosen = await showAppSheet<DateTime>(context, (ctx) {
      final c = AppColors.of(ctx);
      final f = Fmt.of(ctx);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.rescheduleTitle, style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: Space.m),
          InsetGroup(
            indent: 56,
            color: c.bgGrouped,
            children: [
              for (final (label, icon, slot) in options)
                FormRow(
                  label: label,
                  icon: icon,
                  color: c.accent,
                  value: r.timing.type == TimingType.date ? f.date(slot) : '${f.weekdayShort(slot)} ${f.time(slot)}',
                  onTap: () => Navigator.pop(ctx, slot),
                ),
              FormRow(
                label: l10n.reschedPick,
                icon: AppIcons.pickDate,
                color: c.meeting,
                onTap: () async {
                  final picked = await pickDateTime(ctx, start, withTime: keepTime);
                  if (picked != null && ctx.mounted) Navigator.pop(ctx, picked);
                },
              ),
            ],
          ),
          const SizedBox(height: Space.l),
        ],
      );
    });
    if (chosen == null) return;
    // Keep the original for Undo.
    final original = await s.reminders.byId(r.id);
    final originalOcc = await s.occurrences.find(r.id, key);
    await s.service.reschedule(r, key, chosen);
    if (!context.mounted) return;
    final f = Fmt.of(context);
    showUndoSnack(
      context,
      l10n.snackRescheduled(keepTime ? f.when(chosen, allDay: false) : f.date(chosen)),
      undoLabel: l10n.actionUndo,
      onUndo: () async {
        if (original != null && (r.rrule == null || r.repeatMode == RecurrenceMode.afterCompletion)) {
          await s.service.edit(original);
        } else {
          await s.occurrences.save(
            reminderId: r.id,
            occurrenceKey: key,
            state: originalOcc?.state ?? OccurrenceState.pending,
            clearOverrides: originalOcc?.overrideStart == null,
            overrideStart: originalOcc?.overrideStart,
            overrideEnd: originalOcc?.overrideEnd,
          );
          await s.service.resync();
        }
      },
    );
  }

  /// REC-15 / DAT-1: delete with scope for repeating reminders, then Undo.
  Future<bool> delete(Reminder r, DateTime key) async {
    final s = ref.read(servicesProvider);
    var scope = EditScope.all;
    if (r.rrule != null && r.repeatMode == RecurrenceMode.fixed) {
      final picked = await askScope(context, delete: true);
      if (picked == null) return false;
      scope = picked;
    }
    await s.service.deleteScoped(r, key, scope);
    if (context.mounted) {
      showUndoSnack(
        context,
        scope == EditScope.thisOne ? l10n.snackSkipped : l10n.snackDeleted,
        undoLabel: l10n.actionUndo,
        onUndo: () => scope == EditScope.thisOne
            ? s.service.setState(r.id, key, OccurrenceState.pending)
            : s.service.restore(r.id),
      );
    }
    return true;
  }
}

/// S-34 scope dialog: edit → This one / This and future; delete → This one / All.
Future<EditScope?> askScope(BuildContext context, {required bool delete}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<EditScope>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(delete ? l10n.scopeDeleteTitle : l10n.scopeEditTitle),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, EditScope.thisOne),
          child: Padding(padding: const EdgeInsets.symmetric(vertical: Space.s), child: Text(l10n.scopeThisOne)),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, delete ? EditScope.all : EditScope.thisAndFuture),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.s),
            child: Text(delete ? l10n.scopeAll : l10n.scopeThisAndFuture),
          ),
        ),
      ],
    ),
  );
}

/// Material date (+ time) picker returning a wall time.
Future<DateTime?> pickDateTime(BuildContext context, DateTime initial, {required bool withTime}) async {
  final d = await showDatePicker(
    context: context,
    initialDate: DateTime(initial.year, initial.month, initial.day),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (d == null || !context.mounted) return null;
  if (!withTime) return DateTime.utc(d.year, d.month, d.day);
  final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute));
  if (t == null) return null;
  return DateTime.utc(d.year, d.month, d.day, t.hour, t.minute);
}
