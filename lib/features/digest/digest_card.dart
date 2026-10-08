/// S-41 Digest card (DIG-1…3, OVD-3, CON-6 suggestions): Overdue · Missed · Coming up · Removed from
/// your calendar, at the top of Schedule (and today's Day view) until dismissed or the day ends.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../data/prefs_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../actions/occurrence_actions.dart';
import '../../ui/icons.dart';

class DigestCard extends ConsumerWidget {
  const DigestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(digestProvider);
    if (d == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final s = ref.read(servicesProvider);
    final suggestions = s.contacts.suggestions;

    Widget section(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.only(top: Space.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: text.labelSmall?.copyWith(letterSpacing: 0.5)),
          ...rows,
        ],
      ),
    );

    Widget line(String title, String sub, {VoidCallback? onTap, Widget? trailing, Color? color}) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color ?? c.accent, shape: BoxShape.circle)),
            const SizedBox(width: Space.s),
            Expanded(child: Text(title, style: text.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text(sub, style: text.bodySmall),
            ?trailing,
          ],
        ),
      ),
    );

    final today = ref.watch(todayProvider);
    // "Today · 9:00 AM" / "Mon, Oct 12" — time only matters for timed items.
    String short(({Reminder reminder, DateTime start}) i) => i.reminder.timing.type == TimingType.date
        ? (i.start == today ? l10n.groupToday : f.date(i.start))
        : f.when(i.start, allDay: false, today: today);
    final kept = s.prefs.stringSet('stale_kept');
    final stale = d.stale.map((i) => i.occurrenceId).where((id) => !kept.contains(id)).toSet();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.s, Space.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.digest, color: c.warning),
                  const SizedBox(width: Space.s),
                  Expanded(child: Text(l10n.digestTitle, style: text.titleMedium)),
                  TextButton(
                    onPressed: () => s.prefs.set(
                      PrefKeys.digestDismissedDay,
                      formatWallDate(ref.read(todayProvider)),
                    ),
                    child: Text(l10n.actionDismiss),
                  ),
                ],
              ),
              if (d.overdue.isNotEmpty)
                section(l10n.digestOverdue, [
                  for (final i in d.overdue.take(5))
                    stale.contains(i.occurrenceId)
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                line(i.reminder.title, short((reminder: i.reminder, start: i.start)), color: c.danger),
                                Row(
                                  children: [
                                    Expanded(child: Text(l10n.digestStale, style: text.bodySmall)), // OVD-3
                                    TextButton(
                                      // OVD-3 Keep: stays overdue, the question isn't asked again.
                                      onPressed: () => s.prefs.set('stale_kept', [...kept, i.occurrenceId]),
                                      child: Text(l10n.actionKeep),
                                    ),
                                    TextButton(
                                      onPressed: () => OccurrenceActions(context, ref).skip(i.reminder, i.occurrenceKey),
                                      child: Text(l10n.actionSkip),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : line(i.reminder.title, short((reminder: i.reminder, start: i.start)),
                            color: c.danger, onTap: () => openDetail(context, i.reminder, i.occurrenceKey)),
                ]),
              if (d.missed > 0) section(l10n.digestMissed, [line(l10n.digestMissedCount(d.missed), '', color: c.warning)]),
              if (d.upcomingOccasions.isNotEmpty)
                section(l10n.digestComingUp, [
                  for (final i in d.upcomingOccasions.take(5))
                    line(i.reminder.title, short((reminder: i.reminder, start: i.start)),
                        color: c.occasion, onTap: () => openDetail(context, i.reminder, i.occurrenceKey)),
                ]),
              if (d.removedFromCalendar.isNotEmpty)
                section(l10n.digestRemoved, [line('${d.removedFromCalendar.length}', '', color: c.event)]),
              if (suggestions.isNotEmpty)
                section(l10n.digestSuggestions, [
                  for (final cd in suggestions.take(5))
                    line(
                      contactTitle(cd),
                      '',
                      color: c.occasion,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(onPressed: () => s.contacts.addSuggestion(cd), child: Text(l10n.actionAdd)),
                          IconButton(
                            icon: const Icon(AppIcons.close, size: 18),
                            onPressed: () => s.contacts.dismissSuggestion(cd),
                          ),
                        ],
                      ),
                    ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
