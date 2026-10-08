/// Reminder and Occurrence entities (docs/architecture.md §4, behavior-spec TIM/REC/OCC/DAT).
///
/// Wall-clock times are `DateTime`s in UTC used as plain calendar containers (year…minute);
/// their meaning comes from the reminder's time zone (TIM-2/TIM-4).
library;

import 'alert.dart';
import 'attachment.dart';
import 'enums.dart';
import 'money.dart';

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
    this.attachments = const [],
    this.amount,
    this.billKind = BillKind.payment,
    this.rawInput,
    this.rrule,
    this.repeatMode = RecurrenceMode.fixed,
    this.nagInterval,
    this.source = const ManualSource(),
    this.templateId,
    this.status = ReminderStatus.active,
  });

  final RecordMeta meta;
  final String title;
  final String? notes;

  /// Links and files (ATT-1).
  final List<Attachment> attachments;

  /// BIL-2: optional amount (bills only).
  final Money? amount;

  /// BIL-1: payment / subscription / free trial (bills only).
  final BillKind billKind;

  /// Original typed/spoken text (CAP-8).
  final String? rawInput;
  final Kind kind;
  final ReminderContext context;
  final Timing timing;

  /// RFC 5545 RRULE (REC-1), null for one-time reminders.
  final String? rrule;
  final RecurrenceMode repeatMode;
  final List<AlertStage> alertPlan;

  /// ALR-9: opt-in nag interval.
  final Duration? nagInterval;
  final ReminderSource source;
  final String? templateId;
  final ReminderStatus status;

  String get id => meta.id;

  /// Completable types (Terms §0): Task and Bill (BIL-1) always, Occasion per occurrence. CAL-3: imported calendar
  /// events never are.
  bool get completable =>
      (kind == Kind.task || kind == Kind.occasion || kind == Kind.bill) && source is! DeviceCalendarSource;

  bool get repeats => rrule != null;

  /// Imported from the device calendar (read-only, CAL-3).
  bool get isCalendarEvent => source is DeviceCalendarSource;

  Reminder copyWith({
    RecordMeta? meta,
    String? title,
    String? Function()? notes,
    List<Attachment>? attachments,
    Money? Function()? amount,
    BillKind? billKind,
    Kind? kind,
    ReminderContext? context,
    Timing? timing,
    List<AlertStage>? alertPlan,
    String? Function()? rrule,
    RecurrenceMode? repeatMode,
    Duration? Function()? nagInterval,
    ReminderSource? source,
    String? Function()? templateId,
    ReminderStatus? status,
  }) => Reminder(
    meta: meta ?? this.meta,
    title: title ?? this.title,
    notes: notes != null ? notes() : this.notes,
    attachments: attachments ?? this.attachments,
    amount: amount != null ? amount() : this.amount,
    billKind: billKind ?? this.billKind,
    rawInput: rawInput,
    kind: kind ?? this.kind,
    context: context ?? this.context,
    timing: timing ?? this.timing,
    alertPlan: alertPlan ?? this.alertPlan,
    rrule: rrule != null ? rrule() : this.rrule,
    repeatMode: repeatMode ?? this.repeatMode,
    nagInterval: nagInterval != null ? nagInterval() : this.nagInterval,
    source: source ?? this.source,
    templateId: templateId != null ? templateId() : this.templateId,
    status: status ?? this.status,
  );
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
