/// Celebrations (design-direction §6, copy.md §7): "All clear!" when the last of today is done, and
/// the first completion ever. Colored banner with the bell + overlapping stat cards (DS11). Factual
/// stats only — no streaks or points (DS10).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/bell.dart';
import '../../ui/tokens.dart';

enum Celebration { allClear, firstDone }

Future<void> showCelebration(BuildContext context, Celebration kind) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Colors.black.withValues(alpha: 0.35),
  transitionDuration: const Duration(milliseconds: 380),
  pageBuilder: (_, _, _) => _CelebrationCard(kind: kind),
  transitionBuilder: (ctx, a, _, child) {
    final curved = CurvedAnimation(parent: a, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    return FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(curved), child: child));
  },
);

class _CelebrationCard extends ConsumerWidget {
  const _CelebrationCard({required this.kind});
  final Celebration kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(todayProgressProvider);
    final upcoming = (ref.watch(scheduleProvider) ?? const <ScheduleItem>[])
        .where((i) => i.group == ScheduleGroup.tomorrow)
        .length;
    final title = kind == Celebration.allClear ? l10n.allClearTitle : l10n.firstDoneTitle;
    final sub = kind == Celebration.allClear ? l10n.allClearSub : l10n.firstDoneSub;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Material(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(Radii.sheet),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Banner tinted in the success color, bell in the middle.
                SizedBox(
                  height: 230,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        bottom: 36,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [c.success, Color.lerp(c.success, Colors.teal, 0.35)!],
                            ),
                          ),
                          child: const Center(child: Bell(size: 140, mood: BellMood.party)),
                        ),
                      ),
                      // Stat cards overlapping the banner's bottom edge.
                      Positioned(
                        left: Space.l,
                        right: Space.l,
                        bottom: 0,
                        child: Row(
                          children: [
                            Expanded(child: _Stat(value: '${progress.done}', label: l10n.stateDone, color: c.success)),
                            const SizedBox(width: Space.m),
                            Expanded(child: _Stat(value: '$upcoming', label: l10n.groupTomorrow, color: c.accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.xxl, Space.xl, Space.xxl, Space.s),
                  child: Text(title, style: text.titleLarge, textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
                  child: Text(sub, style: text.bodyMedium, textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.all(Space.l),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.actionContinue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.m),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(value, style: text.titleLarge?.copyWith(color: color)),
          Text(label, style: text.labelSmall),
        ],
      ),
    );
  }
}
