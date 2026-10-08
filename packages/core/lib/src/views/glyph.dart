/// Which icon an item's tile shows (approved mockups, DS11): from its template, then words in the
/// title, then its type. Presentation-only — the UI maps each glyph to an actual icon.
library;

import '../capture/templates.dart';
import '../model/enums.dart';
import '../model/reminder.dart';

enum ItemGlyph {
  task,
  meeting,
  video,
  event,
  gift,
  bill,
  shopping,
  call,
  tooth,
  medical,
  food,
  document,
  fitness,
  travel,
  renewal,
  trial,
  nightOut,
  anniversary,
  holiday,
  memorial,
  celebration,
}

/// Keyword groups, checked in order; first hit wins. Whole words, lowercase.
const _keywords = <(ItemGlyph, List<String>)>[
  (ItemGlyph.gift, ['birthday', 'bday', 'anniversary', 'gift']),
  (ItemGlyph.bill, ['pay', 'bill', 'rent', 'invoice', 'tax', 'taxes', 'fee', 'mortgage', 'loan', 'insurance']),
  (ItemGlyph.tooth, ['dentist', 'dental', 'teeth']),
  (ItemGlyph.medical, ['doctor', 'clinic', 'meds', 'medicine', 'pills', 'pharmacy', 'vet', 'checkup', 'hospital']),
  (ItemGlyph.call, ['call', 'phone', 'ring', 'facetime']),
  (
    ItemGlyph.shopping,
    ['buy', 'shop', 'shopping', 'groceries', 'grocery', 'return', 'pickup', 'order', 'milk', 'store', 'cleaning'],
  ),
  (ItemGlyph.food, ['lunch', 'dinner', 'breakfast', 'brunch', 'restaurant', 'coffee']),
  (
    ItemGlyph.document,
    ['report', 'doc', 'document', 'deck', 'slides', 'proposal', 'contract', 'email', 'write', 'review'],
  ),
  (ItemGlyph.fitness, ['gym', 'workout', 'run', 'yoga', 'swim', 'training']),
  (ItemGlyph.travel, ['flight', 'trip', 'travel', 'airport', 'hotel', 'passport', 'visa']),
];

const _videoWords = ['call', 'zoom', 'meet', 'teams', 'video', 'webex'];

ItemGlyph glyphFor(Reminder r) {
  switch (Template.values.where((t) => t.id == r.templateId).firstOrNull) {
    case Template.birthday:
      return ItemGlyph.gift;
    case Template.billDue:
      return ItemGlyph.bill;
    case Template.renewal || Template.subscription:
      return ItemGlyph.renewal;
    case Template.freeTrial:
      return ItemGlyph.trial;
    case Template.nightOut:
      return ItemGlyph.nightOut;
    case Template.appointment:
      return ItemGlyph.medical;
    case null:
      break;
  }
  // SUB-1: a subtype picks the icon (appointments keep tooth/medical from their words below).
  switch (r.subKind?.kind == r.kind ? r.subKind : null) {
    case SubKind.birthday:
      return ItemGlyph.gift;
    case SubKind.anniversary:
      return ItemGlyph.anniversary;
    case SubKind.holiday:
      return ItemGlyph.holiday;
    case SubKind.memorial:
      return ItemGlyph.memorial;
    case SubKind.video:
      return ItemGlyph.video;
    case SubKind.phone:
      return ItemGlyph.call;
    case SubKind.inPerson:
      return ItemGlyph.meeting;
    case SubKind.travel:
      return ItemGlyph.travel;
    case SubKind.social:
      return ItemGlyph.nightOut;
    case SubKind.appointment || null:
      break;
  }
  final words = r.title.toLowerCase().split(RegExp(r"[^a-z0-9']+")).where((w) => w.isNotEmpty).toSet();
  if (r.kind == Kind.meeting) return words.any(_videoWords.contains) ? ItemGlyph.video : ItemGlyph.meeting;
  // An occasion with no subtype: a birthday by its words, otherwise a celebration.
  if (r.kind == Kind.occasion) {
    return words.any(const ['birthday', 'bday'].contains) ? ItemGlyph.gift : ItemGlyph.celebration;
  }
  if (r.kind == Kind.bill) {
    // BIL-1: subscriptions and trials have their own glyphs; payments keep the receipt.
    if (r.billKind == BillKind.subscription) return ItemGlyph.renewal;
    if (r.billKind == BillKind.trial) return ItemGlyph.trial;
    return ItemGlyph.bill;
  }
  for (final (glyph, list) in _keywords) {
    if (list.any(words.contains)) return glyph;
  }
  if (r.subKind == SubKind.appointment) return ItemGlyph.medical;
  return r.kind == Kind.event ? ItemGlyph.event : ItemGlyph.task;
}
