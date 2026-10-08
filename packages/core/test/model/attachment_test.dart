import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

void main() {
  group('ATT-2 links', () {
    test('ATT-2 adds https to a bare address and names it by host', () {
      final a = Attachment.link('www.example.com/tickets');
      expect(a.uri, 'https://www.example.com/tickets');
      expect(a.name, 'example.com');
    });

    test('ATT-2 keeps a typed scheme and title', () {
      final a = Attachment.link('http://intranet.co/x', name: ' Form ');
      expect(a.uri, 'http://intranet.co/x');
      expect(a.name, 'Form');
    });

    test('ATT-2 accepts web, mail and phone links only', () {
      expect(isValidUrl('example.com'), isTrue);
      expect(isValidUrl('https://a.b/c?d=1'), isTrue);
      expect(isValidUrl('mailto:me@x.com'), isTrue);
      expect(isValidUrl('tel:+15551234'), isTrue);
      expect(isValidUrl('not a link'), isFalse);
      expect(isValidUrl('hello'), isFalse);
      expect(isValidUrl('ftp://x.com'), isFalse);
      expect(isValidUrl(''), isFalse);
    });
  });

  test('ATT-1 attachments round-trip through JSON', () {
    const f = Attachment(
      kind: AttachmentKind.file,
      uri: '/data/a.pdf',
      name: 'Lease.pdf',
      mime: 'application/pdf',
      size: 1200,
    );
    expect(Attachment.fromJson(f.toJson()), f);
    final back = Attachment.fromJson(f.toJson());
    expect((back.mime, back.size), ('application/pdf', 1200));
  });

  group('ATT-5 links in notes', () {
    test('ATT-5 finds links and leaves sentence punctuation out', () {
      final l = findLinks('Tickets at https://shop.example.com/a?b=1. Also see www.foo.org, or bar.io!');
      expect(l.map((x) => x.url), ['https://shop.example.com/a?b=1', 'https://www.foo.org', 'https://bar.io']);
      expect(
        'Tickets at https://shop.example.com/a?b=1.'.substring(l.first.start, l.first.end),
        'https://shop.example.com/a?b=1',
      );
    });

    test('ATT-5 plain words and times are not links', () {
      expect(findLinks('Call mom at 3.30 about the 2.5 kg cake'), isEmpty);
    });
  });
}
