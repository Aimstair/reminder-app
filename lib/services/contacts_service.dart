/// Contacts birthdays & anniversaries (CON-1…8). Reads only those dates (CON-2); all on device.
library;

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:reminder_core/reminder_core.dart';

import '../data/prefs_repository.dart';
import '../data/reminder_repository.dart';
import 'reminder_service.dart';

/// Reads contact dates (flutter_contacts in the app, a fake in tests).
abstract class ContactsReader {
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<List<ContactDate>> dates();
}

class DeviceContactsReader implements ContactsReader {
  @override
  Future<bool> requestPermission() async {
    final s = await FlutterContacts.permissions.request(PermissionType.read); // PRM-8
    return s == PermissionStatus.granted || s == PermissionStatus.limited;
  }

  @override
  Future<bool> hasPermission() async {
    try {
      return await FlutterContacts.permissions.has(PermissionType.read);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ContactDate>> dates() async {
    // CON-2: only the event (dates) property is read — no numbers, emails or addresses.
    final contacts = await FlutterContacts.getAll(properties: {ContactProperty.event});
    final out = <ContactDate>[];
    for (final c in contacts) {
      final name = (c.displayName ?? '').trim();
      final id = c.id;
      if (name.isEmpty || id == null) continue;
      for (final e in c.events) {
        final field = switch (e.label.label) {
          EventLabel.birthday => ContactDateField.birthday,
          EventLabel.anniversary => ContactDateField.anniversary,
          _ => null,
        };
        if (field == null || e.month < 1 || e.day < 1) continue;
        out.add(ContactDate(contactId: id, name: name, field: field, month: e.month, day: e.day, year: e.year));
      }
    }
    return out;
  }
}

class ContactsService {
  ContactsService({required this.reader, required this.prefs, required this.reminders, required this.service});

  final ContactsReader reader;
  final PrefsRepository prefs;
  final ReminderRepository reminders;
  final ReminderService service;

  /// CON-6 suggestions when auto-add is off (shown in the digest).
  List<ContactDate> suggestions = const [];

  bool get enabled => prefs.flag(PrefKeys.contactsImport);

  /// CON-3: what would be imported (all selected by default in the review list).
  Future<List<ContactDate>> preview() async {
    if (!await reader.requestPermission()) return const [];
    final existing = await reminders.everything();
    final plan = planContactSync(existing: existing, found: await reader.dates(), autoAdd: true);
    return plan.add;
  }

  /// CON-3/CON-4: import the chosen dates and turn the feature on.
  Future<int> importSelected(List<ContactDate> chosen, {DateTime? today}) async {
    final t = dateOnly(today ?? DateTime.now().toUtc());
    for (final c in chosen) {
      await reminders.insert(reminderFromContact(c, meta: await reminders.newMeta(), today: t));
    }
    await prefs.set(PrefKeys.contactsImport, true);
    await service.resync();
    return chosen.length;
  }

  Future<void> disable() => prefs.set(PrefKeys.contactsImport, false);

  /// CON-6 re-scan on app open (when on and permitted). CON-8: no permission → nothing changes.
  Future<void> rescan({DateTime? today}) async {
    if (!enabled) return;
    try {
      if (!await reader.hasPermission()) return;
      final t = dateOnly(today ?? DateTime.now().toUtc());
      final plan = planContactSync(
        existing: await reminders.everything(),
        found: await reader.dates(),
        autoAdd: prefs.current.autoAddBirthdays,
        dismissed: prefs.stringSet(PrefKeys.dismissedContacts),
      );
      for (final c in plan.add) {
        await reminders.insert(reminderFromContact(c, meta: await reminders.newMeta(), today: t));
      }
      for (final (r, c) in plan.update) {
        await reminders.update(r.copyWith(
          title: contactTitle(c),
          rrule: () => contactRrule(c),
          timing: Timing(type: TimingType.date, start: nextDate(c, t)),
        ));
      }
      suggestions = plan.suggest;
      if (plan.add.isNotEmpty || plan.update.isNotEmpty) await service.resync();
    } catch (_) {
      // Contacts unavailable — try again next time.
    }
  }

  /// "Contact removed" on the detail screen (CON-6).
  Future<bool> contactExists(String contactId) async {
    try {
      if (!await reader.hasPermission()) return true;
      return (await reader.dates()).any((c) => c.contactId == contactId);
    } catch (_) {
      return true;
    }
  }

  Future<void> addSuggestion(ContactDate c) async {
    await importSelected([c]);
    suggestions = [...suggestions]..remove(c);
  }

  Future<void> dismissSuggestion(ContactDate c) async {
    await prefs.set(PrefKeys.dismissedContacts, [...prefs.stringSet(PrefKeys.dismissedContacts), c.key]);
    suggestions = [...suggestions]..remove(c);
  }
}
