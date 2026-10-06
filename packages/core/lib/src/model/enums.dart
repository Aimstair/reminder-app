/// Shared enums for the reminder model (docs/behavior-spec.md, reminder-app-concept.md data model).
library;

/// Reminder type — a behavior preset (concept §Core Concepts 1).
enum Kind { task, meeting, event, occasion }

/// Personal / Work context (concept §Core Concepts 6).
enum ReminderContext { personal, work }

/// TIM-1: a specific time, or a whole day.
enum TimingType { datetime, date }

/// REC-1: fixed calendar repeats, or "N after completion".
enum RecurrenceMode { fixed, afterCompletion }

/// Occurrence lifecycle (OCC-*). `done`, `skipped`, `passed` are terminal.
enum OccurrenceState {
  pending,
  snoozed,
  prepared,
  done,
  skipped,
  passed;

  bool get isResolved => this == done || this == skipped || this == passed;
}

/// Reminder record status (DAT-3).
enum ReminderStatus { active, archived }

/// Alert delivery channel (ALR-8: only push in v1.0).
enum AlertChannel { push, email, sms }
