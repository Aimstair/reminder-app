/// S-10 Home shell: top bar (☰ · title → mini month · search · Today · view switcher), banners
/// (G2–G4, G10), the current view, [+]. S-11 drawer: views, filters by type / context / calendar
/// (VW-2), Completed, Settings, Help.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_core/reminder_core.dart';

import '../data/prefs_repository.dart';
import '../features/capture/capture_sheet.dart';
import '../features/day/day_view.dart';
import '../features/month/month_view.dart';
import '../features/schedule/schedule_page.dart';
import '../l10n/gen/app_localizations.dart';
import '../ui/format.dart';
import '../ui/tokens.dart';
import '../ui/widgets.dart';
import 'providers.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.openCapture = false});

  /// FL-1 step 6: open the capture sheet when onboarding saved nothing.
  final bool openCapture;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();

  static IconData viewIcon(HomeView v) => switch (v) {
    HomeView.schedule => Icons.view_agenda_outlined,
    HomeView.day => Icons.view_day_outlined,
    HomeView.month => Icons.calendar_month_outlined,
  };

  static String viewName(AppLocalizations l10n, HomeView v) => switch (v) {
    HomeView.schedule => l10n.viewSchedule,
    HomeView.day => l10n.viewDay,
    HomeView.month => l10n.viewMonth,
  };
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    if (widget.openCapture) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showCaptureSheet(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = Fmt.of(context);
    final home = ref.watch(homeProvider);
    final today = ref.watch(todayProvider);
    final notifier = ref.read(homeProvider.notifier);
    final title = switch (home.view) {
      HomeView.schedule => f.month(today),
      HomeView.day => home.date.year == today.year ? f.month(home.date) : f.monthYear(home.date),
      HomeView.month => home.date.year == today.year ? f.month(home.date) : f.monthYear(home.date),
    };
    final showToday = home.view != HomeView.schedule &&
        (home.view == HomeView.day ? home.date != today : (home.date.month != today.month || home.date.year != today.year));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          borderRadius: BorderRadius.circular(Radii.row),
          onTap: () async {
            final d = await showMiniMonth(context, home.view == HomeView.schedule ? today : home.date); // S-18
            if (d == null) return;
            if (home.view == HomeView.schedule) {
              notifier.openDay(d);
            } else {
              notifier.setDate(d);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: Space.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const Icon(Icons.arrow_drop_down_rounded),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.topSearch,
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
          if (showToday)
            TextButton(onPressed: notifier.today, child: Text(l10n.topToday))
          else
            const SizedBox(width: 0),
          PopupMenuButton<HomeView>(
            tooltip: l10n.viewSchedule,
            icon: Icon(HomeShell.viewIcon(home.view)),
            initialValue: home.view,
            onSelected: notifier.setView,
            itemBuilder: (_) => [
              for (final v in HomeView.values)
                PopupMenuItem(
                  value: v,
                  child: Row(children: [Icon(HomeShell.viewIcon(v), size: 20), const SizedBox(width: Space.m), Text(HomeShell.viewName(l10n, v))]),
                ),
            ],
          ),
        ],
      ),
      drawer: const _Drawer(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const _Banners(),
            Expanded(
              child: switch (home.view) {
                HomeView.schedule => const SchedulePage(),
                HomeView.day => const DayView(),
                HomeView.month => const MonthView(),
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newReminder,
        onPressed: () => showCaptureSheet(context, day: home.view == HomeView.schedule || home.date == today ? null : home.date),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}

/// G2 notifications off (PRM-1) · G3 exact alarms off (PRM-2) · G4 calendar access lost (CAL-10).
class _Banners extends ConsumerWidget {
  const _Banners();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = ref.watch(permissionsProvider);
    final s = ref.read(servicesProvider);
    ref.watch(calendarRemindersProvider);
    final calendarLost = s.calendar.connected && !s.calendar.permission && s.calendar.calendars.isNotEmpty;
    return Column(
      children: [
        if (!p.notifications)
          InfoBanner(
            icon: Icons.notifications_off_outlined,
            text: l10n.bannerNotifOff,
            action: l10n.actionTurnOn,
            onAction: () async {
              await s.alarms.requestNotificationPermission();
              await ref.read(permissionsProvider.notifier).refresh();
            },
          ),
        if (p.notifications && !p.exactAlarms)
          InfoBanner(
            icon: Icons.timer_off_outlined,
            text: l10n.bannerExact,
            action: l10n.actionFix,
            onAction: s.alarms.openExactAlarmSettings,
          ),
        if (calendarLost)
          InfoBanner(
            icon: Icons.event_busy_outlined,
            text: l10n.bannerCalendarOff,
            action: l10n.actionReconnect,
            onAction: () => s.calendar.connect().then((_) => s.service.resync()),
          ),
      ],
    );
  }
}

class _Drawer extends ConsumerWidget {
  const _Drawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final home = ref.watch(homeProvider);
    final filters = ref.watch(filtersProvider);
    final prefs = ref.read(servicesProvider).prefs;
    ref.watch(calendarRemindersProvider);
    final calendar = ref.read(servicesProvider).calendar;
    final selectedCals = calendar.calendars.where((cal) => calendar.selected.contains(cal.id)).toList();

    Future<void> toggle(String key, Set<String> hidden, String value) async {
      final next = {...hidden};
      if (!next.remove(value)) next.add(value);
      await prefs.set(key, next.toList());
    }

    Widget header(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.l, Space.l, Space.xs),
      child: Text(t.toUpperCase(), style: text.labelSmall?.copyWith(letterSpacing: 0.5)),
    );

    void go(String path) {
      Navigator.pop(context);
      context.push(path);
    }

    return Drawer(
      backgroundColor: c.bgGrouped,
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xl, Space.l, Space.l, Space.s),
              child: Text(l10n.appName, style: text.titleLarge),
            ),
            for (final v in HomeView.values)
              ListTile(
                leading: Icon(HomeShell.viewIcon(v)),
                title: Text(HomeShell.viewName(l10n, v)),
                selected: home.view == v,
                onTap: () {
                  ref.read(homeProvider.notifier).setView(v);
                  Navigator.pop(context);
                },
              ),
            header(l10n.drawerTypes),
            for (final k in Kind.values)
              CheckboxListTile(
                dense: true,
                value: !filters.hiddenKinds.contains(k.name),
                activeColor: c.kind(k),
                secondary: Icon(kindIcon(k), color: c.kind(k)),
                title: Text(f.kind(k)),
                onChanged: (_) => toggle(PrefKeys.hiddenKinds, filters.hiddenKinds, k.name),
              ),
            header(l10n.drawerContext),
            for (final x in ReminderContext.values)
              CheckboxListTile(
                dense: true,
                value: !filters.hiddenContexts.contains(x.name),
                secondary: Icon(x == ReminderContext.work ? Icons.work_outline_rounded : Icons.person_outline_rounded),
                title: Text(f.context(x)),
                onChanged: (_) => toggle(PrefKeys.hiddenContexts, filters.hiddenContexts, x.name),
              ),
            if (selectedCals.isNotEmpty) ...[
              header(l10n.drawerCalendars),
              for (final cal in selectedCals)
                CheckboxListTile(
                  dense: true,
                  value: !filters.hiddenCalendars.contains(cal.id),
                  activeColor: Color(cal.color | 0xFF000000),
                  secondary: Icon(Icons.circle, size: 14, color: Color(cal.color | 0xFF000000)),
                  title: Text(cal.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onChanged: (_) => toggle(PrefKeys.hiddenCalendars, filters.hiddenCalendars, cal.id),
                ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.task_alt_rounded),
              title: Text(l10n.drawerCompleted),
              onTap: () => go('/completed'),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.drawerSettings),
              onTap: () => go('/settings'),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: Text(l10n.drawerHelp),
              onTap: () => go('/settings/about'),
            ),
          ],
        ),
      ),
    );
  }
}
