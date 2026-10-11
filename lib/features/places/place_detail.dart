/// S-30 for place reminders (mockup 14): banner tinted in the place's color with a map snapshot, chips,
/// title, trigger + active line; stat cards (status · radius · distance); a card with the place,
/// trigger, active days/hours and Paused (LOC-12); notes; Done / Skip / Delete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/icons.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../actions/occurrence_actions.dart';
import '../attachments/attachments.dart';
import 'place_format.dart';
import 'place_form.dart';
import 'place_pin.dart';

class PlaceDetailPage extends ConsumerWidget {
  const PlaceDetailPage({super.key, required this.reminder, required this.occurrenceKey, this.occurrence});
  final Reminder reminder;
  final DateTime occurrenceKey;
  final Occurrence? occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final r = reminder;
    final t = r.place!;
    final place = (ref.watch(placesProvider).value ?? const <Place>[]).where((p) => p.id == t.placeId).firstOrNull;
    final prefs = ref.watch(prefsProvider);
    final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();
    final today = ref.watch(todayProvider);
    final wall = instantToWall(now, prefs.deviceTimeZone);
    final status = ref.watch(locationStatusProvider).value;
    final here = ref.watch(hereProvider).value;
    final color = place == null ? c.memorial : c.place(place.color);
    final state = occurrence?.state ?? OccurrenceState.pending;
    final fired = occurrence?.firedAt;
    final key = placeKeyAt(r, wall);
    final saved = ref.watch(occurrencesProvider).value ?? const <String, Occurrence>{};
    final activeNow = key != null && placeActiveNow(r, wall, occurrence: saved[AlarmPlanner.occurrenceId(r.id, key)]);
    final ready = status?.ready ?? true;

    // Status card: Done · Rang 5:42 PM · Paused · Waiting for access · Active · Waiting.
    final (String statusValue, String statusLabel, Color? statusColor) = state.isResolved
        ? (f.state(state), l10n.statStatus, c.success)
        : fired != null
        ? (f.time(instantToWall(fired, prefs.deviceTimeZone)), l10n.detailPlaceRang, color)
        : t.paused
        ? (l10n.placeStatusPaused, l10n.statStatus, c.textSecondary)
        : !ready
        ? (l10n.detailPlaceWaiting, l10n.placeStatusWaitingAccess, c.warning)
        : activeNow
        ? (l10n.placeStatusActive, l10n.detailPlaceWatching, c.success)
        : (l10n.detailPlaceWaiting, l10n.statStatus, null);

    final whenLabel = t.onArrive && t.onLeave
        ? l10n.detailPlaceWhenBoth
        : t.onArrive
        ? l10n.detailPlaceWhenArrive
        : l10n.detailPlaceWhenLeave;
    final activeLine = t.active == PlaceActive.anyDay ? f.hours(t) : '${f.active(r, today: today)} · ${f.hours(t)}';
    final away = here == null || place == null
        ? null
        : metersBetween(here.latitude, here.longitude, place.latitude, place.longitude);

    return Scaffold(
      backgroundColor: c.bgGrouped,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _Banner(reminder: r, place: place, color: color, line: '${f.trigger(t)} · ${place?.name ?? ''}\n$activeLine'),
                Transform.translate(
                  offset: const Offset(0, -Space.xxxl),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.l),
                    child: Row(
                      children: [
                        Expanded(child: _Stat(value: statusValue, label: statusLabel, color: statusColor, dot: activeNow && ready)),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: _Stat(
                            value: place == null ? '–' : f.distance(place.radiusMeters.toDouble()),
                            label: l10n.detailPlaceRadius,
                          ),
                        ),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: _Stat(
                            value: away == null ? f.hours(t) : f.distance(away),
                            label: away == null ? l10n.placeFormHours.toLowerCase() : l10n.detailPlaceFromYou,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (t.linkedEvent case final e?)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
                child: Text(
                  l10n.placeFormFor(e.title, f.when(e.start, allDay: false, today: today)),
                  style: text.bodyMedium,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: InsetGroup(
              children: [
                FormRow(
                  icon: place == null ? AppIcons.place : placeIcon(place.icon, solid: true),
                  color: color,
                  label: place?.name ?? l10n.placeFormChoose,
                  subtitle: place?.address,
                  onTap: () => context.push('/places'),
                ),
                FormRow(
                  icon: t.onArrive && !t.onLeave ? AppIcons.arrive : AppIcons.leave,
                  color: c.memorial,
                  label: whenLabel,
                  value: t.remind == PlaceRemind.everyTime ? l10n.placeFormEveryTime : l10n.placeFormFirstTime,
                ),
                FormRow(icon: AppIcons.time, color: c.accent, label: l10n.placeFormActive, value: activeLine),
                if (!state.isResolved)
                  SwitchRow(
                    icon: AppIcons.pause,
                    color: c.grey,
                    label: l10n.placeFormPaused,
                    value: t.paused,
                    onChanged: (v) => ref.read(servicesProvider).places.setPaused(r, v), // LOC-12
                  ),
              ],
            ),
          ),
          if ((r.notes ?? '').isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
                child: Container(
                  padding: const EdgeInsets.all(Space.l),
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.card + 4)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(AppIcons.notes, color: c.textSecondary),
                      const SizedBox(width: Space.m),
                      Expanded(child: LinkifiedText(r.notes!, style: text.bodyLarge)), // ATT-5
                    ],
                  ),
                ),
              ),
            ),
          if (r.attachments.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
                child: AttachmentList(attachments: r.attachments),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxxl)),
        ],
      ),
      bottomNavigationBar: _Actions(reminder: r, occurrenceKey: occurrenceKey, state: state, color: color),
    );
  }
}

