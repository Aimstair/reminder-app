/// S-42 Completed: done / skipped occurrences, newest first, searchable. Tap → detail (read-only for
/// resolved, REC-14) · "Mark as not done" (OCC-5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/bell.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../actions/occurrence_actions.dart';
import '../../ui/icons.dart';

final _resolvedProvider = StreamProvider<List<Occurrence>>(
  (ref) => ref.watch(servicesProvider).occurrences.watchResolved(),
);

class CompletedPage extends ConsumerStatefulWidget {
  const CompletedPage({super.key});

  @override
  ConsumerState<CompletedPage> createState() => _CompletedPageState();
}

class _CompletedPageState extends ConsumerState<CompletedPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final occs = ref.watch(_resolvedProvider).value;
    final byId = {for (final r in ref.watch(allRemindersProvider).value ?? const <Reminder>[]) r.id: r};
    final prefs = ref.watch(prefsProvider);
    final q = _q.trim().toLowerCase();
    final rows = [
      for (final o in occs ?? const <Occurrence>[])
        if (byId[o.reminderId] case final r? when q.isEmpty || r.title.toLowerCase().contains(q)) (r, o),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.drawerCompleted)),
      body: occs == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.only(bottom: Space.xxxl),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      filled: true,
                      fillColor: c.surface,
                      isDense: true,
                      prefixIcon: const Icon(AppIcons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.row),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _q = v),
                  ),
                ),
                if (rows.isEmpty)
                  EmptyState(title: l10n.completedEmptyTitle, sub: l10n.completedEmptySub, mood: BellMood.calm)
                else
                  InsetGroup(
                    children: [
                      for (final (r, o) in rows)
                        ReminderRow(
                          reminder: r,
                          done: true,
                          when: [
                            f.state(o.state),
                            if (o.resolvedAt != null)
                              f.when(instantToWall(o.resolvedAt!, prefs.deviceTimeZone), allDay: false),
                          ].join(' · '),
                          onTap: () => openDetail(context, r, o.occurrenceKey),
                          trailing: IconButton(
                            tooltip: l10n.actionMarkNotDone,
                            icon: Icon(AppIcons.undo, color: c.textSecondary),
                            onPressed: () async {
                              final s = ref.read(servicesProvider);
                              if (r.status == ReminderStatus.archived) {
                                await s.reminders.update(r.copyWith(status: ReminderStatus.active));
                              }
                              await s.service.setState(r.id, o.occurrenceKey, OccurrenceState.pending);
                            },
                          ),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}
