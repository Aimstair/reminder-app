/// S-19 Places (mockup 11/15, DS17): a map with every place's pin and radius circle, filter chips, and a
/// draggable sheet listing place reminders by place, nearest first. Place reminders are created only
/// here (LOC-3): [+] or a long-press on the map → place picker (S-24) → form (S-25).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../native/place_gateway.dart';
import '../../services/place_service.dart';
import '../../ui/bell.dart';
import '../../ui/format.dart';
import '../../ui/icons.dart';
import '../../ui/motion.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import 'place_form.dart';
import 'place_format.dart';
import 'place_picker_page.dart';
import 'place_pin.dart';

enum _Filter { all, active, paused }

class PlacesPage extends ConsumerStatefulWidget {
  const PlacesPage({super.key});

  @override
  ConsumerState<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends ConsumerState<PlacesPage> with WidgetsBindingObserver {
  GoogleMapController? _map;
  final _sheet = DraggableScrollableController();
  final _headerKeys = <String, GlobalKey>{};
  var _filter = _Filter.all;
  GeoPoint? _here;
  Set<Marker> _markers = {};
  Object? _markerInput;
  var _fitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_locate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sheet.dispose();
    super.dispose();
  }

  /// PRM-10: back from Settings → re-read location access and re-register geofences.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(locationStatusProvider);
      unawaited(ref.read(servicesProvider).places.syncGeofences());
      unawaited(_locate());
    }
  }

  /// Where the user is, for "0.2 mi" and nearest-first — only when location is already allowed (PRM-9).
  Future<void> _locate() async {
    final places = ref.read(servicesProvider).places;
    final status = await places.refreshStatus();
    if (!status.foreground) return;
    final here = await places.gateway.currentLocation();
    if (mounted && here != null) setState(() => _here = here);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final places = ref.watch(placesProvider).value ?? const <Place>[];
    final reminders = ref.watch(placeRemindersProvider) ?? const <Reminder>[];
    final saved = ref.watch(occurrencesProvider).value ?? const <String, Occurrence>{};
    final now = ref.watch(nowProvider).value ?? DateTime.now().toUtc();
    final prefs = ref.watch(prefsProvider);
    final status = ref.watch(locationStatusProvider).value ?? LocationStatus.allGranted;
    final geo = ref.watch(geofenceStateProvider).value ?? const GeofenceState();
    final wall = instantToWall(now, prefs.deviceTimeZone);
    final today = dateOnly(wall);

    bool activeNow(Reminder r) {
      final key = placeKeyAt(r, wall);
      return key != null && placeActiveNow(r, wall, occurrence: saved[AlarmPlanner.occurrenceId(r.id, key)]);
    }

    bool keep(Reminder r) => switch (_filter) {
      _Filter.all => true,
      _Filter.active => activeNow(r) && status.ready,
      _Filter.paused => r.place!.paused,
    };

    final byPlace = <String, List<Reminder>>{};
    for (final r in reminders) {
      if (keep(r)) (byPlace[r.place!.placeId] ??= []).add(r);
    }
    double? away(Place p) => _here == null ? null : metersBetween(_here!.latitude, _here!.longitude, p.latitude, p.longitude);
    final shown = [
      for (final p in places)
        if (_filter == _Filter.all || byPlace.containsKey(p.id)) p,
    ]..sort((a, b) => (away(a) ?? 0).compareTo(away(b) ?? 0) != 0 ? (away(a) ?? 0).compareTo(away(b) ?? 0) : a.name.compareTo(b.name));

    _updateMarkers(shown, byPlace, activeNow, c, status.ready);
    final count = byPlace.values.fold<int>(0, (n, l) => n + l.length);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: c.bgGrouped,
      body: LayoutBuilder(
        builder: (context, box) {
          return Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: _initialCamera(places),
                  style: mapStyleFor(context),
                  circles: {
                    for (final p in shown)
                      placeCircle(p, c.place(p.color), faded: (byPlace[p.id] ?? const []).every((r) => r.place!.paused)),
                  },
                  markers: _markers,
                  myLocationEnabled: status.foreground,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  padding: EdgeInsets.only(top: top + 110, bottom: box.maxHeight * 0.42),
                  onMapCreated: (m) {
                    _map = m;
                    _fit(places);
                  },
                  onLongPress: (at) => _add(at: at),
                ),
              ),
              // Top chrome: back · Places · search, then filter chips (mockup 11).
              Positioned(
                left: Space.l,
                right: Space.l,
                top: top + Space.m,
                child: Row(
                  children: [
                    _CircleButton(
                      icon: AppIcons.previous,
                      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    _TitlePill(title: l10n.placesTitle),
                    const Spacer(),
                    _CircleButton(icon: AppIcons.search, tooltip: l10n.topSearch, onTap: () => context.push('/search')),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: top + Space.m + 56,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Space.l),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: l10n.placesFilterAll,
                        count: reminders.length,
                        on: _filter == _Filter.all,
                        onTap: () => setState(() => _filter = _Filter.all),
                      ),
                      const SizedBox(width: Space.s),
                      _FilterChip(
                        label: l10n.placesFilterActive,
                        dot: c.success,
                        on: _filter == _Filter.active,
                        onTap: () => setState(() => _filter = _Filter.active),
                      ),
                      const SizedBox(width: Space.s),
                      _FilterChip(
                        label: l10n.placesFilterPaused,
                        icon: AppIcons.pause,
                        on: _filter == _Filter.paused,
                        onTap: () => setState(() => _filter = _Filter.paused),
                      ),
                    ],
                  ),
                ),
              ),
              DraggableScrollableSheet(
                controller: _sheet,
                initialChildSize: places.isEmpty ? 0.42 : 0.5,
                minChildSize: 0.18,
                maxChildSize: 0.92,
                snap: true,
                snapSizes: const [0.5],
                builder: (context, scroll) => _Sheet(
                  scroll: scroll,
                  children: [
                    if (places.isEmpty)
                      EmptyState(
                        title: l10n.placesEmptyTitle,
                        sub: l10n.placesEmptySub,
                        compact: true,
                        mood: BellMood.calm,
                        action: l10n.placesEmptyButton,
                        onAction: _add,
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(Space.xl, Space.s, Space.xl, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(child: Text(l10n.placesNearby, style: Theme.of(context).textTheme.headlineMedium)),
                            Text(l10n.placesReminderCount(count), style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      ..._banners(l10n, status, geo),
                      for (final p in shown) ...[
                        _PlaceHeader(
                          key: _headerKeys.putIfAbsent(p.id, GlobalKey.new),
                          place: p,
                          count: (byPlace[p.id] ?? const []).length,
                          distance: away(p) == null ? null : f.distance(away(p)!),
                          onTap: () => _placeMenu(p),
                        ),
                        if (byPlace[p.id] case final list?)
                          InsetGroup(
                            indent: 56,
                            children: [
                              for (final r in list)
                                _PlaceReminderRow(
                                  reminder: r,
                                  color: c.place(p.color),
                                  subline: f.placeSubline(r, today: today),
                                  active: activeNow(r),
                                  ready: status.ready,
                                  onTap: () => context.push('/item/${Uri.encodeComponent(r.id)}/${_segment(r)}'),
                                ),
                            ],
                          ),
                      ],
                    ],
                    const SizedBox(height: 96), // room above the [+] button
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.placesEmptyButton,
        onPressed: _add,
        child: const Icon(AppIcons.add, size: 30),
      ),
    );
  }

  List<Widget> _banners(AppLocalizations l10n, LocationStatus s, GeofenceState geo) {
    final places = ref.read(servicesProvider).places;
    return [
      if (!s.servicesOn)
        InfoBanner(
          text: l10n.placesBannerOff,
          action: l10n.actionTurnOn,
          icon: AppIcons.place,
          onAction: places.gateway.openLocationSettings,
        )
      else if (!s.background)
        InfoBanner(
          text: l10n.placesBannerBackground,
          action: l10n.actionFix,
          icon: AppIcons.place,
          onAction: places.gateway.openAppLocationSettings,
        )
      else if (!s.precise)
        InfoBanner(
          text: l10n.placesBannerPrecise,
          action: l10n.actionFix,
          icon: AppIcons.place,
          onAction: places.gateway.openAppLocationSettings,
        ),
      if (geo.overLimit) InfoBanner(text: l10n.placesBannerLimit, tone: BannerTone.info, icon: AppIcons.info),
    ];
  }

  /// Occurrence segment for the detail route: the current or next active day (any day: its one key).
  String _segment(Reminder r) {
    final prefs = ref.read(prefsProvider);
    final today = dateOnly(instantToWall(DateTime.now().toUtc(), prefs.deviceTimeZone));
    final keys = placeOccurrenceKeys(r, today, addDays(today, 400));
    final key = keys.isNotEmpty ? keys.first : dateOnly(r.timing.start);
    return AlarmPlanner.occurrenceId(r.id, key).split('~').last;
  }

  CameraPosition _initialCamera(List<Place> places) {
    if (places.isNotEmpty) return CameraPosition(target: LatLng(places.first.latitude, places.first.longitude), zoom: 13);
    if (_here != null) return CameraPosition(target: LatLng(_here!.latitude, _here!.longitude), zoom: 14);
    return const CameraPosition(target: LatLng(20, 0), zoom: 1.5);
  }

  /// Fit every place once the map is ready (and once more when the first location arrives).
  void _fit(List<Place> places) {
    final m = _map;
    if (m == null || _fitted) return;
    final points = [
      for (final p in places) LatLng(p.latitude, p.longitude),
      if (_here != null) LatLng(_here!.latitude, _here!.longitude),
    ];
    if (points.isEmpty) return;
    _fitted = true;
    if (points.length == 1) {
      unawaited(m.moveCamera(CameraUpdate.newLatLngZoom(points.single, 15)));
      return;
    }
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    unawaited(
      m.moveCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
          64,
        ),
      ),
    );
  }

  /// Pins are bitmaps; rebuild them only when what they show changes.
  void _updateMarkers(
    List<Place> places,
    Map<String, List<Reminder>> byPlace,
    bool Function(Reminder) activeNow,
    AppColors c,
    bool ready,
  ) {
    final styles = {
      for (final p in places)
        p: PinStyle(
          color: c.place(p.color),
          icon: p.icon,
          count: (byPlace[p.id] ?? const []).length,
          live: ready && (byPlace[p.id] ?? const []).any(activeNow),
          faded: (byPlace[p.id] ?? const []).isNotEmpty && byPlace[p.id]!.every((r) => r.place!.paused),
        ),
    };
    final input = [for (final e in styles.entries) (e.key.id, e.key.latitude, e.key.longitude, e.value)];
    if (_markerInput.toString() == input.toString()) return;
    _markerInput = input;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    unawaited(() async {
      final markers = <Marker>{};
      for (final e in styles.entries) {
        final p = e.key;
        markers.add(
          Marker(
            markerId: MarkerId(p.id),
            position: LatLng(p.latitude, p.longitude),
            icon: await placePinBitmap(e.value, dpr, c.success),
            anchor: const Offset(0.5, 0.5),
            consumeTapEvents: true,
            onTap: () => _focus(p),
          ),
        );
      }
      if (mounted) setState(() => _markers = markers);
      _fit(places);
    }());
  }

  /// Pin tap: camera to the place, sheet scrolls to its group (S-19).
  void _focus(Place p) {
    unawaited(_map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.latitude, p.longitude), 15)));
    final ctx = _headerKeys[p.id]?.currentContext;
    if (ctx != null) unawaited(Scrollable.ensureVisible(ctx, duration: Motion.standard, curve: Motion.spring));
  }

  /// [+] / long-press: pick a place, then fill in the reminder (S-24 → S-25).
  Future<void> _add({LatLng? at}) async {
    final place = await pickPlace(context, at: at == null ? null : (latitude: at.latitude, longitude: at.longitude));
    if (place == null || !mounted) return;
    await showPlaceForm(context, place: place);
  }

  /// Group header tap → Edit place / Delete place (LOC-2).
  Future<void> _placeMenu(Place p) async {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final choice = await showAppSheet<String>(
      context,
      (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetBar(title: p.name),
            InsetGroup(
              children: [
                FormRow(
                  icon: AppIcons.edit,
                  color: c.accent,
                  label: l10n.placeMenuEdit,
                  onTap: () => Navigator.pop(ctx, 'edit'),
                ),
                FormRow(
                  icon: AppIcons.delete,
                  color: c.danger,
                  label: l10n.placeMenuDelete,
                  destructive: true,
                  onTap: () => Navigator.pop(ctx, 'delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'edit') {
      await pickPlace(context, editing: p);
    } else if (choice == 'delete') {
      await deletePlaceWithUndo(context, ref, p);
    }
  }
}

/// LOC-2: "Delete Home?" when it has reminders, then soft delete with Undo.
Future<void> deletePlaceWithUndo(BuildContext context, WidgetRef ref, Place p) async {
  final l10n = AppLocalizations.of(context);
  final places = ref.read(servicesProvider).places;
  final n = (await places.remindersAt(p.id)).length;
  if (!context.mounted) return;
  if (n > 0) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.placeDeleteTitle(p.name)),
        content: Text(l10n.placeDeleteBody(n)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.actionDelete)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }
  final messenger = ScaffoldMessenger.of(context);
  final ids = await places.deletePlace(p);
  showUndoSnackOn(
    messenger,
    l10n.placeDeletedSnack(p.name),
    undoLabel: l10n.actionUndo,
    onUndo: () => unawaited(places.restorePlace(p, ids)),
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.scroll, required this.children});
  final ScrollController scroll;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bgGrouped,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
          children: [const Center(child: SheetGrabber()), ...children],
        ),
      ),
    );
  }
}

