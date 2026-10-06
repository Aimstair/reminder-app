/// Wall time ↔ instant conversion with IANA zones (TIM-2, TIM-13, TIM-14).
library;

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _ready = false;

/// Loads the time zone database once (pure Dart, works in tests and isolates).
void ensureTimeZones() {
  if (_ready) return;
  tzdata.initializeTimeZones();
  _ready = true;
}

/// The instant (UTC) a wall time in [zone] refers to.
/// TIM-13: a time inside a DST gap shifts forward by the gap; TIM-14: in an overlap, the first occurrence.
DateTime wallToInstant(DateTime wall, String zone) {
  ensureTimeZones();
  final loc = tz.getLocation(zone);
  final wallMs = DateTime.utc(wall.year, wall.month, wall.day, wall.hour, wall.minute).millisecondsSinceEpoch;
  final offsetBefore = loc.timeZone(wallMs - const Duration(days: 1).inMilliseconds).offset.inMilliseconds;
  return DateTime.fromMillisecondsSinceEpoch(wallMs - offsetBefore, isUtc: true);
}

/// The wall time (UTC container) of [instant] in [zone].
DateTime instantToWall(DateTime instant, String zone) {
  ensureTimeZones();
  final local = tz.TZDateTime.from(instant.toUtc(), tz.getLocation(zone));
  return DateTime.utc(local.year, local.month, local.day, local.hour, local.minute);
}

/// A wall time after applying TIM-13/14 (e.g. 02:30 on spring-forward day → 03:30).
DateTime normalizeWall(DateTime wall, String zone) => instantToWall(wallToInstant(wall, zone), zone);
