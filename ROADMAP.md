# Roadmap — v1 to v4

Companion to [`reminder-app-concept.md`](reminder-app-concept.md). This file owns **phasing**; the concept doc owns **what features mean and how they work**.

| Version | Theme | Platform | Account |
|---|---|---|---|
| **v0** | Foundations & risk spikes | Android (internal) | — |
| **v1.0** | Local-first launch | Android | None needed |
| **v1.1** | Accounts & cloud | Android | Optional sign-in |
| **v1.2** | Depth & polish | Android | Optional |
| **v2** | iOS & cross-device | Android + iOS | Optional (required for sync) |
| **v3** | Web & connected | Android + iOS + Web | Required on web |
| **v4** | Enterprise | All + admin console (web) | Company sign-in (SSO) |

**Strategy (D5):** consumer launch first (v1–v3), enterprise after the consumer product is proven (v4). Early phases keep the data model, backend, and design enterprise-ready (`docs/product-decisions.md` D5).

Sizing: **S** = small, **M** = medium, **L** = large. No calendar dates — each phase ships when its **exit criteria** are met.

---

## v0 — Foundations & Risk Spikes (internal, not released)

**Goal:** prove the three riskiest assumptions before building features on top of them.

**Entry criteria (done):** specs in `docs/` — behavior spec, parser test set, user flows, screens, design direction, copy, competitors, architecture, testing — and `CLAUDE.md`.

| Item | Size | Exit criterion |
|---|---|---|
| Project setup: Flutter app in `C:deveminder-app` (no spaces in path), `packages/core` Dart package, Pigeon bridge skeleton, test runners | S | App runs on the Galaxy A73 via `flutter run`; `dart test` runs in `packages/core` |
| **Exact-alarm spike** — custom Kotlin native module: schedule, fire, notification actions, reboot reschedule | M | Alarms fire within 1 min on Pixel, Samsung, Xiaomi across reboot, Doze, and app kill |
| ✅ **Animation bake-off** — same prototype in React Native and Flutter (`docs/spikes/animation-bakeoff.md`) | M | **Done 2026-10-06 — Flutter selected** (0% dropped frames on Galaxy A73; weighted 3.90 vs 3.15) |
| **Parser spike** — rule-based NL parser in Dart (no chrono-node equivalent) + parse-preview chips | M–L | Passes ≥ 90% of `parser-test-set.md` counted cases |
| Local database + data model (Reminder, Occurrence, UserPrefs) | M | Core logic covered by automated tests |

**Kill/pivot signal:** if exact alarms can't be made reliable, everything else waits.

---

## v1.0 — Local-First Android Launch

**Goal:** a reminder app people trust, with no account and no backend.
**Hero use cases:** never miss an occasion · never pay a late fee · capture in 3 seconds · your calendar, plus the prep.
**Lead message:** occasions + bills (see `docs/competitors.md`).

### Capture
| Feature | Size |
|---|---|
| Quick capture (typed + voice) with parse-preview chips | L |
| Type & context guessed from keywords, shown as chips | S |
| Default time for undated input (tomorrow 9 AM) | S |
| **Share-sheet capture** — share text from any app → pre-filled capture | S |
| Home-screen widget (quick add + next 3 reminders) | M |
| Quick Settings tile | S |
| **Templates** in capture: Birthday, Bill due, Renewal, Free trial, Night out, Appointment *(moved up from v1.2)* | S |

### Reminder engine
| Feature | Size |
|---|---|
| Types as behavior presets (Meeting / Task / Event / Occasion) with contextual defaults | M |
| Personal / Work context | S |
| Recurrence: daily / weekly / monthly / yearly / custom (RRULE), incl. "last business day" | M |
| **Repeat after completion** ("every 3 months after done") | S |
| Completion semantics per type; "I'm prepared" stops occasion escalation | M |
| Floating vs. zoned time | S |

### Alerts
| Feature | Size |
|---|---|
| Alert plans with multiple offsets, **available on every type** (minutes → months) | M |
| "Start by" lead-time preset for tasks with deadlines | S |
| **Nag until done** (opt-in, repeats every N hours until acknowledged) | S |
| Notification actions: Snooze 1h · Tomorrow · Done / I'm prepared | M |
| Reschedule half-sheet | S |
| Rolling 14-day schedule; reschedule on boot / update / timezone change | M |
| Onboarding for notification + exact-alarm permissions; battery-optimization guidance | M |
| **"Send test reminder"** — end-to-end reliability check in onboarding and Settings | S |

### Views & calendar
| Feature | Size |
|---|---|
| **Schedule view** (default): Overdue · Today · Tomorrow · This week · Later, then by month | M |
| **Day view** — all-day strip + hourly time grid (component reused by 3 Day/Week in v1.2) | L |
| **Month view** — month grid with colored labels | M |
| Side drawer (views, filters by type/context/calendar), mini month picker, **[Today]** | M |
| Local search; Completed screen | S |
| Device calendar import (read-only, choose calendars) with auto-tagging | M |
| **Contacts birthday & anniversary import** → real Occasions with prep nudges | S |
| "Remind me" overlay on synced events (no alerts by default) | S |
| In-app daily digest card (overdue + missed) | S |

### Art & motion
| Feature | Size |
|---|---|
| Bell mascot: AI concept → character sheet → vectors → Rive state machine (7 states) | M |
| Onboarding, empty-state, and celebration illustrations (AI → Rive) | M |
| Completion animation + sounds | S |

