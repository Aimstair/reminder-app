/// S-09 Background location explainer (PRM-9): shown after the first place reminder is saved when
/// "Allow all the time" isn't on yet. Page hero (DS15) + why + [Open settings] / [Not now].
library;

import 'package:flutter/material.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/art.dart';
import '../../ui/icons.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';

Future<void> showBackgroundExplainer(BuildContext context, {required Future<void> Function() openSettings}) =>
    showAppSheet<void>(context, (ctx) => _Explainer(openSettings: openSettings));

class _Explainer extends StatelessWidget {
  const _Explainer({required this.openSettings});
  final Future<void> Function() openSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.l, Space.xl, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PageHero(icon: AppIcons.place, color: c.memorial),
          const SizedBox(height: Space.l),
          Text(l10n.placeBgTitle, style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: Space.s),
          Text(l10n.placeBgBody, style: text.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: Space.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.privacy, size: 16, color: c.success),
              const SizedBox(width: Space.xs + 2),
              Flexible(child: Text(l10n.placeBgFoot, style: text.bodySmall, textAlign: TextAlign.center)),
            ],
          ),
          const SizedBox(height: Space.xl),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
              ),
              onPressed: () {
                openSettings();
                Navigator.pop(context);
              },
              child: Text(l10n.actionOpenSettings),
            ),
          ),
          const SizedBox(height: Space.s),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionNotNow)),
        ],
      ),
    );
  }
}
