import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/integrations/crash_reporting.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('crash reports carry no reminder content (architecture.md §8)', () {
    final event = SentryEvent(
      message: SentryMessage('Could not save "Mom\'s birthday Oct 12"'),
      breadcrumbs: [Breadcrumb(message: 'Tapped "Pay rent"')],
      user: SentryUser(id: 'u1', email: 'someone@example.com'),
      exceptions: [
        SentryException(type: 'FormatException', value: 'Bad input: call mom sunday 6pm'),
      ],
      // ignore: deprecated_member_use
      extra: {'input': 'call mom sunday 6pm'},
      transaction: '/item/abc/202610121800',
    );

    final s = scrubEvent(event);

    expect(s.message, isNull);
    expect(s.breadcrumbs, isNull);
    expect(s.user, isNull);
    // ignore: deprecated_member_use
    expect(s.extra, isNull);
    expect(s.transaction, isNull);
    expect(s.exceptions!.single.type, 'FormatException'); // the error type stays
    expect(s.exceptions!.single.value, isNull);
  });

  test('crash reporting is off without a DSN', () {
    expect(crashReportingEnabled, isFalse);
  });
}
