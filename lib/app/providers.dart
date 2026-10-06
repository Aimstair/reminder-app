/// Riverpod providers: the UI reads state here; data lives in SQLite (architecture.md §3).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import 'app_services.dart';

/// Overridden in main() with the started services.
final servicesProvider = Provider<AppServices>((ref) => throw UnimplementedError('servicesProvider not overridden'));

/// Current settings. Invalidate after changing a pref.
final prefsProvider = Provider<UserPrefs>((ref) => ref.watch(servicesProvider).prefs.current);

/// "Now", ticking every minute so groups and overdue states roll over on screen. Invalidate on resume.
final nowProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now().toUtc();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now().toUtc());
});

final remindersProvider = StreamProvider<List<Reminder>>(
  (ref) => ref.watch(servicesProvider).reminders.watchActive(),
);

final occurrencesProvider = StreamProvider<Map<String, Occurrence>>(
  (ref) => ref.watch(servicesProvider).occurrences.watchByPlannerId(),
);

/// Schedule view (S-12) items; null while loading.
final scheduleProvider = Provider<List<ScheduleItem>?>((ref) {
  final reminders = ref.watch(remindersProvider).value;
  final saved = ref.watch(occurrencesProvider).value;
  final now = ref.watch(nowProvider).value;
  if (reminders == null || saved == null || now == null) return null;
  return ScheduleView(prefs: ref.watch(prefsProvider)).build(reminders, saved, now);
});

/// Daily progress ring ("2/6 done"): occurrences completed today vs. today's total.
final todayProgressProvider = Provider<({int done, int total})>((ref) {
  final items = ref.watch(scheduleProvider) ?? const [];
  final saved = ref.watch(occurrencesProvider).value ?? const {};
  final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();
  final zone = ref.watch(prefsProvider).deviceTimeZone;
  final today = dateOnly(instantToWall(now, zone));
  final done = saved.values
      .where((o) =>
          o.state == OccurrenceState.done &&
          o.resolvedAt != null &&
          dateOnly(instantToWall(o.resolvedAt!, zone)) == today)
      .length;
  final open = items.where((i) => i.group == ScheduleGroup.today || i.group == ScheduleGroup.overdue).length;
  return (done: done, total: done + open);
});
