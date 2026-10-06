/// S-10 Home shell: top bar (☰ · title · search · Today · view switcher), current view, [+] button.
/// v1.0 views: Schedule now; Day and Month follow (S-13, S-14).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/capture/capture_sheet.dart';
import '../features/schedule/schedule_page.dart';
import '../l10n/gen/app_localizations.dart';
import '../ui/tokens.dart';

enum HomeView { schedule, day, month }

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void comingSoon() => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewSchedule),
        actions: [
          IconButton(tooltip: l10n.topSearch, icon: const Icon(Icons.search_rounded), onPressed: comingSoon),
          PopupMenuButton<HomeView>(
            icon: const Icon(Icons.calendar_view_day_rounded),
            onSelected: (v) => v == HomeView.schedule ? null : comingSoon(),
            itemBuilder: (_) => [
              PopupMenuItem(value: HomeView.schedule, child: Text(l10n.viewSchedule)),
              PopupMenuItem(value: HomeView.day, child: Text(l10n.viewDay)),
              PopupMenuItem(value: HomeView.month, child: Text(l10n.viewMonth)),
            ],
          ),
        ],
      ),
      drawer: const _Drawer(),
      body: const SafeArea(top: false, child: SchedulePage()),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newReminder,
        onPressed: () => showCaptureSheet(context),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}

class _Drawer extends StatelessWidget {
  const _Drawer();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    return Drawer(
      backgroundColor: c.bgGrouped,
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Text(l10n.appName, style: Theme.of(context).textTheme.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.view_agenda_outlined),
              title: Text(l10n.viewSchedule),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(leading: const Icon(Icons.view_day_outlined), title: Text(l10n.viewDay), enabled: false),
            ListTile(leading: const Icon(Icons.calendar_month_outlined), title: Text(l10n.viewMonth), enabled: false),
            const Divider(),
            ListTile(leading: const Icon(Icons.task_alt_rounded), title: Text(l10n.drawerCompleted), enabled: false),
            ListTile(leading: const Icon(Icons.settings_outlined), title: Text(l10n.drawerSettings), enabled: false),
            ListTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: Text(l10n.drawerDiagnostics),
              onTap: () {
                Navigator.pop(context);
                context.push('/diagnostics');
              },
            ),
          ],
        ),
      ),
    );
  }
}
