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
import '../ui/motion.dart';

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
              padding: const EdgeInsets.only(right: Space.s),
              // iOS Calendar style: a plain accent "Today" in the bar.
              child: TextButton(
                style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.titleMedium),
                onPressed: notifier.today, // VW-9
                child: Text(l10n.topToday, maxLines: 1),
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
            // Views cross-fade with a small slide in the direction of the menu order.
            Expanded(
              child: SwapFade(
                slide: const Offset(0, 0.015),
                child: KeyedSubtree(
                  key: ValueKey(home.view),
                  child: switch (home.view) {
                    HomeView.schedule => const SchedulePage(),
                    HomeView.day => const DayView(),
                    HomeView.month => const MonthView(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newReminder,
        onPressed: () =>
            showCaptureSheet(context, day: home.view == HomeView.schedule || home.date == today ? null : home.date),
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
      // The pill resizes smoothly and its icon + name cross-fade when the view changes.
      child: Container(
        height: 36,
        padding: const EdgeInsets.fromLTRB(Space.m, 0, Space.s + 2, 0),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 1)),
          ],
        ),
        child: AnimatedSize(
          duration: Motion.standard,
          curve: Motion.spring,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: Motion.standard,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(scale: Tween(begin: 0.6, end: 1.0).animate(a), child: child),
                ),
                child: Row(
                  key: ValueKey(view),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(HomeShell.viewIcon(view), size: 18, color: c.accent),
                    const SizedBox(width: Space.s),
                    Text(HomeShell.viewName(l10n, view), maxLines: 1, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              const SizedBox(width: Space.xs),
              Icon(AppIcons.dropDown, size: 14, color: c.textSecondary),
            ],
          ),
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

class _Drawer extends ConsumerStatefulWidget {
  const _Drawer();

  @override
  ConsumerState<_Drawer> createState() => _DrawerState();
}

/// iOS-style grouped drawer: every row is 48dp; filters show an animated check (VW-2).
class _DrawerState extends ConsumerState<_Drawer> {
  // Collapsed by default: people with several Google accounts can have 30+ calendars (VW-2).
  bool _calendarsOpen = false;

  @override
  Widget build(BuildContext context) {
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
    final hiddenCals = selectedCals.where((cal) => filters.hiddenCalendars.contains(cal.id)).length;

    Future<void> toggle(String key, Set<String> hidden, String value) async {
      final next = {...hidden};
      if (!next.remove(value)) next.add(value);
      await prefs.set(key, next.toList());
    }

    void go(String path) {
      Navigator.pop(context);
      context.push(path);
    }

    const margin = EdgeInsets.symmetric(horizontal: Space.m);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.xl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xl, Space.l, Space.l, Space.m),
              child: Text(l10n.appName, style: text.headlineLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            InsetGroup(
              margin: margin,
              indent: 52,
              children: [
                for (final v in HomeView.values)
                  _DrawerRow(
                    icon: HomeShell.viewIcon(v),
                    iconColor: c.accent,
                    label: HomeShell.viewName(l10n, v),
                    bold: home.view == v,
                    trailing: AnimatedOpacity(
                      opacity: home.view == v ? 1 : 0,
                      duration: Motion.micro,
                      child: Icon(AppIcons.check, size: 18, color: c.accent),
                    ),
                    onTap: () {
                      ref.read(homeProvider.notifier).setView(v);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            GroupCaption(l10n.drawerTypes),
            InsetGroup(
              margin: margin,
              indent: 52,
              children: [
                for (final k in Kind.values)
                  _DrawerRow(
                    icon: kindIcon(k),
                    iconColor: c.kind(k),
                    label: f.kind(k),
                    trailing: CheckCircle(color: c.kind(k), checked: !filters.hiddenKinds.contains(k.name)),
                    onTap: () => toggle(PrefKeys.hiddenKinds, filters.hiddenKinds, k.name),
                  ),
              ],
            ),
            GroupCaption(l10n.drawerContext),
            InsetGroup(
              margin: margin,
              indent: 52,
              children: [
                for (final x in ReminderContext.values)
                  _DrawerRow(
                    icon: x == ReminderContext.work ? AppIcons.work : AppIcons.personal,
                    iconColor: x == ReminderContext.work ? c.meeting : c.task,
                    label: f.context(x),
                    trailing: CheckCircle(color: c.accent, checked: !filters.hiddenContexts.contains(x.name)),
                    onTap: () => toggle(PrefKeys.hiddenContexts, filters.hiddenContexts, x.name),
                  ),
              ],
            ),
            if (selectedCals.isNotEmpty) ...[
              GroupCaption(l10n.drawerCalendars),
              InsetGroup(
                margin: margin,
                indent: 52,
                children: [
                  _DrawerRow(
                    icon: AppIcons.calendar,
                    iconColor: c.danger,
                    label: hiddenCals == 0
                        ? '${selectedCals.length} ${l10n.drawerCalendars.toLowerCase()}'
                        : l10n.drawerCalendarsHidden(hiddenCals),
                    trailing: AnimatedRotation(
                      turns: _calendarsOpen ? 0.25 : 0,
                      duration: Motion.standard,
                      curve: Motion.spring,
                      child: Icon(AppIcons.next, size: 18, color: c.textSecondary),
                    ),
                    onTap: () => setState(() => _calendarsOpen = !_calendarsOpen),
                  ),
                  AnimatedSize(
                    duration: Motion.standard,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: !_calendarsOpen
                        ? const SizedBox(width: double.infinity)
                        : Column(
                            children: [
                              for (final cal in selectedCals)
                                _DrawerRow(
                                  icon: AppIcons.dot,
                                  iconSize: 12,
                                  iconColor: Color(cal.color | 0xFF000000),
                                  label: cal.name,
                                  // Same-named calendars (e.g. holidays) come from different accounts.
                                  sub: cal.accountName.isEmpty || cal.accountName == cal.name ? null : cal.accountName,
                                  trailing: CheckCircle(
                                    color: Color(cal.color | 0xFF000000),
                                    checked: !filters.hiddenCalendars.contains(cal.id),
                                  ),
                                  onTap: () => toggle(PrefKeys.hiddenCalendars, filters.hiddenCalendars, cal.id),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Space.xl),
            InsetGroup(
              margin: margin,
              indent: 52,
              children: [
                _DrawerRow(
                  icon: AppIcons.done,
                  iconColor: c.success,
                  label: l10n.drawerCompleted,
                  chevron: true,
                  onTap: () => go('/completed'),
                ),
                _DrawerRow(
                  icon: AppIcons.settings,
                  iconColor: c.textSecondary,
                  label: l10n.drawerSettings,
                  chevron: true,
                  onTap: () => go('/settings'),
                ),
                _DrawerRow(
                  icon: AppIcons.help,
                  iconColor: c.accent,
                  label: l10n.drawerHelp,
                  chevron: true,
                  onTap: () => go('/settings/about'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One 48dp drawer row (52dp with a second line): icon, label (truncated), trailing check or chevron.
class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.sub,
    this.trailing,
    this.bold = false,
    this.chevron = false,
    this.iconSize = 20,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? sub;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool bold;
  final bool chevron;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: sub == null ? 48 : 56,
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Icon(icon, size: iconSize, color: iconColor),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(fontWeight: bold ? FontWeight.w600 : FontWeight.w400),
                    ),
                    if (sub != null) Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: Space.s), trailing!],
              if (chevron) Icon(AppIcons.next, size: 18, color: c.textSecondary.withValues(alpha: 0.6)),
              SizedBox(width: trailing is CheckCircle ? Space.xs : Space.m),
            ],
          ),
        ),
      ),
    );
  }
}
