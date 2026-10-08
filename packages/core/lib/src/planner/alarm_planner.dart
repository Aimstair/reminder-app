/// Alert planning (ALR-*, SCH-*): turns reminders + saved occurrences into the alarm set for the
/// next 14 days. The app hands the result to the native AlarmScheduler via `sync` (SCH-4).
library;

import 'dart:math' as math;

import '../engine/occurrence_engine.dart';
import '../model/alert.dart';
import '../model/enums.dart';
import '../model/prefs.dart';
import '../model/reminder.dart';
import '../recurrence/recurrence.dart';
import '../time/calendar.dart';
import '../time/zones.dart';

/// One alarm for the native side. [key] = `occurrence_id:stage:nag_seq` (SCH-4).
class PlannedAlarm {
  const PlannedAlarm({
    required this.key,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.kind,
    required this.lateCutoff,
  });

  final String key;

  /// Instant (UTC).
  final DateTime fireAt;
  final String title;
  final String body;

  /// Notification buttons (NTF-2): task | occasion_prep | occasion_day | meeting
  final String kind;
  final Duration lateCutoff;

  @override
  String toString() => '$key @ ${fireAt.toIso8601String()} [$kind] $title — $body';
}

enum AlertKind { stage, anchorFallback, snooze, nag }

/// Everything a text builder needs to word a notification (NTF-1, copy.md §2).
class AlertContext {
  const AlertContext({
    required this.reminder,
    required this.times,
    required this.fireAt,
    required this.alertKind,
    this.stage,
  });

  final Reminder reminder;
  final OccurrenceTimes times;
  final DateTime fireAt;
  final AlertKind alertKind;
  final AlertStage? stage;
}

typedef AlertTextBuilder = ({String title, String body}) Function(AlertContext context);

class AlarmPlanner {
  AlarmPlanner({
    required this.prefs,
    required this.text,
    this.window = const Duration(days: 14), // SCH-2
    this.cap = 400, // SCH-3
  });

  final UserPrefs prefs;
  final AlertTextBuilder text;
  final Duration window;
  final int cap;

  /// ALR-13: nagging stops after this long.
  static const nagLimit = Duration(days: 3);

