/// Riverpod providers: the UI reads state here; data lives in SQLite (architecture.md §3).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../data/prefs_repository.dart';
import '../native/alarm_gateway.dart';
import 'app_services.dart';

/// Overridden in main() with the started services.
final servicesProvider = Provider<AppServices>((ref) => throw UnimplementedError('servicesProvider not overridden'));

/// Ticks whenever a setting changes.
final prefsTickProvider = StreamProvider<int>((ref) async* {
  var n = 0;
  yield n;
  await for (final _ in ref.watch(servicesProvider).prefs.changes) {
    yield ++n;
  }
});

/// Current settings (rebuilds on change).
final prefsProvider = Provider<UserPrefs>((ref) {
  ref.watch(prefsTickProvider);
  return ref.watch(servicesProvider).prefs.current;
});

/// Raw settings, rebuilt on change (for flags the core prefs don't model). A fresh [PrefsView] per
/// change: returning the repository itself would be the same object every time, and Riverpod skips
/// notifying when the value is identical, so filters and toggles never updated on screen.
final prefsRepoProvider = Provider<PrefsView>((ref) {
  ref.watch(prefsTickProvider);
  return PrefsView(ref.watch(servicesProvider).prefs);
});

/// Snapshot handle on [PrefsRepository]; [set] writes through.
class PrefsView {
  PrefsView(this._repo);
  final PrefsRepository _repo;

  bool flag(String key, {bool fallback = false}) => _repo.flag(key, fallback: fallback);
  String? string(String key) => _repo.string(key);
  Set<String> stringSet(String key) => _repo.stringSet(key);
  Future<void> set(String key, Object? value) => _repo.set(key, value);
}

/// "Now", ticking every minute so groups and overdue states roll over on screen. Invalidate on resume.
final nowProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now().toUtc();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now().toUtc());
});

/// Today in the device zone (wall date).
final todayProvider = Provider<DateTime>((ref) {
  final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();
  return dateOnly(instantToWall(now, ref.watch(prefsProvider).deviceTimeZone));
});

final manualRemindersProvider = StreamProvider<List<Reminder>>(
  (ref) => ref.watch(servicesProvider).reminders.watchActive(),
);

/// Active + archived (search S-40, Completed S-42).
final allRemindersProvider = StreamProvider<List<Reminder>>((ref) => ref.watch(servicesProvider).reminders.watchAll());

/// Imported calendar events (CAL-*), in memory.
final calendarRemindersProvider = StreamProvider<List<Reminder>>((ref) async* {
  final cal = ref.watch(servicesProvider).calendar;
  yield cal.reminders;
  yield* cal.changes;
});

final occurrencesProvider = StreamProvider<Map<String, Occurrence>>(
  (ref) => ref.watch(servicesProvider).occurrences.watchByPlannerId(),
);

/// VW-2: drawer filters, applied to every view.
class Filters {
  const Filters({this.hiddenKinds = const {}, this.hiddenContexts = const {}, this.hiddenCalendars = const {}});
  final Set<String> hiddenKinds;
  final Set<String> hiddenContexts;
  final Set<String> hiddenCalendars;

  bool get active => hiddenKinds.isNotEmpty || hiddenContexts.isNotEmpty || hiddenCalendars.isNotEmpty;

  bool shows(Reminder r) {
    if (hiddenKinds.contains(r.kind.name) || hiddenContexts.contains(r.context.name)) return false;
    final s = r.source;
    return !(s is DeviceCalendarSource && hiddenCalendars.contains(s.calendarId));
  }
}

final filtersProvider = Provider<Filters>((ref) {
  final p = ref.watch(prefsRepoProvider);
  return Filters(
    hiddenKinds: p.stringSet(PrefKeys.hiddenKinds),
    hiddenContexts: p.stringSet(PrefKeys.hiddenContexts),
    hiddenCalendars: p.stringSet(PrefKeys.hiddenCalendars),
  );
});

/// Everything the views show: manual reminders + calendar events, filtered (VW-2). Null while loading.
final remindersProvider = Provider<List<Reminder>?>((ref) {
  final manual = ref.watch(manualRemindersProvider).value;
  if (manual == null) return null;
  final cal = ref.watch(calendarRemindersProvider).value ?? const [];
  final f = ref.watch(filtersProvider);
  return [...manual, ...cal].where(f.shows).toList();
});

/// Schedule view (S-12) items; null while loading.
final scheduleProvider = Provider<List<ScheduleItem>?>((ref) {
  final reminders = ref.watch(remindersProvider);
  final saved = ref.watch(occurrencesProvider).value;
  final now = ref.watch(nowProvider).value;
  if (reminders == null || saved == null || now == null) return null;
  return ScheduleView(prefs: ref.watch(prefsProvider)).build(reminders, saved, now);
});

