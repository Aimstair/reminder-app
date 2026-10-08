# Test & Quality Plan — v1.0

How we know the app works — especially that **reminders fire on time**, which is the whole product (D4). Because the app is built with AI, tests are the main safety net: code is trusted when tests that trace back to the specs pass.

Related: [`behavior-spec.md`](behavior-spec.md) · [`parser-test-set.md`](parser-test-set.md) · [`architecture.md`](architecture.md)

---

## 1. Test levels

| Level | What | Tool | Runs |
|---|---|---|---|
| **Unit — core** | Every rule in `behavior-spec.md`: time, recurrence, state machine, alerts, planner, digest, calendar matching, contacts mapping, templates | `dart test` in `packages/core` (no device) | Every change |
| **Property-based** | Recurrence + time zones + DST over thousands of random dates/zones | Seeded random generators in `dart test` (`glados` optional — verify maintenance) | Every change |
| **Parser acceptance** | One test per row in `parser-test-set.md` (A1…N6), fixed "now" | `dart test` | Every change |
| **Data** | Migrations, repositories, soft delete, backup round-trip (`DAT-5`) | `flutter test` + Drift in-memory database | Every change |
| **Native unit** | Alarm diffing, payload → notification, action receiver logic | JUnit + Robolectric (Kotlin) | Every native change |
| **Widget** | Key widgets render in light/dark, large fonts, safe areas; golden (screenshot) tests for key screens | `flutter test` (widget + golden tests), `mocktail` | Every change |
| **Integration** | Dart ↔ Kotlin bridge on a device: sync alarms, read journal, permissions | `integration_test` | Every native/bridge change |
| **End-to-end** | User flows FL-1…FL-18 on a release build | Maestro (uses Flutter semantics labels) | Before each beta build |
| **Device reliability** | Alarm delivery under real conditions (§3) | Manual script + `fire_log` | Before each beta and release |
| **Smoothness** | Dropped frames per scenario (bake-off method, §4) | `spikes/tools/measure.sh`-style adb script + SurfaceFlinger TimeStats | Before each beta |

**Coverage targets:** `packages/core` ≥ 90% lines and **every rule ID has at least one test**; other layers: critical paths covered by e2e.

**Traceability:** test names start with the rule or case ID — `"ALR-11 nag moves outside nag hours to next window start"`, `"F9 every other Monday 1:1"`. A script lists rule IDs in `behavior-spec.md` with no matching test; it must return empty before release.

---

## 2. Time & recurrence test matrix

Run through property tests and fixed cases:

| Area | Cases |
|---|---|
| DST | US spring-forward gap (`TIM-13`), fall-back overlap (`TIM-14`), EU dates (last Sun of Mar/Oct), zones without DST |
| Zones | Reminder zone ≠ device zone (`TIM-6`); default zone change both options (`TIM-7`); travel (`TIM-8`, `TIM-15`); half-hour zones (India, Newfoundland) |
| Month ends | 29–31 clamp (`REC-3`), Feb 29 yearly (`REC-4`), last business day (`REC-5`) |
| After completion | Done early / late / skipped (`REC-6`, `REC-7`) |
| Edits | This one / this and future (`REC-12`, `REC-13`) mid-series |
| Alerts | Past stages at save (`ALR-6`), month offsets (`ALR-3`), nag windows (`ALR-11`), prepared (`OCC-3`) |
| Window | 14-day boundary, alarm cap 400 (`SCH-3`), idempotent keys (`SCH-4`) |

---

## 3. Alarm reliability script (real devices)

**Device matrix** (minimum):

| Device | Android | Why |
|---|---|---|
| Google Pixel (recent) | 15 / 16 | Reference behavior |
| Samsung Galaxy A-series (mid-range) | 14+ | Most common; aggressive battery management |
| Xiaomi / Redmi | 13+ | Most aggressive app killing |
| Older device | 12 | Exact-alarm permission introduced; low memory |

**Scenarios** — each must deliver within 1 minute of scheduled time:

