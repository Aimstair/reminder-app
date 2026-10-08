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
import '../ui/icons.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.openCapture = false});

  /// FL-1 step 6: open the capture sheet when onboarding saved nothing.
  final bool openCapture;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();

  static IconData viewIcon(HomeView v) => switch (v) {
    HomeView.schedule => AppIcons.listView,
    HomeView.day => AppIcons.calendarView,
    HomeView.month => AppIcons.monthGrid,
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
    final home = ref.watch(homeProvider);
    final today = ref.watch(todayProvider);
    final notifier = ref.read(homeProvider.notifier);
    final schedule = home.view == HomeView.schedule;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            icon: const Icon(AppIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: _ViewPill(view: home.view, onSelected: notifier.setView),
        actions: [
          if (schedule) ...[
            IconButton(
              tooltip: l10n.topSearch,
              icon: const Icon(AppIcons.search),
              onPressed: () => context.push('/search'),
            ),
            IconButton(
              tooltip: l10n.drawerSettings,
              icon: const Icon(AppIcons.settings),
              onPressed: () => context.push('/settings'),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: Space.l),
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.of(context).accent.withValues(alpha: 0.12),
                  foregroundColor: AppColors.of(context).accent,
                ),
                onPressed: notifier.today, // VW-9
                child: Text(l10n.topToday),
              ),
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
        child: const Icon(AppIcons.add, size: 30),
      ),
    );
  }
}

/// Centered view switcher (mockups 02/06/08): icon · view name · caret in a rounded pill.
class _ViewPill extends StatelessWidget {
  const _ViewPill({required this.view, required this.onSelected});
  final HomeView view;
  final ValueChanged<HomeView> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    return PopupMenuButton<HomeView>(
      tooltip: '',
      initialValue: view,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        for (final v in HomeView.values)
          PopupMenuItem(
            value: v,
            child: Row(
              children: [
                Icon(HomeShell.viewIcon(v), size: 20),
                const SizedBox(width: Space.m),
                Text(HomeShell.viewName(l10n, v)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.m, Space.s),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.sheet)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(HomeShell.viewIcon(view), size: 20, color: c.textPrimary),
            const SizedBox(width: Space.s),
            Text(HomeShell.viewName(l10n, view), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: Space.xs),
            Icon(AppIcons.dropDown, size: 16, color: c.textPrimary),
          ],
        ),
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
            icon: AppIcons.notificationsOff,
            text: l10n.bannerNotifOff,
            action: l10n.actionTurnOn,
            onAction: () async {
              await s.alarms.requestNotificationPermission();
              await ref.read(permissionsProvider.notifier).refresh();
            },
          ),
        if (p.notifications && !p.exactAlarms)
          InfoBanner(
            icon: AppIcons.preciseOff,
            text: l10n.bannerExact,
            action: l10n.actionFix,
            onAction: s.alarms.openExactAlarmSettings,
          ),
        if (calendarLost)
          InfoBanner(
            icon: AppIcons.calendarOff,
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
                secondary: Icon(x == ReminderContext.work ? AppIcons.work : AppIcons.personal),
                title: Text(f.context(x)),
                onChanged: (_) => toggle(PrefKeys.hiddenContexts, filters.hiddenContexts, x.name),
              ),
            // Collapsed by default: people with several Google accounts can have 30+ calendars (VW-2).
            if (selectedCals.isNotEmpty)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.l, 0),
                  title: Text(l10n.drawerCalendars.toUpperCase(), style: text.labelSmall?.copyWith(letterSpacing: 0.5)),
                  subtitle: filters.hiddenCalendars.isEmpty
                      ? null
                      : Text(l10n.drawerCalendarsHidden(
                          selectedCals.where((cal) => filters.hiddenCalendars.contains(cal.id)).length,
                        )),
                  children: [
                    for (final cal in selectedCals)
                      CheckboxListTile(
                        dense: true,
                        value: !filters.hiddenCalendars.contains(cal.id),
                        activeColor: Color(cal.color | 0xFF000000),
                        secondary: Icon(AppIcons.dot, size: 14, color: Color(cal.color | 0xFF000000)),
                        title: Text(cal.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        // Same-named calendars (e.g. holidays) come from different accounts.
                        subtitle: cal.accountName.isEmpty || cal.accountName == cal.name
                            ? null
                            : Text(cal.accountName, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onChanged: (_) => toggle(PrefKeys.hiddenCalendars, filters.hiddenCalendars, cal.id),
                      ),
                  ],
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(AppIcons.done),
              title: Text(l10n.drawerCompleted),
              onTap: () => go('/completed'),
            ),
            ListTile(
              leading: const Icon(AppIcons.settings),
              title: Text(l10n.drawerSettings),
              onTap: () => go('/settings'),
            ),
            ListTile(
              leading: const Icon(AppIcons.help),
              title: Text(l10n.drawerHelp),
              onTap: () => go('/settings/about'),
            ),
          ],
        ),
      ),
    );
  }
}