### Release basics
Local export/import backup file (S) · crash reporting (S) · privacy policy & Play Store listing (S)

### Exit criteria
- Alarm delivery ≥ 99.5% on the device test matrix
- Simple capture in < 3 seconds; parser ≥ 95% on test set
- Crash-free sessions ≥ 99.5%
- Closed beta (20–50 users) run for ≥ 2 weeks before public release

### Not in v1.0
Accounts, cloud sync, email, LLM parsing, templates, iOS, web.

---

## v1.1 — Accounts & Cloud

**Goal:** add optional sign-in and everything that needs a server.

| Feature | Size |
|---|---|
| Backend (auth, sync API, scheduled jobs) — Supabase or Firebase | L |
| Optional sign-in (Google + email) | M |
| First-sign-in upload & merge of local data | M |
| Cloud backup + offline-first sync (last-write-wins per field) | L |
| Email channel: occasion −7d nudge + daily/weekly digest; preferences + one-click unsubscribe | M |
| LLM parsing fallback for low-confidence input (signed-in only) | M |
| Account deletion & data export (Play Store requirement) | S |

**Exit criteria:** sync conflicts lose no data in automated tests; email deliverability verified (SPF/DKIM/DMARC); sign-in is never required for any v1.0 feature.

---

## v1.2 — Depth & Polish

**Goal:** make the core use cases deeper, based on beta feedback.

| Feature | Size |
|---|---|
| **3 Day & Week views** (reuse Day time grid) + drag to reschedule | M |
| **Year view** — 12 mini months, occasions highlighted | S |
| **Prep reminders** linked to a parent event/meeting (move when the parent moves) | M |
| Custom templates (user-defined) | S |
| Quiet hours per context (e.g. no Work alerts on weekends) | S |
| Multiple times per day (e.g. 8 AM & 8 PM) | S |
| Per-type notification channel preferences | S |
| Smart snooze suggestions by type & time of day | S |
| Design & animation polish pass; custom alert sounds | M |

**Exit criteria:** day-30 retention target set and measured; top 5 beta requests triaged into v2 or the cut list.

---

## v2 — iOS & Cross-Device

**Goal:** feature parity on iOS and seamless use across devices.

| Feature | Size |
|---|---|
| iOS app (shared Flutter codebase; builds need a Mac or cloud CI, e.g. Codemagic) | L |
| iOS native module: local notifications with 64-pending limit handling (rolling window), notification categories | M |
| EventKit calendar import + overlay (same model as Android) | M |
| iOS widgets (WidgetKit) + Share Extension capture | M |
| Multi-device sync hardening: Android ↔ iOS; alert dedup so only one device rings for the same reminder | M |
| Wear OS / Apple Watch notification actions (mirrored notifications, no watch app) | S |
| **Start Google OAuth verification for `calendar.readonly`** (needed for v3 web) | S |

**Exit criteria:** iOS alarm delivery matches Android targets; a reminder edited on one device is correct on the other within 1 min.

---

## v3 — Web & Connected

**Goal:** Aimstair on the web, and two-way connections to the outside world.

| Feature | Size |
|---|---|
| Web app at aimstair.app (Flutter Web — re-evaluate vs a separate web client at v3 start); sign-in required | L |
| Google Calendar via OAuth (web) | M |
| Two-way calendar sync — push app reminders out as calendar events | L |
| CalDAV (Outlook / Apple Calendar on web) | M |
| Browser push notifications (web) | M |
| SMS channel — Twilio; phone verification; A2P 10DLC registration | M |
| **Shared reminders** (family / team) — *only if user demand is proven in v1–v2* | L |
| Aimstair platform integration (shared account, cross-app links) | M |

**Exit criteria:** defined at the start of v3 based on usage data.

---

## v4 — Enterprise

**Goal:** sell to teams and companies on top of the proven consumer product.
**Entry criteria:** v3 shipped; consumer retention targets met; at least one company asking to use it for a team.

| Feature | Size |
|---|---|
| Workspaces / organizations (personal workspace stays free) | L |
| Company sign-in: SSO (SAML / OIDC), SCIM user provisioning | L |
| Admin console (web): members, roles, policies, billing | L |
| Shared & assigned reminders (team reminders, handoffs, "remind my team") — promotes the cut "shared reminders" item | L |
| Team calendars & company-wide occasions (e.g. team birthdays, contract renewals) | M |
| Role-based access control + audit logs | M |
| Security & compliance: SOC 2 readiness, data residency options, data retention policies | L |
| Per-seat pricing, invoicing, trials | M |
| Integrations: Microsoft 365 / Outlook calendar, Google Workspace, Slack/Teams notifications (revisits the cut messenger channels) | L |

**Exit criteria:** defined at the start of v4.

---

## Cross-Cutting Throughout

- **Testing:** every phase adds automated tests for its core logic; every alarm/notification change is tested on the real device matrix
- **Feedback:** in-app feedback link from v1.0; review requests at v1.1 onward
- **Analytics (privacy-respecting):** capture time, alert delivery, snooze/done rates, retention — no reminder content collected
- **Cut list stays cut** unless users ask repeatedly: location triggers, messenger channels, attachments/subtasks

## Key Dependencies

```
v0 alarm spike ──► everything in v1.0
v1.1 backend ────► email, LLM parsing, sync ──► v2 cross-device ──► v3 web
v2 OAuth verification (start early) ──► v3 Google Calendar on web
```
