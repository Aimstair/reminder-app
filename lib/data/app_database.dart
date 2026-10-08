/// app.db — owned by Dart, written only by lib/data/ (docs/architecture.md §4).
/// Regenerate after changes: dart run build_runner build
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:reminder_core/reminder_core.dart';

part 'app_database.g.dart';

/// DAT-1 / DAT-4: every synced row carries these.
mixin Synced on Table {
  TextColumn get id => text()(); // UUID v7
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get deviceId => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Wall times are stored as text `YYYY-MM-DDTHH:mm` (or `YYYY-MM-DD` for date-only); their meaning
/// comes from [tz] (TIM-2, TIM-4).
@DataClassName('ReminderRow')
class Reminders extends Table with Synced {
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get attachments => text().nullable()(); // JSON list of Attachment (ATT-1); null = none
  IntColumn get amountMinor => integer().nullable()(); // BIL-2, in the currency's minor units
  TextColumn get currency => text().nullable()(); // BIL-2, ISO 4217
  TextColumn get billKind => text().nullable()(); // BIL-1: payment / subscription / trial; null = payment
  TextColumn get rawInput => text().nullable()();
  TextColumn get kind => textEnum<Kind>()();
  TextColumn get context => textEnum<ReminderContext>()();
  TextColumn get timingType => textEnum<TimingType>()();
  TextColumn get startLocal => text()();
  TextColumn get endLocal => text().nullable()();
  TextColumn get tz => text().nullable()();
  BoolColumn get tzSetManually => boolean().withDefault(const Constant(false))();
  TextColumn get rrule => text().nullable()();
  TextColumn get repeatMode => textEnum<RecurrenceMode>()();
  TextColumn get alertPlan => text()(); // JSON list of AlertStage
  IntColumn get nagMinutes => integer().nullable()();
  BoolColumn get completable => boolean()();
  TextColumn get source => text()(); // JSON ReminderSource
  TextColumn get templateId => text().nullable()();
  TextColumn get status => textEnum<ReminderStatus>()();
}

@DataClassName('OccurrenceRow')
class Occurrences extends Table with Synced {
  TextColumn get reminderId => text().references(Reminders, #id)();
  TextColumn get occurrenceKey => text()(); // original start (wall time)
  TextColumn get state => textEnum<OccurrenceState>()();
  TextColumn get overrideStart => text().nullable()();
  TextColumn get overrideEnd => text().nullable()();
  TextColumn get overrideAlertPlan => text().nullable()(); // JSON
  DateTimeColumn get snoozedUntil => dateTime().nullable()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get alertsSent => text().withDefault(const Constant('[]'))(); // JSON list of alarm keys

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {reminderId, occurrenceKey},
  ];
}

/// CAL-6: user-added alerts on a read-only synced calendar event.
@DataClassName('CalendarOverlayRow')
class CalendarOverlays extends Table with Synced {
  TextColumn get calendarId => text()();
  TextColumn get eventId => text()();
  TextColumn get seriesId => text().nullable()();
  TextColumn get alertPlan => text()(); // JSON
  TextColumn get kindOverride => textEnum<Kind>().nullable()();
  TextColumn get contextOverride => textEnum<ReminderContext>().nullable()();
  TextColumn get scope => text()(); // event | series
  DateTimeColumn get orphanedAt => dateTime().nullable()(); // CAL-8
}

/// PRF-* settings as key → JSON value.
@DataClassName('PrefRow')
class Prefs extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// D4 metrics — event names and numbers only, never reminder content.
@DataClassName('MetricRow')
class MetricsQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get props => text()(); // JSON of numbers
  DateTimeColumn get at => dateTime()();
}

@DriftDatabase(tables: [Reminders, Occurrences, CalendarOverlays, Prefs, MetricsQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'app'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(reminders, reminders.attachments); // ATT-1
      if (from < 3) {
        await m.addColumn(reminders, reminders.amountMinor);
        await m.addColumn(reminders, reminders.currency);
        await m.addColumn(reminders, reminders.billKind);
        // BIL-7: reminders made with the Bill due / Free trial templates become bills.
        await customStatement(
          "UPDATE reminders SET kind = 'bill', bill_kind = 'payment' WHERE template_id = 'billDue'",
        );
        await customStatement(
          "UPDATE reminders SET kind = 'bill', bill_kind = 'trial' WHERE template_id = 'freeTrial'",
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