/// Pastel header like mockup 04, with a lite map of the place in the circle on the right.
class _Banner extends ConsumerWidget {
  const _Banner({required this.reminder, required this.place, required this.color, required this.line});
  final Reminder reminder;
  final Place? place;
  final Color color;
  final String line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final deep = Color.lerp(color, dark ? Colors.white : Colors.black, 0.3)!;
    final top = MediaQuery.paddingOf(context).top;
    final p = place;
    return ClipRect(
      child: Container(
        color: Color.alphaBlend(color.withValues(alpha: dark ? 0.24 : 0.14), c.surface),
        padding: const EdgeInsets.only(bottom: Space.xxxl + Space.l),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (p != null)
              Positioned(
                right: -40,
                top: top + 44,
                child: Container(
                  width: 196,
                  height: 196,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.surface.withValues(alpha: 0.7), width: 5),
                  ),
                  child: ClipOval(
                    child: IgnorePointer(
                      child: GoogleMap(
                        liteModeEnabled: true,
                        initialCameraPosition: CameraPosition(target: LatLng(p.latitude, p.longitude), zoom: _zoomFor(p.radiusMeters)),
                        style: mapStyleFor(context),
                        circles: {placeCircle(p, color)},
                        markers: {Marker(markerId: MarkerId(p.id), position: LatLng(p.latitude, p.longitude))},
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                  ),
                ),
              ),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: deep),
                        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                        icon: const Icon(AppIcons.previous, size: 20),
                        label: Text(l10n.placesTitle, style: text.titleMedium?.copyWith(color: deep)),
                      ),
                      const Spacer(),
                      if (reminder.status == ReminderStatus.active)
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: deep, backgroundColor: c.surface),
                          onPressed: () => showPlaceForm(context, editing: reminder),
                          child: Text(l10n.actionEdit, style: text.titleMedium?.copyWith(color: deep)),
                        ),
                      const SizedBox(width: Space.m),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.l, Space.l, 150, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: Space.s,
                          children: [
                            _Chip(text: l10n.typePlace.toUpperCase(), color: deep),
                            _Chip(text: f.context(reminder.context).toUpperCase(), color: c.textSecondary),
                          ],
                        ),
                        const SizedBox(height: Space.m),
                        Text(reminder.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.headlineLarge),
                        const SizedBox(height: Space.xs),
                        Text(line, maxLines: 3, overflow: TextOverflow.ellipsis, style: text.bodyLarge?.copyWith(color: deep)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Zoom that fits the circle inside the snapshot.
  static double _zoomFor(int radius) => radius <= 150 ? 16 : radius <= 400 ? 15 : radius <= 900 ? 14 : 13;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: AppColors.of(context).surface, borderRadius: BorderRadius.circular(Radii.chip)),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: 0.4),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color, this.dot = false});
  final String value;
  final String label;
  final Color? color;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(Space.m + 2, Space.m, Space.m, Space.m),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card + 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                if (dot) ...[
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: c.success, shape: BoxShape.circle)),
                  const SizedBox(width: Space.s),
                ],
                Text(value, maxLines: 1, style: text.headlineMedium?.copyWith(color: color ?? c.textPrimary, fontSize: 22)),
              ],
            ),
          ),
          Text(label, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Done (place color) · Skip · Delete; "Mark as not done" once resolved (OCC-5).
class _Actions extends ConsumerWidget {
  const _Actions({required this.reminder, required this.occurrenceKey, required this.state, required this.color});
  final Reminder reminder;
  final DateTime occurrenceKey;
  final OccurrenceState state;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final a = OccurrenceActions(context, ref);
    final r = reminder;
    final router = GoRouter.of(context);

    Widget button(String label, Color bg, Color fg, VoidCallback onTap, {IconData? icon}) => SizedBox(
      height: 50,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
          textStyle: text.titleMedium,
        ),
        onPressed: onTap,
        icon: icon == null ? null : Icon(icon),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.isResolved)
              button(
                l10n.actionMarkNotDone,
                c.textSecondary,
                Colors.white,
                () => ref.read(servicesProvider).service.setState(r.id, occurrenceKey, OccurrenceState.pending),
                icon: AppIcons.undo,
              )
            else ...[
              button(l10n.actionDone, color, Colors.white, () async {
                await a.done(r, occurrenceKey);
                if (router.canPop()) router.pop();
              }, icon: AppIcons.check),
              const SizedBox(height: Space.m),
              Row(
                children: [
                  Expanded(
                    child: button(l10n.actionSkip, c.surface, c.accent, () async {
                      await a.skip(r, occurrenceKey);
                      if (router.canPop()) router.pop();
                    }),
                  ),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: button(l10n.actionDelete, c.surface, c.danger, () async {
                      if (await a.delete(r, occurrenceKey) && router.canPop()) router.pop();
                    }),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
