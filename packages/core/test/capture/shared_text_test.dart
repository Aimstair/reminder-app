import 'package:reminder_core/reminder_core.dart';
import 'package:test/test.dart';

void main() {
  test('CAP-12 short text stays as typed, no notes', () {
    expect(splitSharedText('  Call mom Sunday 6pm '), (input: 'Call mom Sunday 6pm', notes: null));
  });

  test('CAP-12 a link-only share leaves the input empty and keeps the link in notes', () {
    const link = 'https://vt.tiktok.com/ZSbbwjYSQ/';
    expect(splitSharedText(link), (input: '', notes: link));
  });

  test('CAP-12 links are removed from short text and kept in notes', () {
    const shared = 'Concert tickets www.example.com/tix on sale Friday 10am';
    expect(splitSharedText(shared), (input: 'Concert tickets on sale Friday 10am', notes: shared));
  });

  test('CAP-12 long text: first sentence is the input, full text in notes', () {
    final shared = 'Dentist appointment Tuesday at 3pm. ${'Please arrive fifteen minutes early with your insurance card. ' * 3}';
    final r = splitSharedText(shared);
    expect(r.input, 'Dentist appointment Tuesday at 3pm.');
    expect(r.notes, shared.trim());
  });
}
