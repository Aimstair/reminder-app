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
  final loc = location(zone);
  final clean = DateTime.utc(wall.year, wall.month, wall.day, wall.hour, wall.minute, wall.second);
  final wallMs = clean.millisecondsSinceEpoch;
  const day = 24 * 60 * 60 * 1000;
  // Offsets on either side of this date; at most one DST change lies between them.
  final offEarly = loc.timeZone(wallMs - day).offset.inMilliseconds;
  final offLate = loc.timeZone(wallMs + day).offset.inMilliseconds;
  final valid = <int>[
    for (final off in {offEarly, offLate})
      if (_wallOf(loc, wallMs - off) == clean) wallMs - off,
  ]..sort();
  // Normal: one match. TIM-14 overlap: two → the first. TIM-13 gap: none → earlier offset shifts forward.
  final instant = valid.isNotEmpty ? valid.first : wallMs - offEarly;
  return DateTime.fromMillisecondsSinceEpoch(instant, isUtc: true);
}

DateTime _wallOf(tz.Location loc, int instantMs) {
  final l = tz.TZDateTime.fromMillisecondsSinceEpoch(loc, instantMs);
  return DateTime.utc(l.year, l.month, l.day, l.hour, l.minute, l.second);
}

/// The wall time (UTC container) of [instant] in [zone].
DateTime instantToWall(DateTime instant, String zone) {
  ensureTimeZones();
  final local = tz.TZDateTime.from(instant.toUtc(), location(zone));
  return DateTime.utc(local.year, local.month, local.day, local.hour, local.minute);
}

/// A wall time after applying TIM-13/14 (e.g. 02:30 on spring-forward day → 03:30).
DateTime normalizeWall(DateTime wall, String zone) => instantToWall(wallToInstant(wall, zone), zone);

/// IANA location for [zone]. "UTC" (reported by some devices) isn't in the tz database's location
/// list, so it maps to tz.UTC.
tz.Location location(String zone) {
  ensureTimeZones();
  return zone == 'UTC' ? tz.UTC : tz.getLocation(zone);
}

/// All IANA zone names (S-21c picker), sorted, plus "UTC".
List<String> timeZoneNames() {
  ensureTimeZones();
  return [...tz.timeZoneDatabase.locations.keys.where((z) => z.contains('/') && !z.startsWith('Etc/')), 'UTC']..sort();
}
