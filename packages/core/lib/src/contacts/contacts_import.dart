/// Contacts birthdays & anniversaries (CON-*): each becomes a real yearly Occasion reminder.
library;

import '../model/alert.dart';
import '../model/enums.dart';
import '../model/reminder.dart';
import '../time/calendar.dart';

enum ContactDateField { birthday, anniversary }

/// One date read from a contact (CON-2: nothing else is kept). [year] is often unknown (CON-5).
class ContactDate {
  const ContactDate({
    required this.contactId,
    required this.name,
    required this.field,
    required this.month,
    required this.day,
    this.year,
  });

  final String contactId;
  final String name;
  final ContactDateField field;
  final int month;
  final int day;
  final int? year;

  String get key => '$contactId/${field.name}';
}

/// CON-4 title.
String contactTitle(ContactDate c) =>
    c.field == ContactDateField.birthday ? "${c.name}'s birthday" : "${c.name}'s anniversary";

/// CON-5: the series starts at the next occurrence on or after [today]; Feb 29 keeps BYMONTHDAY=29 (REC-4).
DateTime nextDate(ContactDate c, DateTime today) {
  final t = dateOnly(today);
  var d = clampDay(t.year, c.month, c.day);
  if (d.isBefore(t)) d = clampDay(t.year + 1, c.month, c.day);
  return d;
}

String contactRrule(ContactDate c) => 'FREQ=YEARLY;BYMONTH=${c.month};BYMONTHDAY=${c.day}';

/// CON-4: a new reminder for [c].
Reminder reminderFromContact(ContactDate c, {required RecordMeta meta, required DateTime today}) => Reminder(
  meta: meta,
  title: contactTitle(c),
  kind: Kind.occasion,
  subKind: c.field == ContactDateField.birthday ? SubKind.birthday : SubKind.anniversary, // SUB-1
  context: ReminderContext.personal,
  timing: Timing(type: TimingType.date, start: nextDate(c, today)),
  alertPlan: defaultAlertPlan(Kind.occasion, TimingType.date),
  rrule: contactRrule(c),
  source: ContactSource(contactId: c.contactId, field: c.field.name),
);

/// What a re-scan (CON-6) should do.
class ContactSyncPlan {
  const ContactSyncPlan({required this.add, required this.suggest, required this.update, required this.removed});

  /// New contact dates to import (auto-add on).
  final List<ContactDate> add;

  /// New contact dates to suggest in the digest (auto-add off).
  final List<ContactDate> suggest;

  /// Existing reminders whose contact date changed (and the user didn't edit the date).
  final List<(Reminder, ContactDate)> update;

  /// Reminders whose contact (or date) is gone — kept, shown as "Contact removed".
  final List<Reminder> removed;
}

ContactSyncPlan planContactSync({
  required List<Reminder> existing,
  required List<ContactDate> found,
  required bool autoAdd,
  Set<String> dismissed = const {},
}) {
  final byKey = <String, Reminder>{};
  for (final r in existing) {
    final s = r.source;
    if (s is ContactSource) byKey['${s.contactId}/${s.field}'] = r;
  }
  final foundKeys = {for (final c in found) c.key};
  final add = <ContactDate>[], suggest = <ContactDate>[], update = <(Reminder, ContactDate)>[];
  for (final c in found) {
    final r = byKey[c.key];
    if (r == null) {
      if (dismissed.contains(c.key)) continue;
      (autoAdd ? add : suggest).add(c);
      continue;
    }
    final s = r.source as ContactSource;
    if (s.userEditedDate) continue;
    if (r.rrule != contactRrule(c) || r.title != contactTitle(c)) update.add((r, c));
  }
  final removed = [
    for (final e in byKey.entries)
      if (!foundKeys.contains(e.key) && !e.value.meta.isDeleted) e.value,
  ];
  return ContactSyncPlan(add: add, suggest: suggest, update: update, removed: removed);
}