/// Day / Month data (S-13, S-14) for an inclusive day range.
final rangeProvider = Provider.family<List<DayItem>?, ({DateTime from, DateTime to})>((ref, range) {
  final reminders = ref.watch(remindersProvider);
  final saved = ref.watch(occurrencesProvider).value;
  final now = ref.watch(nowProvider).value;
  if (reminders == null || saved == null || now == null) return null;
  return RangeView(prefs: ref.watch(prefsProvider)).build(reminders, saved, range.from, range.to, now);
});

/// Daily progress ring ("2/6 done"): tasks and occasions completed today vs. today's total.
final todayProgressProvider = Provider<({int done, int total})>((ref) {
  final items = ref.watch(scheduleProvider) ?? const [];
  final saved = ref.watch(occurrencesProvider).value ?? const {};
  final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();
  final zone = ref.watch(prefsProvider).deviceTimeZone;
  final today = dateOnly(instantToWall(now, zone));
  final done = saved.values
      .where(
        (o) =>
            o.state == OccurrenceState.done &&
            o.resolvedAt != null &&
            dateOnly(instantToWall(o.resolvedAt!, zone)) == today,
      )
      .length;
  // Only things you can complete (tasks, occasions); meetings and events just pass.
  final open = items
      .where((i) => i.reminder.completable)
      .where((i) => i.group == ScheduleGroup.today || i.group == ScheduleGroup.overdue)
      .length;
  return (done: done, total: done + open);
});

/// Missed alerts from the native fire log since the start of yesterday (DIG-2 §2).
final missedCountProvider = FutureProvider<int>((ref) async {
  final s = ref.watch(servicesProvider);
  ref.watch(nowProvider);
  try {
    final since = DateTime.now().toUtc().subtract(const Duration(days: 1));
    return (await s.alarms.fireLog(since))
        .where((f) => f.outcome == 'missed' && !f.alarmKey.startsWith('test~'))
        .length;
  } catch (_) {
    return 0;
  }
});

/// S-41 digest card content; null when hidden (before digest time, dismissed, or empty).
final digestProvider = Provider<Digest?>((ref) {
  final reminders = ref.watch(remindersProvider);
  final saved = ref.watch(occurrencesProvider).value;
  final now = ref.watch(nowProvider).value;
  if (reminders == null || saved == null || now == null) return null;
  final prefs = ref.watch(prefsProvider);
  final repo = ref.watch(prefsRepoProvider);
  final dismissed = repo.string(PrefKeys.digestDismissedDay);
  if (!digestVisible(prefs: prefs, now: now, dismissedDay: dismissed == null ? null : parseWall(dismissed))) {
    return null;
  }
  final s = ref.watch(servicesProvider);
  final d = buildDigest(
    reminders: reminders,
    saved: saved,
    prefs: prefs,
    now: now,
    missed: ref.watch(missedCountProvider).value ?? 0,
    removedFromCalendar: s.calendar.removedTitles,
  );
  return d.isEmpty && s.contacts.suggestions.isEmpty ? null : d;
});

/// PRM-5 permission state; refreshed on resume.
class PermissionsNotifier extends Notifier<Permissions> {
  @override
  Permissions build() => ref.watch(servicesProvider).permissions;

  Future<void> refresh() async {
    final s = ref.read(servicesProvider);
    try {
      s.permissions = await s.alarms.permissions();
    } catch (_) {}
    state = s.permissions;
  }
}

final permissionsProvider = NotifierProvider<PermissionsNotifier, Permissions>(PermissionsNotifier.new);

/// Home views (S-12…S-14).
enum HomeView { schedule, day, month }

/// VW-1: last-used view and the date the Day/Month views show.
class HomeState {
  const HomeState({required this.view, required this.date});
  final HomeView view;
  final DateTime date;
  HomeState copyWith({HomeView? view, DateTime? date}) => HomeState(view: view ?? this.view, date: date ?? this.date);
}

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    final p = ref.read(servicesProvider).prefs;
    final start = p.string(PrefKeys.startIn) ?? 'last';
    final name = start == 'last' ? (p.string(PrefKeys.lastView) ?? 'schedule') : start;
    final view = HomeView.values.where((v) => v.name == name).firstOrNull ?? HomeView.schedule;
    return HomeState(view: view, date: ref.read(todayProvider));
  }

  void setView(HomeView v) {
    state = state.copyWith(view: v);
    unawaited(ref.read(servicesProvider).prefs.set(PrefKeys.lastView, v.name));
  }

  void setDate(DateTime d) => state = state.copyWith(date: dateOnly(d));
  void today() => state = state.copyWith(date: ref.read(todayProvider));

  /// Day view for [d] (VW-8: tap a Month day).
  void openDay(DateTime d) {
    setDate(d);
    setView(HomeView.day);
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
