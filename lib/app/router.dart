/// Routes (screens.md §2). First launch goes to onboarding (FL-1).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/prefs_repository.dart';
import '../features/completed/completed_page.dart';
import '../features/detail/detail_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/search/search_page.dart';
import '../features/settings/settings_pages.dart';
import '../spike/alarm_spike_page.dart';
import 'home_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// `/item/<reminderId>/<yyyyMMddHHmm>` → occurrence key.
DateTime? parseOccurrenceSegment(String s) {
  if (s.length != 12 || int.tryParse(s) == null) return null;
  return DateTime.utc(
    int.parse(s.substring(0, 4)),
    int.parse(s.substring(4, 6)),
    int.parse(s.substring(6, 8)),
    int.parse(s.substring(8, 10)),
    int.parse(s.substring(10, 12)),
  );
}

GoRouter buildRouter(PrefsRepository prefs) => GoRouter(
  navigatorKey: rootNavigatorKey,
  redirect: (context, state) {
    final onboarding = state.matchedLocation == '/onboarding';
    if (!prefs.onboarded && !onboarding) return '/onboarding';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (_, state) => HomeShell(openCapture: state.uri.queryParameters['capture'] == '1'),
    ),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
    GoRoute(
      path: '/item/:id/:key',
      builder: (_, state) => DetailPage(
        reminderId: Uri.decodeComponent(state.pathParameters['id']!),
        occurrenceKey: parseOccurrenceSegment(state.pathParameters['key']!) ?? DateTime.utc(1970),
      ),
    ),
    GoRoute(path: '/search', builder: (_, _) => const SearchPage()),
    GoRoute(path: '/completed', builder: (_, _) => const CompletedPage()),
    GoRoute(
      path: '/settings',
      builder: (_, _) => const SettingsPage(),
      routes: [
        GoRoute(path: 'schedule', builder: (_, _) => const ScheduleSettingsPage()),
        GoRoute(path: 'timezone', builder: (_, _) => const TimeZoneSettingsPage()),
        GoRoute(path: 'alerts', builder: (_, _) => const AlertDefaultsPage()),
        GoRoute(path: 'notifications', builder: (_, _) => const NotificationSettingsPage()),
        GoRoute(path: 'calendars', builder: (_, _) => const CalendarSettingsPage()),
        GoRoute(path: 'views', builder: (_, _) => const ViewSettingsPage()),
        GoRoute(path: 'reliability', builder: (_, _) => const ReliabilityPage()),
        GoRoute(path: 'about', builder: (_, _) => const AboutPage()),
      ],
    ),
    // Alarm reliability tools from the v0 spike (fire log, permissions) — kept for device testing.
    GoRoute(path: '/diagnostics', builder: (_, _) => const AlarmSpikePage()),
  ],
);
