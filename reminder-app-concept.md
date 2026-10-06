# All-in-One Reminder App — Concept & Plan (v2)

Part of the Aimstair platform (aimstair.app)

## Overview

A single, unified reminder app for anything you need to not forget — meetings, tasks, events, and personal occasions (anniversaries, birthdays, bills, night outs). Reminders share one underlying model; **types are presets of behavior**, not separate modules, keeping the app simple to use and simple to build.

**Core principle:** one inbox for anything you need to not forget — fast capture, clean flows, no feature bloat.

**Audience:** both personal and professional use, in one app. A lightweight **Personal / Work context** on each reminder keeps the two separable without splitting the product.

**Positioning — lead with occasions and bills** (from the competitive scan, `docs/competitors.md`):
1. **Occasions that need preparation** *(lead message — rare among competitors)* — "Anniversary Oct 12" really means "buy a gift by Oct 8". Escalating prep nudges + "I'm prepared"; birthdays imported from Contacts on day one.
2. **Bills, renewals, and trials** *(lead message)* — never pay a late fee: nag until done, month-scale lead times, templates for bills/renewals/trials.
3. **Your calendar, but quiet** — calendar events show up without duplicate alerts; add "Remind me" only where prep is needed.
4. **No account needed, works reliably** — local-first on Android, with a built-in reliability check.
- Fast natural-language capture, repeat-after-completion, and nagging are **table stakes** (TickTick, Todoist, Due have them) — we must do them well, but they're not the headline.

---

## Platform & Account Strategy

### Rollout order
1. **Android** (launch platform)
2. **iOS**
3. **Web** (aimstair.app)

### Accounts: local-first, sign-in optional
- The app is **fully usable signed out** — reminders, alerts, quick capture, and device calendar import all work on-device
- **Sign-in unlocks cloud features:**
  - Backup & multi-device sync (required for iOS/web continuity later)
  - Email notifications (we need a verified address)
  - LLM-assisted parsing fallback (network + abuse control)
  - Web access once it ships
- **On first sign-in, local data is uploaded and merged** into the account — never discarded. If the account already has data (e.g. second device), merge by reminder ID and show a one-time summary.

