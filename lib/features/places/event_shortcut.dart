/// LOC-11 "Remind me when I get there" on Meeting and Event pages: pick the place (searching the
/// calendar event's location when it has one), then the Places form pre-filled with that day and the
/// hours from 1 hour before the start to the end.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import 'place_form.dart';
import 'place_picker_page.dart';

/// [start] / [end] are wall times in the device zone; [allDay] events get Any time.
Future<void> remindWhenThere(
  BuildContext context,
  WidgetRef ref,
  Reminder event, {
  required DateTime start,
  required DateTime end,
  required bool allDay,
}) async {
  final location = ref.read(servicesProvider).calendar.eventFor(event)?.location;
  final place = await pickPlace(context, query: location);
  if (place == null || !context.mounted) return;
  final from = start.subtract(const Duration(hours: 1));
  final day = dateOnly(start);
  await showPlaceForm(
    context,
    place: place,
    date: day,
    // An hour before, but not into the day before (LOC-5 windows belong to their start day).
    hoursFrom: allDay ? null : (dateOnly(from) == day ? ClockTime(from.hour, from.minute) : const ClockTime(0, 0)),
    hoursTo: allDay ? null : ClockTime(end.hour, end.minute),
    linked: LinkedEvent(id: event.id, title: event.title, start: start, calendar: event.isCalendarEvent),
  );
}