| # | Scenario | Pass |
|---|---|---|
| R1 | App in foreground | ✅ on time |
| R2 | App in background | ✅ on time |
| R3 | App swiped away from recents | ✅ on time |
| R4 | Phone locked, idle 2+ hours (Doze) | ✅ on time |
| R5 | Reboot before fire time, app not opened after | ✅ on time |
| R6 | Phone off during fire time, on 30 min later | Shown as late (`SCH-7`) |
| R7 | Phone off 3 h past fire time (cutoff 2 h) | Not shown; in digest as missed |
| R8 | Time zone changed manually | Datetime keeps instant; date-only follows device (`TIM-15`) |
| R9 | Exact alarm permission revoked | Inexact ≤ 10 min + banner (`SCH-9`) |
| R10 | Notifications disabled | No crash; banner; counted missed (`PRM-1`) |
| R11 | Done / Snooze / Tomorrow / Undo from lock screen, app closed | State correct after next app open (journal) |
| R12 | Nag sequence over a night | Stops at end of nag hours, resumes at start (`ALR-11`) |
| R13 | 50 reminders at the same minute | All fire on time, grouped (`SCH-10`); Android shows at most ~50 per app at once (accepted 2026-10-08) |
| R14 | App updated (new build installed) | Alarms still registered |
| R15 | Test reminder (`PRM-7`) with phone locked | ✅ result shown on return |

**Measurement:** `fire_log` (scheduled vs fired) exported after each run; target ≥ 99.5% within 1 min across the matrix (D4).

---

## 4. Performance & UX budgets

| Metric | Budget | How measured |
|---|---|---|
| Cold start to interactive | < 2 s (mid-range) | Startup trace |
| Capture sheet open | < 150 ms | Interaction trace |
| Simple capture (open → saved) | < 3 s median | Analytics in beta |
| Parser response per keystroke | < 30 ms | Unit benchmark |
| Scrolling & animations | 60 fps, no dropped-frame bursts | Perf monitor on mid-range device |
| Rive file size | < 500 KB each | Build check |
| Notification action | < 1 s (`NTF-8`) | Manual + fire_log |

---

## 5. Accessibility & visual checks
- Every screen in **light and dark** themes (screenshot tests for key screens)
- Font scale **200%**: no clipped text on rows, chips, sheets, grids
- **TalkBack** pass on onboarding, capture, list, detail, settings
- **Reduce Motion** on: no movement animations, celebrations skipped
- Contrast check on all token pairs (WCAG AA)

---

## 6. Beta plan
- **Closed beta:** 20–50 testers (mix of personal and work users, several Samsung/Xiaomi owners), ≥ 2 weeks (ROADMAP v1.0 exit)
- In-app feedback link; weekly review of crash reports, `fire_log` delivery rate, capture time, and parser misses
- **Every parser miss reported becomes a new row in `parser-test-set.md`** before it's fixed

---

## 7. Release checklist (Google Play)

- [ ] All unit, parser, and e2e tests green; rule-ID coverage script empty
- [ ] Reliability script R1–R15 passed on the full device matrix
- [ ] Performance budgets met
- [ ] **Permissions declared & justified:** `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM` (and Play's exact-alarm declaration — check whether the app qualifies for `USE_EXACT_ALARM`), `RECEIVE_BOOT_COMPLETED`, `READ_CALENDAR`, `READ_CONTACTS` (prominent in-app disclosure before the request, `PRM-8`)
- [ ] **Data safety form**: data stays on device in v1.0; crash/analytics data described; no contact or calendar data collected off-device
- [ ] Privacy policy published (covers calendar + contacts access)
- [ ] Final app name, icon, store listing, screenshots (D2) — lead with occasions + bills
- [ ] Translation keys complete (no hard-coded strings)
- [ ] Light/dark, 200% font, TalkBack, Reduce Motion checks done
- [ ] AI-generated art: commercial-use terms confirmed (`design-direction.md` DS9)