### Implications
- The **device is the source of truth for scheduling alerts**, always. Alerts fire locally even offline or signed out. The server only adds channels (email) and sync.
- Sync must be designed as **offline-first** from day one (each record has `updated_at` + `device_id`; last-write-wins per field is sufficient for v1 since there's no sharing).

---

## Core Concepts

### 1. Reminder types are behavior presets
Choosing a type just pre-fills behavior fields; every field remains editable.

| Behavior | Meeting | Task | Event | Occasion |
|---|---|---|---|---|
| Has fixed time? | yes | optional (due-by) | yes | date only |
| Can be "done"? | no — just passes | **yes** | no | per year |
| Nags when overdue? | no | **yes** (into digest) | no | no |
| Prep lead time? | rarely | no | sometimes | **yes** |
| Default recurrence | none | none | none | yearly |
| Default alerts | 1 ping (−10m) | 1 ping (at time) | 1 ping (−1h) | escalating (−7d, −1d, day-of 9am) |
| Default context | Work | Personal | Personal | Personal |

### 2. "When it happens" ≠ "when to remind me"
Every reminder has its **timing** (when the thing is) and a separate **alert plan** (a list of offsets from that time). Single-ping is just an alert plan with one entry; escalation is several. This is what makes occasions useful.

### 3. Completion semantics
- **Task:** marked done; if overdue, stays visible in red and rolls into the missed-reminder digest
- **Meeting / Event:** auto-passes after its end time; no completion needed
- **Occasion:** done *for this year's occurrence only* — comes back next year
- **"✓ I'm prepared"** action on occasion nudges cancels the remaining escalation stages for that occurrence (escalation without an off-switch is nagging)

### 4. Undated capture
"Buy milk" with no time gets a **default time (tomorrow 9:00 AM)**, shown as an editable chip before saving. No separate "someday" list in v1.

### 5. Time zones (like Google Calendar)
- Every timed reminder has a time zone; new reminders use the user's **default time zone**, editable per reminder
- Changing the default offers to move upcoming reminders too; traveling prompts to switch the default
- Date-only reminders (birthdays, date-only tasks) have **no time zone** — "Oct 12" is Oct 12 wherever you are
- Full rules: `docs/behavior-spec.md` §1

### 6. Context: Personal / Work
- One field per reminder, defaulted from type, editable in one tap
- v1: filter the list by context
- v1.2: quiet hours per context (e.g. no Work alerts on weekends)

---

## Core Features (v1 — Android)

*Email, the digest email, and LLM parsing need sign-in and ship in v1.1; everything else here is v1.0 — see ROADMAP.md.*

### Quick Capture
- Natural-language input, typed or spoken (Android speech-to-text): "call mom Sunday 6pm"
- **Parse preview:** before saving, show what was understood as editable chips — `Call mom · Sun Oct 5 · 6:00 PM · Personal`. Resolves ambiguity ("Friday" said on a Friday, "at 6" AM/PM) without retyping.
- Type and context are guessed from keywords ("meeting", "standup", "birthday", "anniversary", "pay") and shown as chips too
- Target: **capture in under 3 seconds** for a simple reminder
- Entry points: in-app button, **home-screen widget**, **Quick Settings tile**, and **share-sheet capture** (share text from WhatsApp/email → pre-filled capture)

### Reminder Types + Contextual Defaults
- Meeting / Task / Event / Occasion as presets (see table above)
- Selecting a type auto-applies its recurrence and alert defaults *(moved up from v1.1 — without it, types do nothing)*

### Smart Recurrence
- Occasions: yearly by default
- Others: daily / weekly / monthly / custom, incl. business-day rules ("last business day of the month")
- **Repeat after completion:** "every 3 months after I last did it" (filters, haircuts, car service) — next occurrence is calculated from the completion date, not a fixed calendar
- Stored as **RFC 5545 RRULE** strings so future calendar sync and CalDAV interop are nearly free

### Alerts
- Single ping for meetings/tasks/events; escalating for occasions — but **any type can use a multi-stage alert plan**
- Offsets range from minutes to **months** (passport renewal 6 months out, certification expiry)
- **"Start by" preset** for tasks with a deadline (report due Friday → nudge Wednesday)
- **Nag until done** (opt-in): re-alerts every N hours until acknowledged — for bills and critical items
- **Notification actions** (Android allows ~3 buttons): `Snooze 1h` · `Tomorrow` · `Done` (or `I'm prepared` for occasions)
- Custom reschedule opens a small half-sheet, not the full app
- Synced calendar events **do not alert by default** — user can tap "Remind me" on any synced event to add an alert plan

### Views (inspired by Google Calendar)
- **Schedule** (default): one upcoming timeline, grouped Overdue · Today · Tomorrow · This week · Later
- **Day** and **Month** views in v1.0; **3 Day**, **Week**, and **Year** in v1.2 (Year = birthdays, renewals, expiries at a glance)
- Side drawer like Google Calendar: switch views, filter by type / context / calendar
- **Simple search** across all reminders
- Full rules: `docs/screens.md` §1 (`VW-*`)

### Device Calendar Import (read-only)
- Read events via Android's **on-device calendar provider** (`CalendarContract`, `READ_CALENDAR` permission)
- Covers Google, Outlook/Exchange, Samsung, and any account synced to the phone — **works signed out, no Google OAuth verification needed**
- User chooses which calendars to include
- Auto-tagging heuristics:
  - Has other attendees → **Meeting** (context: Work)
  - All-day + yearly recurrence → **Occasion**
  - Everything else → **Event**
  - User corrections are remembered per recurring series
- Synced events are read-only; the app overlays alert plans instead of copying them (prevents duplicates)

### Notifications
- **Push / local notifications** — default channel, free, works offline
- **Email** (signed-in only) — used narrowly in v1:
  - The −7d occasion nudge (when prep requires time)
  - The missed-reminder digest
  - Requires per-user preference + one-click unsubscribe; via Postmark/SendGrid

### Missed-Reminder Digest *(moved up from "nice-to-have")*
- Daily summary (in-app card each morning; email if signed in and opted in) of overdue tasks and missed alerts
- The natural home for "nag when overdue" — one calm summary instead of repeated pings

---

## Android-Specific Requirements (launch blockers)

- **Exact alarms:** reminders must fire on time. Android 12+ restricts exact alarms; Android 14 denies `SCHEDULE_EXACT_ALARM` by default on new installs. Plan an onboarding step that explains and requests it, and degrade gracefully (inexact window + in-app warning) if denied. Evaluate whether the app qualifies for `USE_EXACT_ALARM` under Play policy.
- **Notification permission:** `POST_NOTIFICATIONS` runtime prompt (Android 13+) — ask at the moment the user saves their first reminder, not at launch.
- **Reboot / update survival:** reschedule all pending alarms on `BOOT_COMPLETED`, app update, and time/timezone change.
- **Doze & OEM battery killers:** test on Samsung, Xiaomi, OnePlus; detect aggressive battery optimization and guide the user to exempt the app.
- **Rolling schedule window:** schedule alarms only for the next ~14 days of occurrences and top up daily — keeps the alarm count bounded and carries over cleanly to iOS (64 pending local notifications limit).

---

## Phasing

Version-by-version scope (v0 → v3), sizing, and exit criteria live in **[ROADMAP.md](ROADMAP.md)**. Summary: v1.0 local-first Android launch → v1.1 accounts & cloud → v1.2 depth & polish → v2 iOS & cross-device → v3 web & connected.

---

## Data Model (draft)

```
Reminder
  id                    UUID (generated on device — required for offline-first)
  user_id?              null while signed out
  title, notes
  raw_input             original typed/spoken text (debugging the parser)
  kind                  task | meeting | event | occasion   (preset only)
  context               personal | work
  timing                { type: datetime | date, start, end?, tz?, tz_set_manually }
                        // tz: IANA zone, null for date-only; end optional on every type
  rrule?                RFC 5545 string
  repeat_mode           fixed | after_completion
  alert_plan            [{ offset, channels: [push|email|sms] }]
  completable           bool
  nag_when_overdue      bool
  nag_until_done?       { interval }   opt-in repeat alerts until acknowledged
  source                manual | device_calendar { calendar_id, event_id, series_id }
                        | contact { contact_id, field: birthday | anniversary, user_edited_date }
  status                active | archived
  created_at, updated_at, device_id

Occurrence              (materialized lazily, one per instance of a reminder)
  reminder_id, occurrence_start
  state                 pending | done | skipped | prepared
  snoozed_until?
  alerts_sent[]         per-stage record so alerts never fire twice

CalendarOverlay         (user-added alerts on a read-only synced event)
  source_event_id / series_id, alert_plan, kind_override?, context_override?

UserPrefs                // full list with defaults: docs/behavior-spec.md §12
  default time zone, travel prompt on/off
  day time, nag hours, "Tomorrow" snooze time, late-alert cutoff
  default alert plan per kind
  channel preferences per kind
  digest time, quiet hours per context
  included device calendars
```

The **Occurrence** table is what makes "done this year, back next year" and per-instance snoozing work correctly for recurring reminders.

---

## Technical Decisions

### Decided
- **NLP parsing:** deterministic rule-based parser running **on-device** (instant, offline, private, free) with parse-preview chips. LLM fallback (signed-in only) when parser confidence is low or to classify type/context.
- **Calendar dedup:** overlay, never copy. For manual reminders that predate a sync, *suggest* a merge only when titles are fuzzy-similar **and** times fall within ~30 minutes. Never merge silently.
- **Auto-tagging:** heuristics above, with per-series user corrections remembered.
- **Recurrence format:** RFC 5545 RRULE.
- **Scheduling:** device-authoritative, rolling 14-day window.
- **App stack: Flutter (Dart)** — decided 2026-10-06 by an animation bake-off against React Native (`docs/spikes/animation-bakeoff.md`)
  - Why: on a mid-range Android phone (Galaxy A73), Flutter had **0% dropped frames** in every animation scene vs 0.2–5.9% for React Native, held 120 Hz more often, and felt clearly smoother hands-on; weighted score 3.90 vs 3.15
  - Animation: Flutter's own animation framework (springs, implicit animations, custom painting) + **Rive** for designed sequences (bell mascot, built with Data Binding)
  - Native: custom **Kotlin** (via Pigeon) owns exact alarms, reboot rescheduling, notification actions, calendar import, widget, and Quick Settings tile; no Dart runs on the alarm-firing path
  - Accepted trade-offs: the natural-language parser is written in Dart from scratch; web (v3) uses Flutter Web; iOS builds need a Mac or cloud CI; over-the-air updates need a third-party service
  - Alternatives considered: React Native + Expo (lost the bake-off), Kotlin Multiplatform (weaker web, thinner animation ecosystem)
  - Full details: `docs/architecture.md`

### AI-Assisted Development Guardrails
- **Version control (git) from day one** — every AI change is reviewable and reversible
- **Automated tests for core logic** (recurrence expansion, NLP parser, alert scheduling, sync merge) — the safety net when code isn't reviewed line by line
- **Project instructions file (CLAUDE.md)** recording stack, library choices, and conventions so every AI session stays consistent
- **Stick to mainstream, well-documented libraries** and pin versions; avoid niche packages
- **Test on real Android devices** (Pixel, Samsung, Xiaomi) for every alarm/notification change — this is the one area emulators and AI can't verify

### Open
- **Backend:** sync API + email sender + digest scheduler. Candidates: Supabase, Firebase, or a small custom service.
- **Sync conflict policy** beyond last-write-wins per field (only matters once sharing exists).

---

## Deliberately Cut / Deferred Indefinitely

| Feature | Reason |
|---|---|
| Messenger/WhatsApp/Slack notifications | Each platform requires separate API approval and business verification; high setup cost, low payoff over push + email |
| Location-based reminder triggers | Permissions and battery overhead for marginal value at launch |
| Shared/collaborative reminders | A full sync/accounts/permissions project on its own — v2 candidate if users ask |
| Rich attachments (photos, links, subtasks) | Scope creep from "reminder" toward "project manager" |
| Multiple alert sounds/themes | Cosmetic polish, post-launch only |
| Separate "someday" / undated list | Default-time rule covers it; revisit if users ask |

---

## Changes from v1 of this doc

- Types redefined as **behavior presets**; contextual defaults and search moved into v1
- Added **Personal / Work context** to serve both audiences
- Added **completion semantics**, **lead time vs. alert time**, **"I'm prepared"** escalation stop, **floating time zones**, **parse preview**
- Calendar sync switched from Google OAuth to the **on-device calendar provider** for mobile (works signed out, no verification wait); Google OAuth moved to the web phase
- Synced events **don't alert by default** (avoids duplicating calendar alerts)
- Email narrowed to occasion early-nudges and the digest; digest moved into v1
- Added **local-first / optional sign-in** model and **Android launch requirements**
- Added draft **data model**

---

## Suggested Next Steps

1. ✅ Planning docs, CLAUDE.md, git repo
2. ✅ Animation bake-off → **Flutter**
3. Set up the Flutter project in `C:\dev\reminder-app` (structure per `docs/architecture.md`)
4. Prototype the **quick-capture + parse-preview** flow — it's the core differentiator; validate the < 3s target
5. Spike **exact-alarm reliability** on 3–4 real Android devices (Samsung, Xiaomi, Pixel) before building features on top of it
6. Finalize the data model above and build the local DB + rolling alarm scheduler
