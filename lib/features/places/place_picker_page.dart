/// S-24 Place picker (mockup 12, DS17): search (Android Geocoder), saved-place chips, a map with a fixed
/// center pin and the radius circle drawn live, then name, icon, color and radius (LOC-1).
/// Returns the saved [Place] (new or edited), or null.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../native/place_gateway.dart';
import '../../ui/icons.dart';
import '../../ui/motion.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../../ui/format.dart';
import 'place_format.dart';
import 'place_pin.dart';

/// Opens S-24. [at] starts the pin there (long-press on S-19); [editing] edits a saved place (LOC-2);
/// [query] searches straight away (LOC-11 event location, LOC-16 parsed place name).
Future<Place?> pickPlace(BuildContext context, {GeoPoint? at, Place? editing, String? query}) =>
    Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => PlacePickerPage(at: at, editing: editing, query: query), fullscreenDialog: true),
    );

class PlacePickerPage extends ConsumerStatefulWidget {
  const PlacePickerPage({super.key, this.at, this.editing, this.query});
  final GeoPoint? at;
  final Place? editing;
  final String? query;

  @override
  ConsumerState<PlacePickerPage> createState() => _PlacePickerPageState();
}

class _PlacePickerPageState extends ConsumerState<PlacePickerPage> {
  GoogleMapController? _map;
  late LatLng _center;
  final _search = TextEditingController();
  final _name = TextEditingController();
  String? _address;
  late PlaceIcon _icon;
  late PlaceColor _color;
  late int _radius;
  var _nameEdited = false;
  var _results = <FoundPlace>[];
  var _searching = false;
  var _offline = false;
  var _moved = false;
  Timer? _debounce;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _center = e != null
        ? LatLng(e.latitude, e.longitude)
        : widget.at != null
        ? LatLng(widget.at!.latitude, widget.at!.longitude)
        : const LatLng(20, 0);
    _name.text = e?.name ?? '';
    _nameEdited = e != null;
    _address = e?.address;
    _icon = e?.icon ?? PlaceIcon.pin;
    _color = e?.color ?? PlaceColor.teal;
    _radius = e?.radiusMeters ?? placeDefaultRadius;
    unawaited(_start());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _name.dispose();
    super.dispose();
  }

  PlaceGateway get _gateway => ref.read(servicesProvider).places.gateway;

  /// PRM-9: ask for "while using the app" the first time the picker opens; works without it too.
  Future<void> _start() async {
    if (widget.editing == null && widget.at == null) {
      final granted = await _gateway.requestForeground();
      ref.invalidate(locationStatusProvider);
      if (granted) {
        final here = await _gateway.currentLocation();
        if (here != null && mounted && !_moved) _moveTo(LatLng(here.latitude, here.longitude), zoom: 16);
      }
    } else if (widget.at != null) {
      unawaited(_lookUp(_center));
    }
    final q = widget.query;
    if (q != null && q.isNotEmpty && mounted) {
      _search.text = q;
      await _runSearch(q, pickFirst: true);
    }
  }

  void _moveTo(LatLng at, {double zoom = 16}) {
    setState(() => _center = at);
    unawaited(_map?.animateCamera(CameraUpdate.newLatLngZoom(at, zoom)));
  }

  /// The address under the pin after the user drags the map (name follows unless typed by hand).
  Future<void> _lookUp(LatLng at) async {
    final found = await _gateway.reverseGeocode(at.latitude, at.longitude);
    if (!mounted) return;
    setState(() {
      _address = found?.address;
      if (!_nameEdited) _name.text = found?.name ?? '';
    });
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(q));
  }

  Future<void> _runSearch(String q, {bool pickFirst = false}) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    List<FoundPlace> found;
    try {
      found = await _gateway.search(q, near: (latitude: _center.latitude, longitude: _center.longitude));
      _offline = false;
    } catch (_) {
      found = const [];
      _offline = true;
    }
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = found;
    });
    if (pickFirst && found.isNotEmpty) _choose(found.first);
  }

  void _choose(FoundPlace p) {
    FocusScope.of(context).unfocus();
    setState(() {
      _results = [];
      _search.text = p.name;
      _name.text = p.name;
      _nameEdited = false;
      _address = p.address;
      if (widget.editing == null) _icon = guessPlaceIcon(p.name);
    });
    _moveTo(LatLng(p.latitude, p.longitude));
  }

  Future<void> _myLocation() async {
    if (!await _gateway.requestForeground()) return;
    final here = await _gateway.currentLocation();
    if (here != null && mounted) {
      _moveTo(LatLng(here.latitude, here.longitude));
      unawaited(_lookUp(LatLng(here.latitude, here.longitude)));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final places = ref.read(servicesProvider).places;
    final name = _name.text.trim().isEmpty ? l10n.pickerDefaultName : _name.text.trim();
    final e = widget.editing;
    final Place saved;
    if (e != null) {
      saved = await places.updatePlace(
        e.copyWith(
          name: name,
          latitude: _center.latitude,
          longitude: _center.longitude,
          address: () => _address,
          radiusMeters: _radius,
          icon: _icon,
          color: _color,
        ),
      );
    } else {
      saved = await places.createPlace(
        name: name,
        latitude: _center.latitude,
        longitude: _center.longitude,
        address: _address,
        radiusMeters: _radius,
        icon: _icon,
        color: _color,
      );
    }
    if (mounted) Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final f = Fmt.of(context);
    final saved = widget.editing == null ? (ref.watch(placesProvider).value ?? const <Place>[]) : const <Place>[];
    final top = MediaQuery.paddingOf(context).top;
    final color = c.place(_color);
    final mapHeight = MediaQuery.sizeOf(context).height * 0.36;

    return Scaffold(
      backgroundColor: c.bgGrouped,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: mapHeight + Radii.sheet,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: widget.editing != null || widget.at != null ? 16 : 1.5,
              ),
              style: mapStyleFor(context),
              circles: {
                Circle(
                  circleId: const CircleId('r'),
                  center: _center,
                  radius: _radius.toDouble(),
                  fillColor: color.withValues(alpha: 0.13),
                  strokeColor: color.withValues(alpha: 0.6),
                  strokeWidth: 2,
                ),
              },
              myLocationEnabled: ref.watch(locationStatusProvider).value?.foreground ?? false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              padding: EdgeInsets.only(top: top + 100, bottom: Radii.sheet),
              onMapCreated: (m) => _map = m,
              onCameraMoveStarted: () => _moved = true,
              onCameraMove: (pos) => setState(() => _center = pos.target),
              onCameraIdle: () {
                if (_moved) unawaited(_lookUp(_center));
              },
            ),
          ),
          // Fixed center pin (the map moves under it).
          Positioned(
            left: 0,
            right: 0,
            top: (mapHeight + top + 100) / 2 - 23,
            child: IgnorePointer(child: Center(child: _PinBadge(color: color, icon: _icon))),
          ),
          Positioned(
            right: Space.l,
            top: mapHeight - 60,
            child: _RoundButton(icon: AppIcons.recenter, onTap: _myLocation, tooltip: l10n.pickerMyLocation),
          ),
          // Bottom card: name, icon, color, radius, button.
          Positioned(
            left: 0,
            right: 0,
            top: mapHeight,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.bgGrouped,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              child: ListView(
                padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Space.l),
                children: [
                  const Center(child: SheetGrabber()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.xl, Space.m, Space.xl, 0),
                    child: Row(
                      children: [
                        IconTile(icon: placeIcon(_icon, solid: true), color: color, size: 44),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name.text.isEmpty ? l10n.pickerDefaultName : _name.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleLarge,
                              ),
                              if (_address != null && _address!.isNotEmpty)
                                Text(_address!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GroupCaption(l10n.pickerName),
                  InsetGroup(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Space.l),
                        child: TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: l10n.pickerDefaultName,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                          onChanged: (_) => setState(() => _nameEdited = true),
                        ),
                      ),
                    ],
                  ),
                  GroupCaption(l10n.pickerIcon),
                  InsetGroup(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(Space.s),
                        child: GridView.count(
                          crossAxisCount: 6,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1.15,
                          children: [
                            for (final i in PlaceIcon.values)
                              Semantics(
                                button: true,
                                selected: i == _icon,
                                label: placeIconName(l10n, i),
                                child: Pressable(
                                  onTap: () => setState(() => _icon = i),
                                  child: AnimatedContainer(
                                    duration: Motion.micro,
                                    decoration: BoxDecoration(
                                      color: i == _icon ? color.withValues(alpha: 0.16) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: i == _icon ? color : Colors.transparent, width: 2),
                                    ),
                                    child: Icon(
                                      placeIcon(i, solid: i == _icon),
                                      size: 22,
                                      color: i == _icon ? color : c.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  GroupCaption(l10n.pickerColor),
                  InsetGroup(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.m),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final k in PlaceColor.values)
                              Semantics(
                                button: true,
                                selected: k == _color,
                                label: placeColorName(l10n, k),
                                child: Pressable(
                                  onTap: () => setState(() => _color = k),
                                  child: AnimatedContainer(
                                    duration: Motion.micro,
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: c.place(k),
                                      shape: BoxShape.circle,
                                      boxShadow: k == _color
                                          ? [
                                              BoxShadow(color: c.surface, spreadRadius: 2.5),
                                              BoxShadow(color: c.place(k), spreadRadius: 4.5),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  GroupCaption(l10n.pickerWithin),
                  InsetGroup(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(Space.l, Space.xs, Space.l, Space.xs),
                        child: Row(
                          children: [
                            Text(f.distance(placeMinRadius.toDouble()), style: text.bodySmall),
                            Expanded(
                              child: Slider(
                                value: _radius.toDouble(),
                                min: placeMinRadius.toDouble(),
                                max: placeMaxRadius.toDouble(),
                                divisions: (placeMaxRadius - placeMinRadius) ~/ 50,
                                onChanged: (v) => setState(() => _radius = v.round()),
                              ),
                            ),
                            Text(f.distance(placeMaxRadius.toDouble()), style: text.bodySmall),
                            SizedBox(
                              width: 72,
                              child: Text(
                                f.distance(_radius.toDouble()),
                                textAlign: TextAlign.end,
                                style: text.titleMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.l, 0),
                    child: SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
                        ),
                        child: Text(widget.editing != null ? l10n.pickerSave : l10n.pickerUse),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Top: back + search, results, saved-place chips.
          Positioned(
            left: Space.l,
            right: Space.l,
            top: top + Space.m,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _RoundButton(
                      icon: AppIcons.previous,
                      onTap: () => Navigator.pop(context),
                      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    ),
                    const SizedBox(width: Space.m - 2),
                    Expanded(child: _searchField(l10n, c, text)),
                  ],
                ),
                if (_results.isNotEmpty || (_search.text.isNotEmpty && !_searching && _results.isEmpty && _offline))
                  _resultsCard(l10n, c, text)
                else if (saved.isNotEmpty || widget.editing == null)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.m),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final p in saved) ...[
                            _Chip(
                              icon: placeIcon(p.icon, solid: true),
                              iconColor: c.place(p.color),
                              label: p.name,
                              onTap: () => Navigator.pop(context, p), // reuse a saved place as it is
                            ),
                            const SizedBox(width: Space.s),
                          ],
                          _Chip(icon: AppIcons.myLocation, iconColor: c.accent, label: l10n.pickerMyLocation, onTap: _myLocation),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField(AppLocalizations l10n, AppColors c, TextTheme text) => Container(
    height: 48,
    decoration: BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.row),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 2))],
    ),
    child: Row(
      children: [
        const SizedBox(width: Space.m),
        Icon(AppIcons.search, size: 18, color: c.textSecondary),
        const SizedBox(width: Space.s),
        Expanded(
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.pickerSearchHint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
            ),
            onChanged: _onQuery,
            onSubmitted: (q) => _runSearch(q, pickFirst: true),
          ),
        ),
        if (_searching)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.m),
            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_search.text.isNotEmpty)
          IconButton(
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            icon: Icon(AppIcons.close, size: 16, color: c.textSecondary),
            onPressed: () => setState(() {
              _search.clear();
              _results = [];
            }),
          ),
      ],
    ),
  );

  Widget _resultsCard(AppLocalizations l10n, AppColors c, TextTheme text) => Padding(
    padding: const EdgeInsets.only(top: Space.s),
    child: Material(
      color: c.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(Radii.row),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
        child: _results.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(Space.l),
                child: Text(_offline ? l10n.errorPlaceSearchOffline : l10n.pickerNoResults(_search.text), style: text.bodyMedium),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(indent: 56),
                itemBuilder: (_, n) {
                  final r = _results[n];
                  return FormRow(
                    icon: placeIcon(guessPlaceIcon(r.name), solid: true),
                    color: c.memorial,
                    label: r.name,
                    subtitle: r.address,
                    onTap: () => _choose(r),
                  );
                },
              ),
      ),
    ),
  );
}

/// The fixed center pin (same look as the map pins, 46 dp).
class _PinBadge extends StatelessWidget {
  const _PinBadge({required this.color, required this.icon});
  final Color color;
  final PlaceIcon icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2.5),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: Icon(placeIcon(icon, solid: true), color: Colors.white, size: 23),
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, required this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

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
          child: Icon(icon, size: 22, color: icon == AppIcons.recenter ? c.accent : c.textPrimary),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.iconColor, required this.label, required this.onTap});
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
