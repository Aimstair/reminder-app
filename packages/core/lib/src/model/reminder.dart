/// Reminder and Occurrence entities (docs/architecture.md §4, behavior-spec TIM/REC/OCC/DAT).
///
/// Wall-clock times are `DateTime`s in UTC used as plain calendar containers (year…minute);
/// their meaning comes from the reminder's time zone (TIM-2/TIM-4).
library;

import 'alert.dart';
import 'enums.dart';

/// Fields every synced row carries (DAT-1, DAT-4).
class RecordMeta {
  const RecordMeta({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.deletedAt,
  });

  /// UUID v7, generated on device.
  final String id;

  /// Instants (UTC).
  final DateTime createdAt;
  final DateTime updatedAt;
  final String deviceId;

  /// Soft delete (DAT-1).
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  RecordMeta touched(DateTime now, {DateTime? deletedAt, bool clearDeleted = false}) => RecordMeta(
    id: id,
    createdAt: createdAt,
    updatedAt: now,
    deviceId: deviceId,
    deletedAt: clearDeleted ? null : (deletedAt ?? this.deletedAt),
  );
}

/// When the thing happens (TIM-*).
class Timing {
  const Timing({required this.type, required this.start, this.end, this.timeZone, this.timeZoneSetManually = false})
    : assert(type == TimingType.datetime || timeZone == null, 'TIM-4: date-only has no time zone');

  final TimingType type;

  /// Wall time (datetime) or the day at 00:00 (date).
  final DateTime start;

  /// Optional end (TIM-11).
  final DateTime? end;

  /// IANA zone for datetime reminders (TIM-2); null for date-only (TIM-4).
  final String? timeZone;

  /// TIM-7: zones set by hand don't move when the default zone changes.
  final bool timeZoneSetManually;
}

/// Where a reminder came from.
sealed class ReminderSource {
  const ReminderSource();

  Map<String, Object?> toJson();

  static ReminderSource fromJson(Map<String, Object?> j) => switch (j['type']) {
    'device_calendar' => DeviceCalendarSource(
      calendarId: j['calendar_id']! as String,
      eventId: j['event_id']! as String,
      seriesId: j['series_id'] as String?,
    ),
    'contact' => ContactSource(
      contactId: j['contact_id']! as String,
      field: j['field']! as String,
      userEditedDate: (j['user_edited_date'] as bool?) ?? false,
    ),
    _ => const ManualSource(),
  };
}

class ManualSource extends ReminderSource {
  const ManualSource();
  @override
  Map<String, Object?> toJson() => {'type': 'manual'};
}

class DeviceCalendarSource extends ReminderSource {
  const DeviceCalendarSource({required this.calendarId, required this.eventId, this.seriesId});
  final String calendarId;
  final String eventId;
  final String? seriesId;
  @override
  Map<String, Object?> toJson() => {
    'type': 'device_calendar',
    'calendar_id': calendarId,
    'event_id': eventId,
    'series_id': seriesId,
  };
}

/// CON-4: birthday / anniversary imported from Contacts.
class ContactSource extends ReminderSource {
  const ContactSource({required this.contactId, required this.field, this.userEditedDate = false});
  final String contactId;

  /// `birthday` | `anniversary`
  final String field;

  /// CON-6: when true, a changed date in Contacts doesn't overwrite the user's edit.
  final bool userEditedDate;
  @override
  Map<String, Object?> toJson() => {
    'type': 'contact',
    'contact_id': contactId,
    'field': field,
    'user_edited_date': userEditedDate,
  };
}

class Reminder {
  const Reminder({
    required this.meta,
    required this.title,
    required this.kind,
    required this.context,
    required this.timing,
    required this.alertPlan,
    this.notes,
    this.rawInput,
    this.rrule,
    this.repeatMode = RepeatMode.fixed,
    this.nagInterval,
    this.source = const ManualSource(),
    this.templateId,
    this.status = ReminderStatus.active,
  });

  final RecordMeta meta;
  final String title;
  final String? notes;

  /// Original typed/spoken text (CAP-8).
  final String? rawInput;
  final Kind kind;
  final ReminderContext context;
  final Timing timing;

  /// RFC 5545 RRULE (REC-1), null for one-time reminders.
  final String? rrule;
  final RepeatMode repeatMode;
  final List<AlertStage> alertPlan;

  /// ALR-9: opt-in nag interval.
  final Duration? nagInterval;
  final ReminderSource source;
  final String? templateId;
  final ReminderStatus status;

  String get id => meta.id;

  /// Completable types (Terms §0): Task always, Occasion per occurrence.
  bool get completable => kind == Kind.task || kind == Kind.occasion;

  bool get repeats => rrule != null;
}

/// One instance of a reminder (OCC-*). Saved only when inside the 14-day window or changed (OCC-6).
class Occurrence {
  const Occurrence({
    required this.meta,
    required this.reminderId,
    required this.occurrenceKey,
    this.state = OccurrenceState.pending,
    this.overrideStart,
    this.overrideEnd,
    this.overrideAlertPlan,
    this.snoozedUntil,
    this.resolvedAt,
    this.alertsSent = const {},
  });

  final RecordMeta meta;
  final String reminderId;

  /// The original (unmodified) start of this instance — identifies it within the series.
  final DateTime occurrenceKey;
  final OccurrenceState state;

  /// REC-12 "this one" edits.
  final DateTime? overrideStart;
  final DateTime? overrideEnd;
  final List<AlertStage>? overrideAlertPlan;

  /// Instant (UTC) the snoozed alert re-fires (NTF-4).
  final DateTime? snoozedUntil;
  final DateTime? resolvedAt;

  /// SCH-6: alarm keys already shown.
  final Set<String> alertsSent;

  String get id => meta.id;
}