/// Group header outside the card, like "Today 4" on Schedule (mockup 02): small solid tile, name,
/// count badge, distance on the right.
class _PlaceHeader extends StatelessWidget {
  const _PlaceHeader({super.key, required this.place, required this.count, required this.distance, required this.onTap});
  final Place place;
  final int count;
  final String? distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, Space.l, Space.xl, Space.s),
          child: Row(
            children: [
              IconTile(icon: placeIcon(place.icon, solid: true), color: c.place(place.color), size: 28, filled: true),
              const SizedBox(width: Space.m - 2),
              Flexible(child: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium)),
              if (count > 0) ...[
                const SizedBox(width: Space.s),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: c.textSecondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                  child: Text('$count', style: text.labelSmall),
                ),
              ],
              const Spacer(),
              if (distance != null) Text(distance!, style: text.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row like a Schedule row: round tinted trigger icon, title, clock + subline, Active pill.
class _PlaceReminderRow extends StatelessWidget {
  const _PlaceReminderRow({
    required this.reminder,
    required this.color,
    required this.subline,
    required this.active,
    required this.ready,
    required this.onTap,
  });
  final Reminder reminder;
  final Color color;
  final String subline;
  final bool active;
  final bool ready;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final t = reminder.place!;
    final paused = t.paused;
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: paused ? 0.45 : 1,
        child: SizedBox(
          height: 62,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.m),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(t.onArrive && !t.onLeave ? AppIcons.arrive : AppIcons.leave, size: 17, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reminder.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyLarge),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(AppIcons.clockSmall, size: 14, color: c.textSecondary),
                          const SizedBox(width: Space.xs),
                          Expanded(
                            child: Text(
                              !ready && !paused ? l10n.placeStatusWaitingAccess : subline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (paused)
                  Text(l10n.placeStatusPaused, style: text.bodySmall)
                else if (active && ready)
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: c.success.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 7, height: 7, decoration: BoxDecoration(color: c.success, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(
                          l10n.placeStatusActive,
                          style: text.labelSmall?.copyWith(color: c.success, fontWeight: FontWeight.w600),
                        ),
                      ],
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: c.surface,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, size: 22, color: c.textPrimary),
        ),
      ),
    );
  }
}

class _TitlePill extends StatelessWidget {
  const _TitlePill({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.place, size: 20, color: c.memorial),
          const SizedBox(width: Space.s),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// Filter chip like Schedule's (mockup 02): black when selected, white otherwise.
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.on, required this.onTap, this.count, this.dot, this.icon});
  final String label;
  final bool on;
  final VoidCallback onTap;
  final int? count;
  final Color? dot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final fg = on ? c.bgGrouped : c.textPrimary;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.micro,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: on ? c.textPrimary : c.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 7),
            ],
            if (icon != null) ...[Icon(icon, size: 15, color: fg.withValues(alpha: 0.7)), const SizedBox(width: 6)],
            Text(label, style: text.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text('$count', style: text.titleSmall?.copyWith(color: fg.withValues(alpha: 0.6))),
            ],
          ],
        ),
      ),
    );
  }
}
