import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/app_services.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'l10n/gen/app_localizations.dart';
import 'ui/theme.dart';

/// Bootstrap (architecture.md §2): services → providers → router.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.start();
  runApp(
    ProviderScope(
      overrides: [servicesProvider.overrideWithValue(services)],
      child: const ReminderApp(),
    ),
  );
  // Apply notification taps and resync alarms (architecture.md §6); the first frame doesn't wait.
  services.refresh();
}

class ReminderApp extends ConsumerStatefulWidget {
  const ReminderApp({super.key});

  @override
  ConsumerState<ReminderApp> createState() => _ReminderAppState();
}

class _ReminderAppState extends ConsumerState<ReminderApp> {
  late final GoRouter _router = buildRouter();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  Future<void> _onResume() async {
    await ref.read(servicesProvider).refresh();
    ref
      ..invalidate(prefsProvider) // device zone may have changed (TIM-15)
      ..invalidate(nowProvider);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    onGenerateTitle: (context) => AppLocalizations.of(context).appName,
    debugShowCheckedModeBanner: false,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
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
