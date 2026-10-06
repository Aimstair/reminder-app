/// Local search (S-40): title and notes, active and archived, case- and accent-insensitive.
library;

import '../model/reminder.dart';

String _fold(String s) {
  const from = 'àáâãäåèéêëìíîïòóôõöùúûüñçý';
  const to = 'aaaaaaeeeeiiiiooooouuuuncy';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : to[i]);
  }
  return b.toString();
}

/// Reminders matching every word of [query], title matches first, then by title.
List<Reminder> searchReminders(Iterable<Reminder> reminders, String query) {
  final words = _fold(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  final hits = <(Reminder, bool)>[];
  for (final r in reminders) {
    if (r.meta.isDeleted) continue;
    final title = _fold(r.title);
    final all = '$title ${_fold(r.notes ?? '')}';
    if (words.every(all.contains)) hits.add((r, words.every(title.contains)));
  }
  hits.sort((a, b) {
    if (a.$2 != b.$2) return a.$2 ? -1 : 1;
    return a.$1.title.toLowerCase().compareTo(b.$1.title.toLowerCase());
  });
  return [for (final h in hits) h.$1];
}
