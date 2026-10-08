/// CAP-12: what to put in the capture input and in notes when text arrives from the share sheet.
library;

final _link = RegExp(r'(?:https?://|www\.)\S+', caseSensitive: false);
final _firstSentence = RegExp(r'^(.{1,120}?[.!?])(\s|$)', dotAll: true);

/// [input] is parsed like typed text; [notes] is null when there is nothing to keep.
typedef SharedCapture = ({String input, String? notes});

SharedCapture splitSharedText(String shared) {
  final full = shared.trim();
  final hasLink = _link.hasMatch(full);
  // Links never become the title.
  var input = full.replaceAll(_link, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final long = input.length > 120;
  if (long) {
    final m = _firstSentence.firstMatch(input);
    input = (m?.group(1) ?? input.substring(0, 120)).trim();
  }
  return (input: input, notes: hasLink || long ? full : null);
}
