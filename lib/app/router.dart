/// Routes (screens.md §2). Onboarding, detail, search and settings join as they are built.
library;

import 'package:go_router/go_router.dart';

import '../spike/alarm_spike_page.dart';
import 'home_shell.dart';

GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeShell()),
    // Alarm reliability tools from the v0 spike (fire log, permissions) — kept for device testing.
    GoRoute(path: '/diagnostics', builder: (_, _) => const AlarmSpikePage()),
  ],
);
