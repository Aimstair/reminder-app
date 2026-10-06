/// FL-1 step 7 / PRM-6: on the first save of a reminder with alerts — notifications explainer (S-05)
/// → system dialog, precise timing (S-06) if needed, battery tip (S-07) on aggressive phones, then
/// "Want to make sure it works?" (PRM-7). Runs once.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/prefs_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/bell.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import 'setup_widgets.dart';

/// Phones known to stop background apps (PRM-4, dontkillmyapp.com).
const _aggressive = {'samsung', 'xiaomi', 'redmi', 'poco', 'oneplus', 'oppo', 'vivo', 'realme', 'huawei', 'honor', 'meizu', 'asus', 'tecno', 'infinix'};

Future<void> runPermissionFlowOnce(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final s = container.read(servicesProvider);
  if (s.prefs.flag('notif_asked')) return;
  await s.prefs.set('notif_asked', true);
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);

  var perms = await s.alarms.permissions();
  if (!perms.notifications && context.mounted) {
    await _explain(context, BellMood.ringing, l10n.notifTitle, l10n.notifSub, l10n.actionContinue);
    await s.alarms.requestNotificationPermission();
    // The system dialog is async; give it a moment before reading the result.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    perms = await s.alarms.permissions();
  }
  if (!perms.exactAlarms && context.mounted) {
    final go = await _explain(context, BellMood.calm, l10n.exactTitle, l10n.exactSub, l10n.actionOpenSettings,
        secondary: l10n.actionNotNow);
    if (go) await s.alarms.openExactAlarmSettings();
  }
  final brand = (await s.platform?.deviceBrand() ?? '').toLowerCase();
  if (!perms.batteryUnrestricted && _aggressive.contains(brand) && !s.prefs.flag(PrefKeys.batteryTipDismissed) && context.mounted) {
    final go = await _explain(context, BellMood.thinking, l10n.batteryTitle,
        l10n.batterySub(brand.isEmpty ? '' : brand[0].toUpperCase() + brand.substring(1)), l10n.actionShowMe,
        secondary: l10n.actionLater);
    await s.prefs.set(PrefKeys.batteryTipDismissed, true);
    if (go) await s.alarms.openBatteryOptimizationSettings();
  }
  await container.read(permissionsProvider.notifier).refresh();
  if (context.mounted) {
    await showAppSheet<void>(
      context,
      (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TestReminderPanel(),
            const SizedBox(height: Space.s),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(ctx).actionSkipStep)),
          ],
        ),
      ),
    );
  }
}

/// A permission explainer sheet; true = primary button.
Future<bool> _explain(BuildContext context, BellMood mood, String title, String sub, String primary,
    {String? secondary}) async {
  final r = await showAppSheet<bool>(
    context,
    (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(Space.xxl, 0, Space.xxl, Space.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Bell(size: 120, mood: mood),
          const SizedBox(height: Space.l),
          Text(title, style: Theme.of(ctx).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: Space.s),
          Text(sub, style: Theme.of(ctx).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: Space.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(primary)),
          ),
          if (secondary != null) TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(secondary)),
        ],
      ),
    ),
  );
  return r ?? false;
}
