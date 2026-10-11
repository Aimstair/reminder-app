// Pigeon definition for the Dart ↔ Kotlin places bridge: geofences (LOC-13…15), location permission
// and status (PRM-9, PRM-10), current location and place search for the picker (S-24).
// Regenerate: dart run pigeon --input pigeons/place_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/native/place_api.g.dart',
  kotlinOut: 'android/app/src/main/kotlin/app/aimstair/reminder_app/places/PlaceApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'app.aimstair.reminder_app.places'),
  dartPackageName: 'reminder_app',
))

/// One geofence per place (LOC-13). [payloadJson] holds the place's reminders, their active days,
/// hours, remind mode and notification text — Kotlin checks LOC-7 itself when it fires.
class GeofenceSpec {
  GeofenceSpec({
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.arrive,
    required this.leave,
    required this.payloadJson,
  });

  String placeId;
  double latitude;
  double longitude;
  int radiusMeters;
  bool arrive;
  bool leave;
  String payloadJson;
}

/// PRM-10: what place reminders need to ring.
class LocationState {
  LocationState({
    required this.foreground,
    required this.background,
    required this.precise,
    required this.servicesOn,
    required this.playServices,
  });

  /// "While using the app" (or better).
  bool foreground;

  /// "Allow all the time" (Android 10+).
  bool background;

  /// Precise, not approximate.
  bool precise;

  /// Location turned on in quick settings.
  bool servicesOn;

  /// Google Play services available (geofencing needs it).
  bool playServices;
}

class LatLng {
  LatLng({required this.latitude, required this.longitude});
  double latitude;
  double longitude;
}

/// A search or reverse-geocoding result (Android Geocoder).
class PlaceResult {
  PlaceResult({required this.name, required this.address, required this.latitude, required this.longitude});

  /// Feature name ("Trader Joe's") or the first address line.
  String name;
  String address;
  double latitude;
  double longitude;
}

/// Result of a geofence sync (LOC-14).
class GeofenceSyncResult {
  GeofenceSyncResult({required this.registered, required this.requested, required this.error});

  int registered;
  int requested;

  /// Why nothing could be registered (no permission, location off, no Play services); null when fine.
  String? error;
}

@HostApi()
abstract class PlaceHostApi {
  /// Replace the registered geofences with [specs] (LOC-13); over 100 → the nearest 100 (LOC-14).
  @async
  GeofenceSyncResult syncGeofences(List<GeofenceSpec> specs);

  LocationState getLocationState();

  /// PRM-9: precise "while using the app". Returns whether it's granted now.
  @async
  bool requestForegroundLocation();

  /// PRM-9 / PRM-10: "Allow all the time" lives in the app's location settings (Android 11+).
  void openAppLocationSettings();

  /// PRM-10: location services off → the system Location screen.
  void openLocationSettings();

  /// Last known or a fresh fix; null without permission or when nothing is available quickly.
  @async
  LatLng? currentLocation();

  /// S-24 search, biased to [near] when given. Empty when offline or nothing matched.
  @async
  List<PlaceResult> searchPlaces(String query, LatLng? near);

  /// S-24: the address under a dropped pin.
  @async
  PlaceResult? reverseGeocode(double latitude, double longitude);
}
