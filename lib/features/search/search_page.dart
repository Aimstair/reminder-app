/// S-40 Search: live results over active and archived reminders (title + notes); empty state G7
/// with "Create '…'".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/art.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../actions/occurrence_actions.dart';
import '../capture/capture_sheet.dart';
import '../../ui/icons.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final all = [...?ref.watch(allRemindersProvider).value, ...?ref.watch(calendarRemindersProvider).value];
    final results = searchReminders(all, _q);
    final saved = ref.watch(occurrencesProvider).value ?? const {};
    final prefs = ref.watch(prefsProvider);
    final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            filled: true,
            fillColor: c.surface,
            isDense: true,
            prefixIcon: const Icon(AppIcons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.row), borderSide: BorderSide.none),
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
        actions: const [SizedBox(width: Space.l)],
      ),
      body: _q.trim().isEmpty
          ? ListView(
              children: [
                const SizedBox(height: Space.xxl),
                PageHero(icon: AppIcons.search, color: c.accent, caption: l10n.searchHero),
              ],
            )
          : results.isEmpty
          ? EmptyState(
              title: l10n.searchEmpty(_q.trim()),
              action: l10n.searchCreate(_q.trim()),
              onAction: () => showCaptureSheet(context, text: _q.trim()),
            )
          : ListView(
              padding: const EdgeInsets.only(top: Space.s, bottom: Space.xxxl),
              children: [
                InsetGroup(
                  indent: ReminderRow.dividerIndent,
                  children: [
                    for (final r in results)
                      Builder(
                        builder: (context) {
                          // Show the next open occurrence for repeating items, else the start.
                          final key = _nextKey(r, saved, prefs, now);
                          final occ = saved[AlarmPlanner.occurrenceId(r.id, key)];
                          final done = r.status == ReminderStatus.archived || (occ?.state.isResolved ?? false);
                          final allDay = r.timing.type == TimingType.date;
                          final wall = allDay
                              ? key
                              : instantToWall(
                                  OccurrenceTimes.of(r, occ?.overrideStart ?? key, prefs).anchor,
                                  prefs.deviceTimeZone,
                                );
                          return ReminderRow(
                            reminder: r,
                            when: f.when(wall, allDay: allDay),
                            done: done,
                            onTap: () => openDetail(context, r, key),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  static DateTime _nextKey(Reminder r, Map<String, Occurrence> saved, UserPrefs prefs, DateTime now) {
    if (r.rrule == null || r.repeatMode == RecurrenceMode.afterCompletion) return r.timing.start;
    final zone = r.timing.type == TimingType.date ? prefs.deviceTimeZone : (r.timing.timeZone ?? prefs.defaultTimeZone);
    final from = dateOnly(instantToWall(now, zone));
    for (final k in occurrenceKeysBetween(r, from, addDays(from, 800))) {
      final o = saved[AlarmPlanner.occurrenceId(r.id, k)];
      if (o == null || !o.state.isResolved) return k;
    }
    return r.timing.start;
  }
}
