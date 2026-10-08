/// Crash reporting (architecture.md §3): Sentry, off unless a DSN is given at build time
/// (`--dart-define=SENTRY_DSN=…`). No reminder content leaves the device (architecture.md §8): no
/// breadcrumbs, screenshots or view hierarchy, and exception messages are dropped (they can quote
/// user text) — only error types and stack traces are sent.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../app/version.dart';

const _dsn = String.fromEnvironment('SENTRY_DSN');

bool get crashReportingEnabled => _dsn.isNotEmpty && kReleaseMode;

/// Runs [app] inside Sentry when enabled, otherwise just runs it.
Future<void> runWithCrashReporting(FutureOr<void> Function() app) async {
  if (!crashReportingEnabled) return app();
  await SentryFlutter.init(
    (o) {
      o.dsn = _dsn;
      o.release = 'reminder-app@$appVersion';
      o.sendDefaultPii = false;
      o.attachScreenshot = false; // view hierarchy is off by default too
      o.attachThreads = false;
      o.enableUserInteractionBreadcrumbs = false;
      o.enableAutoNativeBreadcrumbs = false;
      o.maxBreadcrumbs = 0;
      o.beforeBreadcrumb = (_, _) => null;
      o.beforeSend = (event, _) => scrubEvent(event);
      o.tracesSampleRate = 0; // crashes only, no performance tracing
    },
    appRunner: app,
  );
}

/// Removes everything that could contain user text; keeps error types, stack traces and
/// device/app context.
SentryEvent scrubEvent(SentryEvent e) {
  e
    ..message = null
    ..breadcrumbs = null
    ..user = null
    ..request = null
    // ignore: deprecated_member_use — deprecated but still sent when set; clear it anyway.
    ..extra = null
    ..transaction = null
    ..culprit = null
    ..serverName = null;
  for (final x in e.exceptions ?? const <SentryException>[]) {
    x.value = null;
  }
  return e;
}
