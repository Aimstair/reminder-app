/// Wording for places (copy.md §5b): triggers, active days, hours, distances, icon and color names.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';

extension PlaceFmt on Fmt {
  /// "Arrive" · "Leave" · "Arrive or leave".
  String trigger(PlaceTrigger t) => t.onArrive && t.onLeave
      ? l10n.placeTriggerBoth
      : t.onArrive
      ? l10n.placeTriggerArrive
      : l10n.placeTriggerLeave;

  /// LOC-5: "Any time" or "9 AM – 5 PM".
  String hours(PlaceTrigger t) {
    if (t.anyTime) return l10n.placeHoursAny;
    DateTime w(ClockTime c) => DateTime.utc(2000, 1, 1, c.hour, c.minute);
    return l10n.placeHoursRange(time(w(t.hoursFrom!)), time(w(t.hoursTo!)));
  }

  /// LOC-4: "Any day" · "Sat, Oct 18" · "Every Tuesday".
  String active(Reminder r, {DateTime? today}) => switch (r.place!.active) {
    PlaceActive.anyDay => l10n.placeActiveAny,
    PlaceActive.onDate => date(r.timing.start, today: today),
    PlaceActive.repeats => repeat(r.rrule, RecurrenceMode.fixed, start: r.timing.start),
  };

  /// S-19 row subline: "Arrive · Tue, 6 – 10 PM"; any day is left out ("Leave · Any time").
  String placeSubline(Reminder r, {DateTime? today}) {
    final t = r.place!;
    final when = t.active == PlaceActive.anyDay ? hours(t) : '${active(r, today: today)}, ${hours(t)}';
    return l10n.placeSubline(trigger(t), when);
  }

  /// S-25 summary: "Rings when you arrive at Trader Joe's, weekdays, 9 AM – 5 PM."
  String placeSummary(Reminder r, Place place, {DateTime? today}) {
    final t = r.place!;
    final head = t.onArrive && t.onLeave
        ? l10n.placeSummaryBoth(place.name)
        : t.onArrive
        ? l10n.placeSummaryArrive(place.name)
        : l10n.placeSummaryLeave(place.name);
    final parts = [
      head,
      if (t.active != PlaceActive.anyDay) active(r, today: today).toLowerCase(),
      if (!t.anyTime) hours(t),
    ];
    return '${parts.join(', ')}.';
  }

  /// Radius or distance: meters/km, or feet/miles where the locale uses them (LOC-1).
  String distance(double meters) {
    if (_imperial(locale)) {
      final feet = meters * 3.28084;
      if (feet < 1000) return l10n.distanceFeet((feet / 10).round() * 10);
      final mi = meters / 1609.344;
      return l10n.distanceMiles(mi < 10 ? mi.toStringAsFixed(1) : mi.round().toString());
    }
    if (meters < 1000) return l10n.distanceMeters((meters / 10).round() * 10);
    final km = meters / 1000;
    return l10n.distanceKm(km < 10 ? km.toStringAsFixed(1) : km.round().toString());
  }
}

/// US, Liberia and Myanmar use miles; the UK uses miles on roads too.
bool _imperial(String locale) {
  final region = locale.split(RegExp('[-_]')).skip(1).firstOrNull?.toUpperCase();
  return const {'US', 'LR', 'MM', 'GB'}.contains(region);
}

/// Straight-line distance in meters (haversine).
double metersBetween(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

String placeIconName(AppLocalizations l10n, PlaceIcon i) => switch (i) {
  PlaceIcon.home => l10n.placeIconHome,
  PlaceIcon.work => l10n.placeIconWork,
  PlaceIcon.store => l10n.placeIconStore,
  PlaceIcon.gym => l10n.placeIconGym,
  PlaceIcon.school => l10n.placeIconSchool,
  PlaceIcon.food => l10n.placeIconFood,
  PlaceIcon.health => l10n.placeIconHealth,
  PlaceIcon.parking => l10n.placeIconParking,
  PlaceIcon.travel => l10n.placeIconTravel,
  PlaceIcon.worship => l10n.placeIconWorship,
  PlaceIcon.heart => l10n.placeIconHeart,
  PlaceIcon.pin => l10n.placeIconPin,
};

String placeColorName(AppLocalizations l10n, PlaceColor c) => switch (c) {
  PlaceColor.blue => l10n.placeColorBlue,
  PlaceColor.indigo => l10n.placeColorIndigo,
  PlaceColor.teal => l10n.placeColorTeal,
  PlaceColor.green => l10n.placeColorGreen,
  PlaceColor.orange => l10n.placeColorOrange,
  PlaceColor.pink => l10n.placeColorPink,
  PlaceColor.red => l10n.placeColorRed,
  PlaceColor.grey => l10n.placeColorGrey,
};

/// The icon a new place gets from its name (Home → house, Work → briefcase…); pin otherwise.
PlaceIcon guessPlaceIcon(String name) {
  final n = name.toLowerCase();
  bool has(List<String> w) => w.any(n.contains);
  if (has(['home', 'house', 'apartment'])) return PlaceIcon.home;
  if (has(['work', 'office'])) return PlaceIcon.work;
  if (has(['gym', 'fitness', 'yoga'])) return PlaceIcon.gym;
  if (has(['school', 'college', 'university', 'campus'])) return PlaceIcon.school;
  if (has(['store', 'market', 'shop', 'mart', "trader joe", 'costco', 'target', 'walmart', 'grocery'])) {
    return PlaceIcon.store;
  }
  if (has(['restaurant', 'cafe', 'coffee', 'pizza', 'bar ', 'diner'])) return PlaceIcon.food;
  if (has(['hospital', 'clinic', 'pharmacy', 'doctor', 'dentist'])) return PlaceIcon.health;
  if (has(['parking', 'garage'])) return PlaceIcon.parking;
  if (has(['airport', 'station', 'terminal'])) return PlaceIcon.travel;
  if (has(['church', 'mosque', 'temple', 'synagogue'])) return PlaceIcon.worship;
  return PlaceIcon.pin;
}

/// The color a place is drawn in (LOC-1), from the design tokens.
Color placeColorOf(BuildContext context, PlaceColor c) => AppColors.of(context).place(c);