  /// Stable id of an occurrence (no ':' — the native side splits keys on it).
  static String occurrenceId(String reminderId, DateTime start) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$reminderId~${start.year}${two(start.month)}${two(start.day)}${two(start.hour)}${two(start.minute)}';
  }

  /// [saved] = occurrences stored in app.db, keyed by [occurrenceId].
  List<PlannedAlarm> plan(List<Reminder> reminders, Map<String, Occurrence> saved, DateTime now) {
    final out = <PlannedAlarm>[];
    final horizon = now.add(window);
    for (final r in reminders) {
      if (r.meta.isDeleted || r.status != ReminderStatus.active) continue;
      for (final start in _starts(r, now)) {
        final id = occurrenceId(r.id, start);
        out.addAll(_forOccurrence(r, id, start, saved[id], now, horizon));
      }
    }
    out.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return out.length > cap ? out.sublist(0, cap) : out; // SCH-3: earliest first
  }

  /// Occurrence starts whose alerts could fall in the window.
  Iterable<DateTime> _starts(Reminder r, DateTime now) {
    final zone = r.timing.type == TimingType.date ? prefs.deviceTimeZone : (r.timing.timeZone ?? prefs.defaultTimeZone);
    final nowWall = instantToWall(now, zone);
    final lead = _maxLead(r.alertPlan);
    final lookBack = (r.nagInterval != null ? nagLimit : Duration.zero) + const Duration(days: 2);
    final from = nowWall.subtract(lookBack);
    final to = nowWall.add(window + lead + const Duration(days: 1));

    // REC-6: after-completion reminders keep timing.start at the current due date (the app moves it
    // when an occurrence is completed), so they plan like one-time reminders.
    if (r.rrule == null || r.repeatMode == RecurrenceMode.afterCompletion) {
      final s = r.timing.start;
      return (s.isBefore(from) && r.nagInterval == null) || s.isAfter(to) ? const [] : [s];
    }
    return RecurrenceRule.parse(r.rrule!).expand(r.timing.start, from: from, to: to);
  }

  static Duration _maxLead(List<AlertStage> plan) {
    var lead = Duration.zero;
    for (final s in plan) {
      if (s.offset.amount >= 0) continue;
      final n = -s.offset.amount;
      final d = switch (s.offset.unit) {
        OffsetUnit.minutes => Duration(minutes: n),
        OffsetUnit.hours => Duration(hours: n),
        OffsetUnit.days => Duration(days: n),
        OffsetUnit.weeks => Duration(days: 7 * n),
        OffsetUnit.months => Duration(days: 31 * n),
      };
      if (d > lead) lead = d;
    }
    return lead;
  }

  List<PlannedAlarm> _forOccurrence(
    Reminder r,
    String occId,
    DateTime seriesStart,
    Occurrence? occ,
    DateTime now,
    DateTime horizon,
  ) {
    final state = occ?.state ?? OccurrenceState.pending;
    if (state.isResolved) return const []; // OCC-4
    final start = occ?.overrideStart ?? seriesStart; // REC-12
    final times = OccurrenceTimes.of(r, start, prefs, overrideEnd: occ?.overrideEnd);
    final sent = occ?.alertsSent ?? const <String>{};
    final cutoff = prefs.lateAlertCutoff ?? const Duration(days: 3650);

    var stages = occ?.overrideAlertPlan ?? r.alertPlan;
    if (state == OccurrenceState.prepared) stages = stages.where((s) => !s.isPrep).toList(); // OCC-3

    final out = <PlannedAlarm>[];
    PlannedAlarm make(String key, DateTime at, AlertKind ak, {AlertStage? stage}) {
      final t = text(AlertContext(reminder: r, times: times, fireAt: at, alertKind: ak, stage: stage));
      return PlannedAlarm(
        key: key,
        fireAt: at,
        title: t.title,
        body: t.body,
        kind: _buttons(r.kind, stage, ak),
        lateCutoff: cutoff,
      );
    }

    bool inWindow(DateTime at) => at.isAfter(now) && !at.isAfter(horizon);

    final fires = <DateTime>[];
    for (var i = 0; i < stages.length; i++) {
      final at = _fireTime(r, times, stages[i]);
      fires.add(at);
      final key = '$occId:$i:0';
      if (inWindow(at) && !sent.contains(key)) out.add(make(key, at, AlertKind.stage, stage: stages[i]));
    }

    // ALR-6: every stage was already past when the reminder (or this occurrence) was last saved, and
    // the occurrence is still ahead → one alert at the anchor. Stages that passed after saving have
    // fired (or were missed) — no fallback then, or every alert would ring twice.
    final edited = occ != null && (occ.overrideStart != null || occ.overrideAlertPlan != null);
    final savedAt = edited && occ.meta.updatedAt.isAfter(r.meta.updatedAt) ? occ.meta.updatedAt : r.meta.updatedAt;
    if (stages.isNotEmpty &&
        fires.every((f) => !f.isAfter(savedAt) && !f.isAfter(now)) &&
        times.anchor.isAfter(now)) {
      final key = '$occId:anchor:0';
      if (inWindow(times.anchor) && !sent.contains(key)) out.add(make(key, times.anchor, AlertKind.anchorFallback));
    }

    // NTF-4 / NTF-5: a snoozed alert re-fires at snoozedUntil.
    final snoozed = occ?.snoozedUntil;
    if (state == OccurrenceState.snoozed && snoozed != null) {
      final key = '$occId:snz${snoozed.millisecondsSinceEpoch}:0';
      if (inWindow(snoozed) && !sent.contains(key)) out.add(make(key, snoozed, AlertKind.snooze));
    }

    // ALR-9…13: nag until done, after the last stage, inside nag hours, for at most 3 days.
    final nag = r.nagInterval;
    if (nag != null && r.completable && state != OccurrenceState.prepared) {
      final last = fires.isEmpty ? times.anchor : fires.reduce((a, b) => a.isAfter(b) ? a : b);
      final stop = last.add(nagLimit);
      var t = last;
      for (var k = 1; k <= 200; k++) {
        t = _intoNagHours(t.add(nag));
        if (t.isAfter(stop) || t.isAfter(horizon)) break;
        final key = '$occId:nag:$k';
        if (inWindow(t) && !sent.contains(key) && (snoozed == null || !t.isBefore(snoozed))) {
          out.add(make(key, t, AlertKind.nag));
        }
      }
    }
    return out;
  }

  /// ALR-2/ALR-3: minutes/hours add to the instant; days/weeks/months move the wall date, keeping the time.
  DateTime _fireTime(Reminder r, OccurrenceTimes times, AlertStage s) {
    final o = s.offset;
    switch (o.unit) {
      case OffsetUnit.minutes:
        return times.anchor.add(Duration(minutes: o.amount));
      case OffsetUnit.hours:
        return times.anchor.add(Duration(hours: o.amount));
      case OffsetUnit.days:
      case OffsetUnit.weeks:
      case OffsetUnit.months:
        final zone = r.timing.type == TimingType.date
            ? prefs.deviceTimeZone
            : (r.timing.timeZone ?? prefs.defaultTimeZone);
        final anchorWall = instantToWall(times.anchor, zone);
        final wall = switch (o.unit) {
          OffsetUnit.days => addDays(anchorWall, o.amount),
          OffsetUnit.weeks => addDays(anchorWall, 7 * o.amount),
          _ => addMonths(anchorWall, o.amount),
        };
        return wallToInstant(wall, zone);
    }
  }

  /// ALR-11: outside nag hours → move to the next window start (device local time).
  DateTime _intoNagHours(DateTime t) {
    final zone = prefs.deviceTimeZone;
    final wall = instantToWall(t, zone);
    final minutes = wall.hour * 60 + wall.minute;
    final startM = prefs.nagStart.minutes, endM = prefs.nagEnd.minutes;
    if (minutes < startM) {
      return wallToInstant(DateTime.utc(wall.year, wall.month, wall.day).add(Duration(minutes: startM)), zone);
    }
    if (minutes > endM) {
      final next = addDays(DateTime.utc(wall.year, wall.month, wall.day), 1);
      return wallToInstant(next.add(Duration(minutes: startM)), zone);
    }
    return t;
  }

  /// NTF-2: which buttons the notification gets.
  static String _buttons(Kind kind, AlertStage? stage, AlertKind ak) => switch (kind) {
    Kind.meeting || Kind.event => 'meeting',
    Kind.occasion => (stage?.isPrep ?? false) ? 'occasion_prep' : 'occasion_day',
    Kind.task => 'task',
  };
}

/// Smallest gap between consecutive alarms — handy for diagnostics.
Duration? minGap(List<PlannedAlarm> alarms) {
  Duration? best;
  for (var i = 1; i < alarms.length; i++) {
    final g = alarms[i].fireAt.difference(alarms[i - 1].fireAt);
    best = best == null ? g : Duration(microseconds: math.min(best.inMicroseconds, g.inMicroseconds));
  }
  return best;
}
