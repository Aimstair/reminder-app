/// Links and files attached to a reminder (ATT-1…ATT-6).
library;

enum AttachmentKind { link, file }

class Attachment {
  const Attachment({required this.kind, required this.uri, required this.name, this.mime, this.size});

  /// A web link the user typed or pasted (ATT-2).
  factory Attachment.link(String url, {String? name}) {
    final u = normalizeUrl(url);
    return Attachment(
      kind: AttachmentKind.link,
      uri: u,
      name: (name ?? '').trim().isEmpty ? displayHost(u) : name!.trim(),
    );
  }

  final AttachmentKind kind;

  /// `https://…` for links; the app-private file path for files (ATT-3).
  final String uri;

  /// Shown in lists: the link title or host, or the original file name.
  final String name;
  final String? mime;

  /// Bytes, files only.
  final int? size;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'uri': uri,
    'name': name,
    if (mime != null) 'mime': mime,
    if (size != null) 'size': size,
  };

  static Attachment fromJson(Map<String, Object?> j) => Attachment(
    kind: AttachmentKind.values.asNameMap()[j['kind']] ?? AttachmentKind.link,
    uri: j['uri']! as String,
    name: (j['name'] as String?) ?? '',
    mime: j['mime'] as String?,
    size: (j['size'] as num?)?.toInt(),
  );

  @override
  bool operator ==(Object other) => other is Attachment && other.kind == kind && other.uri == uri && other.name == name;

  @override
  int get hashCode => Object.hash(kind, uri, name);
}

final _scheme = RegExp(r'^[a-z][a-z0-9+.-]*:', caseSensitive: false);

/// ATT-2: "example.com/x" → "https://example.com/x"; schemes the user typed are kept.
String normalizeUrl(String input) {
  final t = input.trim();
  return _scheme.hasMatch(t) ? t : 'https://$t';
}

/// ATT-2: a link must look like a web address (or mailto/tel).
bool isValidUrl(String input) {
  final t = input.trim();
  if (t.isEmpty || t.contains(' ')) return false;
  final u = Uri.tryParse(normalizeUrl(t));
  if (u == null) return false;
  if (u.scheme == 'mailto' || u.scheme == 'tel') return u.path.isNotEmpty;
  return (u.scheme == 'http' || u.scheme == 'https') && u.host.contains('.') && !u.host.endsWith('.');
}

/// "https://www.example.com/a" → "example.com".
String displayHost(String url) {
  final u = Uri.tryParse(url);
  if (u == null || u.host.isEmpty) return url;
  return u.host.startsWith('www.') ? u.host.substring(4) : u.host;
}

/// ATT-5: web links inside notes, as (start, end) spans, so they can be tapped.
final _urlInText = RegExp(
  r'(?:https?://|www\.)[^\s<>"]+|\b[a-z0-9-]+(?:\.[a-z0-9-]+)*\.(?:com|org|net|io|dev|app|co|me|ai|edu|gov)(?:/[^\s<>"]*)?',
  caseSensitive: false,
);

List<({int start, int end, String url})> findLinks(String text) => [
  for (final m in _urlInText.allMatches(text))
    if (_trimmed(m.group(0)!) case final s when s.isNotEmpty)
      (start: m.start, end: m.start + s.length, url: normalizeUrl(s)),
];

/// Trailing punctuation belongs to the sentence, not the link.
String _trimmed(String s) => s.replaceFirst(RegExp(r'[.,;:!?)\]]+$'), '');
