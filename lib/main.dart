import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/app_services.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'data/prefs_repository.dart';
import 'features/actions/occurrence_actions.dart';
import 'features/capture/capture_sheet.dart';
import 'integrations/crash_reporting.dart';
import 'l10n/gen/app_localizations.dart';
import 'native/platform_gateway.dart';
import 'services/reminder_service.dart';
import 'ui/format.dart';
import 'ui/theme.dart';

/// Bootstrap (architecture.md §2): services → providers → router.
Future<void> main() => runWithCrashReporting(() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Font licences (Inter OFL, Phosphor MIT) must ship with the app; they show on the licences page.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Inter'], await rootBundle.loadString('assets/fonts/Inter-OFL.txt'));
    yield LicenseEntryWithLineBreaks(['Phosphor Icons'], await rootBundle.loadString('assets/fonts/Phosphor-MIT.txt'));
  });
  final platform = PlatformGateway();
  final services = await AppServices.start(platform: platform);
  runApp(
    ProviderScope(
      overrides: [servicesProvider.overrideWithValue(services)],
      child: const ReminderApp(),
    ),
  );
});

class ReminderApp extends ConsumerStatefulWidget {
  const ReminderApp({super.key});

  @override
  ConsumerState<ReminderApp> createState() => _ReminderAppState();
}

class _ReminderAppState extends ConsumerState<ReminderApp> {
  late final GoRouter _router = buildRouter(ref.read(servicesProvider).prefs);
  late final AppLifecycleListener _lifecycle;
  final _subs = <StreamSubscription<String>>[];

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    final s = ref.read(servicesProvider);
    final p = s.platform;
    if (p != null) {
      _subs
        ..add(p.launchActions.listen(_launch))
        ..add(p.sharedText.listen(_shared));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Apply notification taps and resync alarms (architecture.md §6); the first frame doesn't wait.
      await _refresh();
      // Cold start from the tile / widget / a notification / the share sheet.
      final action = await p?.takeLaunchAction();
      if (action != null) _launch(action);
      final text = await p?.takeSharedText();
      if (text != null) _shared(text);
    });
  }

  Future<void> _refresh() async {
    final s = ref.read(servicesProvider);
    await s.refresh();
    if (!mounted) return;
    ref
      ..invalidate(prefsProvider) // device zone may have changed (TIM-15)
      ..invalidate(nowProvider)
      ..invalidate(missedCountProvider);
    await ref.read(permissionsProvider.notifier).refresh();
    await _travelPrompt();
  }

  Future<void> _onResume() => _refresh();

  BuildContext? get _ctx => rootNavigatorKey.currentContext;

  /// `capture` (QS tile S-62, widget [+] S-61) or `open:<alarmKey>` (notification body, NTF-3).
  void _launch(String action) {
    final ctx = _ctx;
    if (ctx == null || !ref.read(servicesProvider).prefs.onboarded) return;
    if (action == 'capture') {
      showCaptureSheet(ctx);
    } else if (action.startsWith('open:')) {
      final occ = parseAlarmKey(action.substring(5));
      if (occ != null) _router.push(detailPath(occ.reminderId, occ.occurrenceKey));
    }
  }

  /// S-63 share target (FL-5): pre-filled capture, preview before saving (CAP-7, CAP-12).
  void _shared(String text) {
    final ctx = _ctx;
    if (ctx == null || !ref.read(servicesProvider).prefs.onboarded) return;
    showCaptureSheet(ctx, text: text);
  }

  /// TIM-8: once per new zone, offer to switch the default zone (PRF-2).
  Future<void> _travelPrompt() async {
    final s = ref.read(servicesProvider);
    final p = s.prefs.current;
    final ctx = _ctx;
    if (ctx == null || !s.prefs.onboarded || !p.askOnTravel) return;
    final here = p.deviceTimeZone;
    if (here == p.defaultTimeZone || here == 'UTC' || s.prefs.string('travel_asked') == here) return;
    await s.prefs.set('travel_asked', here);
    if (!ctx.mounted) return;
    final l10n = AppLocalizations.of(ctx);
    final switchIt = await showDialog<bool>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: Text(l10n.travelTitle(Fmt.city(here))),
        content: Text(l10n.travelBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx, false), child: Text(l10n.actionKeepCity(Fmt.city(p.defaultTimeZone)))),
          FilledButton(onPressed: () => Navigator.pop(dctx, true), child: Text(l10n.actionSwitch)),
        ],
      ),
    );
    if (switchIt == true) {
      await s.prefs.set(PrefKeys.defaultTimeZone, here);
      await s.service.resync();
    }
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(prefsRepoProvider).string(PrefKeys.theme) ?? 'system';
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
    );
  }
}
