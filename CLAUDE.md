# Reminder App — instructions for AI sessions

Reminder app (working name "Reminder App", part of the Aimstair platform). Android first, then iOS, then web. Built entirely with AI assistance — **the specs in `docs/` are the source of truth; code follows them.**

## Status
v0 done. **v1.0 feature-complete (2026-10-07), ready for device testing:** core engine (recurrence, occurrences, planner, digest, templates, calendar/contacts import, search) · Drift data layer + backup · native alarms + platform bridge (calendar, share target, QS tile, widget, backup files) · all v1.0 screens (Schedule/Day/Month, capture, detail, editor, pickers, search, completed, settings, onboarding). Open: device checks of the new native parts, Pixel/Xiaomi alarm matrix, Rive mascot art (vector stand-in in `lib/ui/bell.dart`), Inter font + icon set, crash reporting, store listing. The v0 alarm test screen lives on as Settings → Reliability → Alarm diagnostics (`/diagnostics`). Core enums: `RecurrenceMode` (not RepeatMode) and `ClockTime` (not TimeOfDay) to avoid clashes with Flutter.

## Read before working
| File | Use it for |
|---|---|
| `reminder-app-concept.md` | What the app is, core concepts, positioning |
| `ROADMAP.md` | What's in which version — **don't build features from a later version** |
| `docs/behavior-spec.md` | Exact rules with IDs (`TIM-*`, `REC-*`, `OCC-*`, `ALR-*`, `SCH-*`, `NTF-*`, …) — **wins over everything else** |
| `docs/parser-test-set.md` | Parser rules (`PRS-*`) and acceptance cases |
| `docs/user-flows.md` · `docs/screens.md` | Flows (`FL-*`), screens (`S-*`), view rules (`VW-*`) |
| `docs/design-direction.md` · `docs/copy.md` | Look, motion, tokens · all user-facing text |
| `docs/design/mockups/` | **Approved UI mockups (images) — build screens to match them** |
| `docs/architecture.md` · `docs/testing.md` | Structure, libraries, data model, alarm module · test plan |
| `docs/product-decisions.md` · `docs/competitors.md` | Business decisions (D1–D4) · market context |
| `docs/spikes/animation-bakeoff.md` | Why Flutter; build lessons on this machine |

## Stack
Flutter (stable) · Dart 3 · go_router · flutter_riverpod · Drift (SQLite) · timezone + flutter_timezone · **own recurrence engine and parser** in `packages/core` · Flutter animation APIs + spring presets · rive (use Data Binding) · audioplayers · flutter_contacts · speech_to_text · Pigeon (Dart ↔ Kotlin) · gen-l10n · flutter_test + mocktail + integration_test + Maestro · own Kotlin for alarms, notifications, calendar, widget, Quick Settings tile.
Project lives in `C:\dev\reminder-app` — **never in a path with spaces** (Android native builds fail on Windows).
Don't add a package that isn't in `docs/architecture.md` §3 without asking and updating that table.

## Architecture rules
- `packages/core/` is a **pure Dart package**: no Flutter imports. All behavior rules live here; it runs with `dart test`.
- **Dart plans, Kotlin executes:** Dart computes the alarm set; Kotlin fires notifications and handles notification buttons without starting Flutter. Never put Dart on the alarm-firing path.
- Two databases: `app.db` (Drift, written only by `lib/data/`) and `native.db` (written only by Kotlin; Dart reaches it only through the Pigeon API).
- Features don't import each other's internals.
- Respect safe-area insets everywhere (Android 15 is edge-to-edge).

## Conventions
- Reference rule IDs in a short comment where a rule is implemented: `// ALR-11`.
- Name tests after rule or case IDs: `'REC-3 clamps day 31 to month end'`, `'F9 every other Monday 1:1'`.
- Every change to `packages/core/` comes with tests. Parser changes must keep `parser-test-set.md` cases passing.
- No hard-coded user-facing strings — use l10n (ARB) keys from `docs/copy.md`. No hard-coded colors/spacing/durations — use design tokens.
- IDs are UUIDs generated on device; every row has `created_at`, `updated_at`, `device_id`, `deleted_at`.
- Never send reminder content off the device (crash reports and analytics are scrubbed).
- Keep code simple and readable; prefer small pure functions in `core`.
- Judge animations and performance only in **profile/release** builds, never debug.

## When specs and reality disagree
1. If a rule is missing, ambiguous, or contradicts another: **stop and ask** — don't guess.
2. If a spec change is agreed: update the spec file first, add a row to the decision log at the bottom of `docs/behavior-spec.md`, then change code and tests.
3. A real-world parser miss becomes a new row in `docs/parser-test-set.md` before it's fixed.

## Commands
*(confirmed during v0; Flutter SDK at C:/src/flutter)*
- Run on phone (hot reload): `flutter run` · performance and alarms: `flutter run --release`
- Release APK / Play bundle: `flutter build apk --release` · `flutter build appbundle` (add `--dart-define=SENTRY_DSN=<dsn>` for beta/store builds to turn on crash reporting)
- Core tests: `cd packages/core && dart test` · app tests: `flutter test` · `flutter test integration_test`
- E2E: `maestro/run.sh [flow.yaml]` — **emulator only** (flows wipe app data; the script refuses physical devices). Start the AVD first: `emulator -avd Medium_Phone_API_36.0 -no-window`. Maestro CLI in `~/.maestro`, Java from Android Studio's JBR
- Analyze / format: `flutter analyze` · `dart format .`
- Regenerate Pigeon bridge: `dart run pigeon --input pigeons/<file>.dart`
- Rive native libs (if the build step fails): `dart run rive_native:setup -p android`
- Gradle memory is capped in `android/gradle.properties` (`-Xmx2560m`, Metaspace 1 GB for release lint, 2 workers) — this PC has limited RAM; close browsers during first builds

## Definition of done
Tests pass (core + parser + app), `flutter analyze` clean, rule IDs referenced, strings/tokens used, works in light & dark, safe areas respected, and — for anything touching alarms or notifications — checked on a real Android device in a release build.
