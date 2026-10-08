/// Which icon an item's tile shows (approved mockups, DS11): from its template, then words in the
/// title, then its type. Presentation-only — the UI maps each glyph to an actual icon.
library;

import '../capture/templates.dart';
import '../model/enums.dart';
import '../model/reminder.dart';

enum ItemGlyph { task, meeting, video, event, gift, bill, shopping, call, tooth, medical, food, document, fitness, travel, renewal, trial, nightOut }

/// Keyword groups, checked in order; first hit wins. Whole words, lowercase.
const _keywords = <(ItemGlyph, List<String>)>[
  (ItemGlyph.gift, ['birthday', 'bday', 'anniversary', 'gift']),
  (ItemGlyph.bill, ['pay', 'bill', 'rent', 'invoice', 'tax', 'taxes', 'fee', 'mortgage', 'loan', 'insurance']),
  (ItemGlyph.tooth, ['dentist', 'dental', 'teeth']),
  (ItemGlyph.medical, ['doctor', 'clinic', 'meds', 'medicine', 'pills', 'pharmacy', 'vet', 'checkup', 'hospital']),
  (ItemGlyph.call, ['call', 'phone', 'ring', 'facetime']),
  (ItemGlyph.shopping, ['buy', 'shop', 'shopping', 'groceries', 'grocery', 'return', 'pickup', 'order', 'milk', 'store', 'cleaning']),
  (ItemGlyph.food, ['lunch', 'dinner', 'breakfast', 'brunch', 'restaurant', 'coffee']),
  (ItemGlyph.document, ['report', 'doc', 'document', 'deck', 'slides', 'proposal', 'contract', 'email', 'write', 'review']),
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
    case Template.renewal:
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
  final words = r.title.toLowerCase().split(RegExp(r"[^a-z0-9']+")).where((w) => w.isNotEmpty).toSet();
  if (r.kind == Kind.meeting) return words.any(_videoWords.contains) ? ItemGlyph.video : ItemGlyph.meeting;
  if (r.kind == Kind.occasion) return ItemGlyph.gift;
  for (final (glyph, list) in _keywords) {
    if (list.any(words.contains)) return glyph;
  }
  return r.kind == Kind.event ? ItemGlyph.event : ItemGlyph.task;
}
