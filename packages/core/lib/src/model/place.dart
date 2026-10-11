/// Places and place reminders (behavior-spec §9c, LOC-1…LOC-16).
library;

import 'prefs.dart';
import 'reminder.dart';

/// LOC-1: icons a place can wear (picker order).
enum PlaceIcon { home, work, store, gym, school, food, health, parking, travel, worship, heart, pin }

/// LOC-1: place colors, from the design tokens (follow light/dark).
enum PlaceColor { blue, indigo, teal, green, orange, pink, red, grey }

/// LOC-4: which days a place reminder can ring.
enum PlaceActive { anyDay, onDate, repeats }

/// LOC-6: once per occurrence, or every arrive/leave (at most once an hour).
enum PlaceRemind { firstTime, everyTime }

/// What happened at the place.
enum PlaceEvent { arrive, leave }

/// LOC-1: radius limits and default, in meters.
const placeMinRadius = 100;
const placeMaxRadius = 2000;
const placeDefaultRadius = 200;

/// LOC-1: a saved location place reminders ring at.
class Place {
  const Place({
    required this.meta,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.radiusMeters = placeDefaultRadius,
    this.icon = PlaceIcon.pin,
    this.color = PlaceColor.teal,
  });

  final RecordMeta meta;
  final String name;
  final double latitude;
  final double longitude;

  /// As found by search; may be empty for a dropped pin.
  final String? address;
  final int radiusMeters;
  final PlaceIcon icon;
  final PlaceColor color;

  String get id => meta.id;

  Place copyWith({
    RecordMeta? meta,
    String? name,
    double? latitude,
    double? longitude,
    String? Function()? address,
    int? radiusMeters,
    PlaceIcon? icon,
    PlaceColor? color,
  }) => Place(
    meta: meta ?? this.meta,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    address: address != null ? address() : this.address,
    radiusMeters: clampRadius(radiusMeters ?? this.radiusMeters),
    icon: icon ?? this.icon,
    color: color ?? this.color,
  );
}

/// LOC-1: radius stays within 100 m – 2 km.
int clampRadius(int meters) => meters < placeMinRadius
    ? placeMinRadius
    : meters > placeMaxRadius
    ? placeMaxRadius
    : meters;

/// LOC-11: the meeting/event a place reminder was made for (shown as "For: {title} · {when}").
class LinkedEvent {
  const LinkedEvent({required this.id, required this.title, required this.start, this.calendar = false});

  /// Reminder id, or the calendar event id when [calendar].
  final String id;
  final String title;

  /// Wall time of the event's start.
  final DateTime start;
  final bool calendar;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'start': start.toIso8601String(),
    'calendar': calendar,
  };

  static LinkedEvent? fromJson(Map<String, Object?>? j) => j == null
      ? null
      : LinkedEvent(
          id: j['id']! as String,
          title: j['title']! as String,
          start: DateTime.parse(j['start']! as String),
          calendar: (j['calendar'] as bool?) ?? false,
        );
}

/// LOC-3: the place part of a place reminder. Its dates live in the reminder's timing and rrule:
/// [PlaceActive.onDate] = the timing date, [PlaceActive.repeats] = timing date + rrule,
/// [PlaceActive.anyDay] = no date (the timing date is just when it was made).
class PlaceTrigger {
  const PlaceTrigger({
    required this.placeId,
    this.onArrive = true,
    this.onLeave = false,
    this.active = PlaceActive.anyDay,
    this.hoursFrom,
    this.hoursTo,
    this.remind = PlaceRemind.firstTime,
    this.paused = false,
    this.linkedEvent,
  }) : assert(onArrive || onLeave, 'LOC-3: Arrive, Leave, or both'),
       assert((hoursFrom == null) == (hoursTo == null), 'LOC-5: both ends or neither');

  final String placeId;
  final bool onArrive;
  final bool onLeave;
  final PlaceActive active;

  /// LOC-5: null = any time.
  final ClockTime? hoursFrom;
  final ClockTime? hoursTo;
  final PlaceRemind remind;

  /// LOC-12
  final bool paused;

  /// LOC-11
  final LinkedEvent? linkedEvent;

  bool get anyTime => hoursFrom == null;

  bool fires(PlaceEvent e) => e == PlaceEvent.arrive ? onArrive : onLeave;

  PlaceTrigger copyWith({
    String? placeId,
    bool? onArrive,
    bool? onLeave,
    PlaceActive? active,
    ClockTime? Function()? hoursFrom,
    ClockTime? Function()? hoursTo,
    PlaceRemind? remind,
    bool? paused,
    LinkedEvent? Function()? linkedEvent,
  }) => PlaceTrigger(
    placeId: placeId ?? this.placeId,
    onArrive: onArrive ?? this.onArrive,
    onLeave: onLeave ?? this.onLeave,
    active: active ?? this.active,
    hoursFrom: hoursFrom != null ? hoursFrom() : this.hoursFrom,
    hoursTo: hoursTo != null ? hoursTo() : this.hoursTo,
    remind: remind ?? this.remind,
    paused: paused ?? this.paused,
    linkedEvent: linkedEvent != null ? linkedEvent() : this.linkedEvent,
  );

  Map<String, Object?> toJson() => {
    'place_id': placeId,
    'arrive': onArrive,
    'leave': onLeave,
    'active': active.name,
    'from': hoursFrom?.minutes,
    'to': hoursTo?.minutes,
    'remind': remind.name,
    'paused': paused,
    'linked': linkedEvent?.toJson(),
  };

  static PlaceTrigger fromJson(Map<String, Object?> j) {
    ClockTime? clock(Object? m) => m == null ? null : ClockTime((m as int) ~/ 60, m % 60);
    final arrive = (j['arrive'] as bool?) ?? true;
    final leave = (j['leave'] as bool?) ?? false;
    return PlaceTrigger(
      placeId: j['place_id']! as String,
      onArrive: arrive || !leave,
      onLeave: leave,
      active: PlaceActive.values.asNameMap()[j['active']] ?? PlaceActive.anyDay,
      hoursFrom: j['to'] == null ? null : clock(j['from']),
      hoursTo: j['from'] == null ? null : clock(j['to']),
      remind: PlaceRemind.values.asNameMap()[j['remind']] ?? PlaceRemind.firstTime,
      paused: (j['paused'] as bool?) ?? false,
      linkedEvent: LinkedEvent.fromJson((j['linked'] as Map?)?.cast<String, Object?>()),
    );
  }
}
