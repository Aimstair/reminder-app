# Spike: Exact-Alarm Reliability (v0)

**Question:** Can reminders fire on time on real Android phones — with the app closed, after reboot, in Doze — using our "Dart plans, Kotlin executes" design?
**Status:** ✅ **passed on Samsung** (2026-10-06) · Pixel and Xiaomi still to test
**Code:** `android/app/src/main/kotlin/app/aimstair/reminder_app/alarms/` · bridge `pigeons/alarm_api.dart` · test screen `lib/spike/alarm_spike_page.dart` (temporary)

## What was built
- Kotlin module with its own `native.db` (alarms, action_journal, fire_log) — `docs/architecture.md` §4–5
- `setExactAndAllowWhileIdle` alarms, inexact 10-min fallback when exact alarms aren't allowed (`SCH-9`)
- Notification buttons handled natively without starting Flutter: Done, I'm prepared, Snooze, Tomorrow, Undo (`NTF-2`, `NTF-4`, `NTF-8`, `NTF-9`)
- No double fire (`SCH-6`); late/missed handling with 2 h cutoff (`SCH-7`); notifications off → recorded missed (`PRM-1`)
- Re-registration on boot, app update, time and time-zone change (`SCH-5`)
- Pigeon-generated typed bridge (Dart ↔ Kotlin)

## Results — Samsung Galaxy A73 5G (SM-A736B), Android 15, release build

| Test (docs/testing.md §3) | Result |
|---|---|
| R1/R2 Foreground / background (test in 15 s, task in 1 min) | ✅ fired 0.0 s late |
| R3 App swiped away from recents | ✅ fired on time |
| R5 Reboot before fire time, app not opened | ✅ fired 0.2 s late |
| R4 Phone locked and idle (Doze, +45 min) | ✅ fired on time |
| R13 Burst: 5 alarms in the same minute | ✅ all 5 fired 0.0 s late |
| Occasion: "I'm prepared" on prep nudge keeps day-of alert (`OCC-3`) | ✅ |
| Notification buttons with app closed (Done/Undo, Snooze) (R11) | ✅ |
| Late alert (due 30 min ago) shown and marked late (`SCH-7`) | ✅ LATE · 1805 s (intended) |
| Missed alert (due 3 h ago) recorded, not shown (`SCH-7`) | ✅ MISSED (intended) |

**Fire log summary:** 12 on time · 1 late (intended) · 1 missed (intended). Real alarms: max delay **0.2 s**.

## v1.0 build — Samsung Galaxy A73 (Android 15), release, 2026-10-08
Real reminders created through the app (share target → capture → Save), not spike buttons. Delays from the native fire log.

| Test (docs/testing.md §3) | Battery setting | Result |
|---|---|---|
| R1 Foreground | Unrestricted | ✅ 0.0 s |
| R2 Background | Unrestricted | ✅ 0.0 s |
| R3 Swiped away from Recents | Unrestricted | ✅ 0.0 s |
| R4 Deep Doze (forced via `dumpsys deviceidle force-idle`, unplugged) | Unrestricted | ✅ 0.0 s, still IDLE when fired |
| R14 App updated (`adb install -r`), app not opened | Unrestricted | ✅ same alarms registered before/after |
| R9 Exact alarms revoked (`appops --uid … deny`) | **Default** | ✅ re-registered inexact (+10 min window), banner G3 shown; fired 7 min 47 s late. Re-grant → native receiver re-registered exact without opening the app |
| R13 50 alarms at the same minute | Default | ⚠️ 50/50 alarms fired and 50/50 `notify()` calls at 09:40:00; Android showed **48** — its ~50-active-notifications-per-app cap was reached (other app notifications were still in the shade). Grouped under one summary (`SCH-10`) ✅ |
| R10 Notifications off (`pm revoke POST_NOTIFICATIONS`) | Default | ✅ no crash; banner G2; digest "1 alert wasn't shown" |

Notes:
- With battery **Unrestricted**, Android allows exact alarms even without `SCHEDULE_EXACT_ALARM` (`exactAllowReason=allow-listed`), so R9 must run with the default battery setting.
- Device time zone can't be changed over adb on Android 15 (`SUGGEST_MANUAL_TIME_AND_ZONE` required) — R8 is manual.
- **Bug found and fixed:** the `ALR-6` anchor fallback was re-applied on every re-plan, so after an Event/Meeting's last alert fired, a second alert was added at the start time. Now applied only when all stages were already past at the last save.

## Still to do (before v1.0 exit criteria)
- Run the same script on **Pixel** and **Xiaomi/Redmi** (most aggressive battery management) — via beta testers if no device is available
- Confirm results with the **default battery setting** vs "Unrestricted" (record which was used)
- R6–R10, R12, R14 from `docs/testing.md` §3 (phone off past cutoff, time-zone change, exact permission revoked, notifications disabled, nag overnight, app update)
- Undo should restore an occurrence's cancelled sibling alarms — planned on the Dart side when it reconciles the journal
- Play Store: decide `SCHEDULE_EXACT_ALARM` vs `USE_EXACT_ALARM` declaration (docs/testing.md §7)

## Decisions confirmed by this spike
- Keep firing and notification buttons **fully native** — works with the app closed and survives reboot
- `minSdk 26` (Android 8) — needed for `java.time` and notification channels
- Pigeon bridge works well for the Dart ↔ Kotlin API
