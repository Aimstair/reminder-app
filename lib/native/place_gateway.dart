/// Dart side of the native places module (pigeons/place_api.dart): geofences (LOC-13), location
/// permission (PRM-9, PRM-10), and the picker's location and search (S-24). An interface so services
/// and widgets can be tested with a fake.
library;

import 'package:reminder_core/reminder_core.dart';

import 'place_api.g.dart';

/// PRM-10: what place reminders need to ring.
class LocationStatus {
  const LocationStatus({
    required this.foreground,
    required this.background,
    required this.precise,
    required this.servicesOn,
    required this.playServices,
  });

  final bool foreground;
  final bool background;
  final bool precise;
  final bool servicesOn;
  final bool playServices;

  /// Everything needed for geofences to fire.
  bool get ready => background && precise && servicesOn && playServices;

  static const allGranted = LocationStatus(
    foreground: true,
    background: true,
    precise: true,
    servicesOn: true,
    playServices: true,
  );
}

/// A search hit or the address under a pin.
class FoundPlace {
  const FoundPlace({required this.name, required this.address, required this.latitude, required this.longitude});
  final String name;
  final String address;
  final double latitude;
  final double longitude;
}

typedef GeoPoint = ({double latitude, double longitude});

abstract class PlaceGateway {
  /// LOC-13: replace the registered geofences. Returns how many are watched (LOC-14).
  Future<({int registered, int requested, String? error})> sync(List<GeofencePlan> plans, Duration lateCutoff) async =>
      (registered: plans.length, requested: plans.length, error: null);

  Future<LocationStatus> status() async => LocationStatus.allGranted;
  Future<bool> requestForeground() async => true;
  Future<void> openAppLocationSettings() async {}
  Future<void> openLocationSettings() async {}
  Future<GeoPoint?> currentLocation() async => null;
  Future<List<FoundPlace>> search(String query, {GeoPoint? near}) async => const [];
  Future<FoundPlace?> reverseGeocode(double latitude, double longitude) async => null;
}

/// Used in tests and on platforms without the native module.
class NoopPlaceGateway extends PlaceGateway {}

class PigeonPlaceGateway extends PlaceGateway {
  PigeonPlaceGateway([PlaceHostApi? api]) : _api = api ?? PlaceHostApi();
  final PlaceHostApi _api;

  @override
  Future<({int registered, int requested, String? error})> sync(List<GeofencePlan> plans, Duration lateCutoff) async {
    final r = await _api.syncGeofences([
      for (final p in plans)
        GeofenceSpec(
          placeId: p.place.id,
          latitude: p.place.latitude,
          longitude: p.place.longitude,
          radiusMeters: p.place.radiusMeters,
          arrive: p.arrive,
          leave: p.leave,
          payloadJson: p.payloadJson(lateCutoff: lateCutoff),
        ),
    ]);
    return (registered: r.registered, requested: r.requested, error: r.error);
  }

  @override
  Future<LocationStatus> status() async {
    final s = await _api.getLocationState();
    return LocationStatus(
      foreground: s.foreground,
      background: s.background,
      precise: s.precise,
      servicesOn: s.servicesOn,
      playServices: s.playServices,
    );
  }

  @override
  Future<bool> requestForeground() => _api.requestForegroundLocation();

  @override
  Future<void> openAppLocationSettings() => _api.openAppLocationSettings();

  @override
  Future<void> openLocationSettings() => _api.openLocationSettings();

  @override
  Future<GeoPoint?> currentLocation() async {
    final l = await _api.currentLocation();
    return l == null ? null : (latitude: l.latitude, longitude: l.longitude);
  }

  @override
  Future<List<FoundPlace>> search(String query, {GeoPoint? near}) async => [
    for (final r in await _api.searchPlaces(
      query,
      near == null ? null : LatLng(latitude: near.latitude, longitude: near.longitude),
    ))
      FoundPlace(name: r.name, address: r.address, latitude: r.latitude, longitude: r.longitude),
  ];

  @override
  Future<FoundPlace?> reverseGeocode(double latitude, double longitude) async {
    final r = await _api.reverseGeocode(latitude, longitude);
    return r == null ? null : FoundPlace(name: r.name, address: r.address, latitude: r.latitude, longitude: r.longitude);
  }
}
