# Technical Architecture — v1.0

How the app is built: modules, libraries, data, and how alarms work. Written so an AI coding session can follow it without guessing. Conventions for every session are summarized in [`CLAUDE.md`](../CLAUDE.md).

**Stack (decided 2026-10-06 by the animation bake-off — [`spikes/animation-bakeoff.md`](spikes/animation-bakeoff.md)):** **Flutter** (stable) + **Dart 3**, Android first. Custom **Kotlin** code for alarms, notifications, and device integrations, connected through **Pigeon** (typed bridge).

**Project location:** `C:\dev\reminder-app` — a path **without spaces** (Android native builds on Windows fail with spaces in the path; see bake-off log).

---

## 1. Big picture

```
┌─────────────────────────────── Flutter app (Dart) ─────────────────────────────────┐
│                                                                                     │
│  UI (screens, views, design system)  ──►  App actions (use cases, Riverpod)         │
│        ▲ reactive queries                      │                                    │
│        │                                       ▼                                    │
│  Data layer (Drift / SQLite: app.db) ◄──  CORE package (pure Dart: model, engine,   │
│                                            parser, planner)                          │
│                                               │ alarm plan (diff)                    │
│                                               ▼                                     │
│                                Pigeon bridge (generated, typed)                     │
└───────────────────────────────────────────────┼─────────────────────────────────────┘
                                                ▼
┌─────────────────────────── Kotlin (android/app/src/main/kotlin) ────────────────────┐
│  native.db: alarms · action_journal · fire_log                                      │
│  AlarmManager · NotificationManager · ActionReceiver · BootReceiver · WorkManager   │
│  CalendarContract reader · Quick Settings tile · home-screen widget · share intent  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**Core idea — "Dart plans, Kotlin executes":**
- Dart decides *what* should fire and *when* (all rules from `behavior-spec.md`).
- Kotlin fires notifications and handles notification buttons **without starting Flutter** — fast and reliable even when the app is closed (`SCH-1`, `NTF-8`).
- Notification taps are written to a journal; Dart reconciles them into the main data the next time it runs.

---

## 2. Project structure

```
C:\dev\reminder-app\
  lib/                          Flutter app
    main.dart                   Bootstrap: Rive init, DB, providers, router
    app/                        Router (go_router), theme, app shell
    features/                   One folder per area: onboarding, capture, schedule, day, month,
                                detail, search, digest, settings, reliability
    ui/                         Design tokens (design-direction.md §3), shared widgets, motion helpers
    data/                       Drift schema, migrations, repositories, backup (DAT-*)
    native/                     Dart side of the Pigeon bridge (generated + thin wrappers)
    integrations/               Contacts, speech, sound, haptics
    l10n/                       ARB files — keys from copy.md (Flutter gen-l10n)
  packages/
    core/                       PURE Dart package — no Flutter imports (enforced: it's a Dart-only package)
      lib/src/model/            Reminder, Occurrence, AlertStage, Prefs, ids
      lib/src/time/             Time zones, DST, anchors, due times (TIM-*)
      lib/src/recurrence/       RRULE expansion + clamps + after-completion (REC-*)
      lib/src/engine/           Occurrence state machine (OCC-*), overdue (OVD-*), digest (DIG-*)
      lib/src/alerts/           Alert plans, nag, templates (ALR-*, TPL-*)
      lib/src/planner/          Builds the alarm set for the 14-day window (SCH-*)
      lib/src/parser/           Natural-language parser (PRS-*, CAP-*) — written in Dart, test-first
      lib/src/calendar/         Auto-tagging, overlays, duplicate matching (CAL-*)
      lib/src/contacts/         Birthday import mapping (CON-*)
      test/                     Unit + parser acceptance tests (run with `dart test`)
  pigeons/                      Pigeon API definitions (source of the generated bridge)
  android/app/src/main/kotlin/  alarms/, notifications/, calendar/, widget/, tile/, share/
  assets/                       fonts (Inter), rive/, sounds/, images
  integration_test/             Flutter integration tests
  maestro/                      End-to-end flows (FL-*)
```

**Dependency rules:**
- `packages/core` depends only on pure-Dart packages (`timezone`, `rrule`, `uuid`) — it runs with plain `dart test`, no device.
- `lib/features/*` may use `core`, `data`, `ui`, `native`, `integrations` — never another feature's internals.
- Only `lib/native/` talks to Kotlin; only `lib/data/` talks to SQLite.

---

## 3. Libraries

Versions checked on pub.dev on 2026-10-06; **re-verify at setup** and pin exact versions. Adding a library not listed here requires updating this table.

| Need | Package | Latest checked | Notes |
|---|---|---|---|
| Framework | Flutter stable (3.47.x) | — | Release/profile builds for any performance judgment |
| Routing | `go_router` | 18.0.2 | Declarative routes, deep links from notifications |
| State | `flutter_riverpod` | 3.4.3 | App actions + UI state; data lives in SQLite |
| Database | `drift` + `drift_flutter` | 2.35.1 / 0.3.1 | Typed schema, migrations, reactive queries. Don't use `sqlite3_flutter_libs` (end-of-life) |
| Time zones | `timezone` + `flutter_timezone` | 0.11.1 / 5.1.1 | IANA database + device zone; DST-safe `TZDateTime` math |
| Recurrence | **Our own** (in `core`) | — | RRULE subset (FREQ, INTERVAL, BYDAY, BYMONTH, BYMONTHDAY, BYSETPOS, UNTIL, COUNT). Not the `rrule` package: RFC 5545 skips short months / non-leap years where we clamp (`REC-3`, `REC-4`) |
| Parser | **Our own** (in `core`) | — | No Dart equivalent of chrono-node; implement `PRS-*` test-first against `parser-test-set.md` |
| IDs | `uuid` | 4.6.0 | UUID v7 |
| Animation | Flutter built-ins (`AnimationController`, physics `SpringSimulation`, implicit animations, slivers) | — | Shared spring presets + `SpringCurve` in `ui/motion` (from the bake-off) |
| Illustrations | `rive` | 0.14.11 | Bell mascot; **use Data Binding** (state-machine inputs are deprecated). Requires `RiveNative.init()`; build step downloads native libs (`dart run rive_native:setup -p android`) |
| Sound | `audioplayers` | 6.8.1 | Completion chime (`PRF-12`); haptics via built-in `HapticFeedback` |
| Calendar | **Own Kotlin** (`CalendarContract`) via Pigeon | — | `device_calendar` is stale (2024); fallback: `device_calendar_plus` (0.10.1, verify maturity) |
| Contacts | `flutter_contacts` | 2.6.0 | Birthday/anniversary dates only (`CON-2`) — verify it reads contact events |
| Speech | `speech_to_text` | 7.5.0 | Voice capture |
| Home-screen widget | **Own Kotlin** (`AppWidgetProvider`) | — | Built without `home_widget`: Dart pushes the next 3 items as JSON via the platform bridge (`updateWidget`) |
| Kotlin coroutines | `kotlinx-coroutines-android` (Gradle) | 1.9.0 | Needed by Pigeon `@async` host methods (calendar permission, backup file pickers) |
| Share sheet | `receive_sharing_intent` | 1.9.0 | Or handle the share intent directly in Kotlin |
| Native bridge | `pigeon` (dev) | 29.0.6 | Typed Dart ↔ Kotlin API generated from `pigeons/` |
| Notifications & alarms | **Own Kotlin** | — | `flutter_local_notifications` (22.3.1) not used for reminders — our native module owns the firing path (§5) |
| i18n | Flutter `gen-l10n` + `intl` | 0.20.3 | ARB files; keys from `copy.md` |
| Crash reporting | `sentry_flutter` | 9.30.1 | No reminder content in reports |
| Analytics | `posthog_flutter` (or similar) | 5.50.15 | Counts and timings only (D4) |
| Tests | `flutter_test`, `test`, `mocktail` (1.0.5), `integration_test`, Maestro | — | Property tests: seeded random generators; `glados` optional (last release 2023 — verify) |

---

## 4. Data model

Derived from `reminder-app-concept.md` and `behavior-spec.md`. Every app table has `id` (UUID v7, generated on device), `created_at`, `updated_at`, `device_id`, `deleted_at` (`DAT-1`, `DAT-4`). Times are stored as ISO strings; instants in UTC plus the IANA zone where relevant.

**`app.db`** — owned by Dart (Drift)

| Table | Key columns |
|---|---|
| `reminders` | title, notes, raw_input, kind, context, timing_type, start_local, end_local, tz (null for date), tz_set_manually, rrule, repeat_mode, alert_plan (JSON), nag_interval, completable, source (JSON: manual / device_calendar / contact), template_id, status |
| `occurrences` | reminder_id, occurrence_key (original start), state, override_start/end, override_alert_plan, snoozed_until, resolved_at, alerts_sent (JSON of stage keys) |
| `calendar_overlays` | calendar_id, event_id, series_id, alert_plan, kind_override, context_override, scope (event/series), orphaned_at |
| `prefs` | key, value (JSON) — all `PRF-*` settings |
| `metrics_queue` | event name, numeric props, timestamp — never content |

**`native.db`** — owned by Kotlin (separate file; Dart accesses it only through the Pigeon API)

| Table | Key columns |
|---|---|
| `alarms` | key (`occurrence_id:stage:nag_seq`), fire_at_utc, exact (bool), payload (JSON: title, body, channel, buttons, deep link, tomorrow_time, late_cutoff) |
| `action_journal` | alarm key, action (done / prepared / snooze / tomorrow / undo), acted_at, applied (bool) |
| `fire_log` | alarm key, scheduled_at, fired_at — delivery metrics (D4) and test reminder (`PRM-7`) |

**Why two files:** each runtime owns exactly one database, so there's no cross-runtime locking or schema-version coupling. The native side holds only what it needs to fire alarms with the app closed.

**Virtual vs saved occurrences (`OCC-6`):** occurrences are computed on the fly for any date range; a row is saved only when it enters the 14-day window or its state changes.

---

## 5. Alarm & notification module (Kotlin)

`android/app/src/main/kotlin/.../alarms` — the **only** code on the alarm-firing path.

**API exposed to Dart (Pigeon)**

| Method | Purpose |
|---|---|
| `sync(List<AlarmSpec>)` | Replace the registered set with this list (diff by key: add, update, cancel) — `SCH-4` |
| `cancel(List<String> keys)` | Cancel specific alarms and remove their notifications (`OCC-4`, `DAT-2`) |
| `getPermissionState()` | Notifications, exact alarm, battery optimization (`PRM-5`) |
| `openPermissionSettings(kind)` | Deep link to the right Android settings screen |
| `readJournal()` / `markApplied(ids)` | Notification actions taken while Flutter wasn't running |
| `scheduleTest()` / `getTestResult()` | Test reminder (`PRM-7`) |
| `getFireLog(since)` | Delivery metrics |
| `readCalendars()` / `readEvents(range, calendarIds)` | Device calendar import (`CAL-*`) |

**Native responsibilities**
- Register alarms with `AlarmManager` exact APIs when allowed; fall back to inexact windows (`SCH-9`).
- On fire: check `fire_log` to never show twice (`SCH-6`), build the notification from `payload`, post it on the right channel, record the fire.
- **Notification buttons** (`ActionReceiver`, no Flutter):
  - **Done / I'm prepared** → write journal, cancel that occurrence's other alarms (prep stages only for prepared), show the 5 s Undo notification (`NTF-9`)
  - **Snooze / Tomorrow** → write journal, register a one-off alarm at the new time using values in the payload (`NTF-4`, `PRF-5`)
  - **Undo** → write journal, restore cancelled alarms whose time is still ahead
- `BootReceiver`, time/time-zone change, app update → re-register from `alarms`; late ones handled per `SCH-7` (cutoff in payload).
- A periodic **WorkManager** job (≈ daily) starts a **background Flutter engine** (Dart entry point marked `@pragma('vm:entry-point')`) to top up the 14-day window and build the digest — not time-critical.

**Why not Dart on fire?** Starting a Flutter engine from a closed app is slow and can be killed by the OS; keeping firing and buttons native protects the 99.5% delivery target (D4).

---

## 6. Key runtime flows

**Save a reminder (FL-2)**
1. UI → `saveReminder(input)` action → validate with `core` → write `reminders` (+ occurrences in window)
2. `core` planner computes alarms for affected occurrences → `native.sync(diff)`
3. Drift reactive query updates the list; animation plays

**App start / resume**
1. `native.readJournal()` → apply each action through the `core` engine (done, snooze…) → `markApplied`
2. Check permissions (`PRM-5`) → banners
3. Recompute window (`SCH-5`), sync alarms, refresh calendar & contacts if due (`CAL-2`, `CON-6`)
4. Build digest if it's past digest time and not yet built today

**Time zone change** → native receiver re-registers instants; on next Dart run, `date` reminders are recomputed (`TIM-15`) and the travel prompt is evaluated (`TIM-8`).

---

## 7. Build & run (Windows, Android)

| Task | Command |
|---|---|
| Develop on phone (hot reload) | `flutter run` |
| Judge performance / animations | `flutter run --profile` or `--release` (never judge in debug) |
| Test alarms & notifications | `flutter run --release` on a real device |
| Release APK | `flutter build apk --release` |
| Play Store bundle | `flutter build appbundle` |
| Core logic tests | `cd packages/core && dart test` |
| App tests | `flutter test` · `flutter test integration_test` |
| E2E | `maestro test maestro/` |
| Regenerate bridge | `dart run pigeon --input pigeons/<file>.dart` |

**Machine notes (from the bake-off):** cap Gradle memory in `android/gradle.properties` (`-Xmx2560m`, 2 workers) — the template's 8 GB exceeds this PC's free RAM; close browsers during first builds; first build is slow (Gradle downloads), later ones ~90 s.

**Later:** iOS builds (v2) need a Mac or cloud CI (e.g. Codemagic); over-the-air updates need a third-party service (e.g. Shorebird).

---

## 8. Cross-cutting rules
- **Spec traceability:** code implementing a rule references its ID in a short comment (`// ALR-11`); tests are named after rule or case IDs.
- **No reminder content** leaves the device in v1.0 (crash reports and analytics are scrubbed).
  - Crash reporting (`lib/integrations/crash_reporting.dart`) is on only in release builds made with `--dart-define=SENTRY_DSN=…`. Sent: error type, stack trace, device/OS/app version. Not sent: messages, exception text, breadcrumbs, screenshots, view hierarchy, user info. Native (Kotlin) crashes go through the Android SDK without the Dart scrubber — keep reminder text out of Kotlin exception messages.
- **Strings** only via l10n keys; **colors/spacing/motion** only via design tokens.
- **Edge-to-edge:** Android 15 draws apps under the system bars — every screen and sheet must respect safe-area insets (bake-off bug: sheet buttons under the navigation bar).
- **Performance budgets** (see `testing.md`): cold start < 2 s on a mid-range phone; capture sheet opens < 150 ms; no dropped frames in scrolling and animations at the device's refresh rate.
- **Accessibility:** every interactive widget has semantics (label, role); supports font scaling and Reduce Motion (`MediaQuery.disableAnimations`) (`design-direction.md` §7).

---

## 9. Ready for v1.1 (not built in v1.0)
- UUIDs + `updated_at` + `device_id` + soft deletes on every row → sync can be added without migrations of identity.
- `isFeatureEnabled(feature)` gate around every cloud feature (D1).
- Alert stages already carry `channels`; email is ignored until v1.1 (`ALR-8`).
