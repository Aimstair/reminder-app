# Behavior Spec — v1.0

The exact rules for how reminders behave. Every rule has an ID (e.g. `ALR-4`) so tests and code can reference it. If code and this spec disagree, **the spec wins** — fix the code or change the spec on purpose.

Related: [`reminder-app-concept.md`](../reminder-app-concept.md) (concepts, data model) · [`ROADMAP.md`](../ROADMAP.md) (phasing) · [`product-decisions.md`](product-decisions.md)

**Scope:** v1.0 (Android, local-only, no account). Rules marked *(v1.1+)* are listed only so the v1.0 design doesn't block them.

---

## 0. Terms

| Term | Meaning |
|---|---|
| **Reminder** | The thing the user created or imported ("Mom's birthday", yearly) |
| **Occurrence** | One instance of a reminder ("Mom's birthday 2026") |
| **Anchor** | The moment alert offsets are measured from (see `TIM-10`) |
| **Alert stage** | One entry in an alert plan: an offset + channels |
| **Fire time** | Anchor + offset = when a stage's notification should appear |
| **Day time** | User's default time for date-only items. Default **09:00** (`PRF-3`) |
| **Resolved** | Occurrence in a terminal state: `done`, `skipped`, or `passed` |
| **Completable** | Types that can be marked done: **Task** always; **Occasion** per occurrence |

---

## 1. Timing (`TIM`)

- **TIM-1** A reminder's timing is one of:
  - `datetime` — a specific time, e.g. "6:00 PM Sun Oct 5"
  - `date` — a whole day, no time, e.g. "Oct 12"
- **TIM-2** **Every `datetime` reminder has a time zone** (IANA, e.g. `America/New_York`), like Google Calendar. The time means that wall-clock time *in that zone*.
- **TIM-3** New reminders get the user's **default time zone** (`PRF-1`). The user can change the time zone on any individual reminder (time zone picker next to the time).
- **TIM-4** **`date` reminders have no time zone** (like all-day events in Google Calendar): "Oct 12" is Oct 12 wherever the user is, and the anchor uses day time in the device's current zone.
- **TIM-5** Calendar-imported events keep the source event's time zone.
- **TIM-6** **Display:** times are shown converted to the device's current zone. If a reminder's zone differs from the device zone, its original time is shown too: "6:00 PM (3:00 PM London)".
- **TIM-7** Changing the default time zone (`PRF-1`) asks: **"Only new reminders"** or **"Also move upcoming reminders"**. The second option changes the time zone of every unresolved reminder still in the old default zone, keeping the same wall-clock time (6:00 PM stays 6:00 PM, in the new zone). Reminders the user set to a specific zone by hand are not changed.
- **TIM-8** **Travel:** when the device zone changes and differs from the default zone, show a one-time prompt: "Switch your default time zone to [new zone]?" (setting `PRF-2`, default **on**). Until the user accepts, reminders keep their own zones; times are displayed converted (`TIM-6`).
- **TIM-9** The parser recognizes explicit zones in input ("3pm EST", "15:00 London") and sets that reminder's zone (`CAP-9`).
- **TIM-10** Anchor:
  - `datetime` → the start time
  - `date` → that date at **day time** (`PRF-3`)
- **TIM-11** End time is **optional on every type**. Defaults when none is given: Meeting = start + 30 min · Event = start + 1 h · Task = **no end** (just a due time) · `date` = end of that day (23:59:59). The user can add an end time to a task (e.g. "Work on report 2–4 PM").
- **TIM-12** **Due time** (used for overdue, `OVD-1`):
  - `datetime` task → its end time if it has one, otherwise its start time
  - `date` task or occasion → **end of that day** (a task due "Oct 15" is not overdue at 9:01 AM on Oct 15)
  - Alerts still use the anchor (`TIM-10`), not the due time.
- **TIM-13** DST gap (time doesn't exist, e.g. 02:30 on spring-forward day): shift **forward by the length of the gap** (02:30 → 03:30).
- **TIM-14** DST overlap (time happens twice, e.g. 01:30 on fall-back day): use the **first** occurrence.
- **TIM-15** On device time-zone change: recompute fire times for `date` reminders (which follow the device zone) and reschedule (`SCH-5`). `datetime` reminders keep their absolute moment in time.

## 2. Recurrence (`REC`)

- **REC-1** Recurrence is stored as an RFC 5545 RRULE plus `repeat_mode`: `fixed` or `after_completion`.
- **REC-2** `fixed` occurrences are generated from the RRULE starting at the reminder's original start.
- **REC-3** **Month-end clamp:** a monthly rule on day 29–31 falls on the **last day of the month** in shorter months (rent "on the 31st" → Feb 28/29, Apr 30). *Note: plain RRULE skips these months; the engine must clamp.*
- **REC-4** **Feb 29 yearly:** falls on **Feb 28** in non-leap years.
- **REC-5** "Last business day" = last Mon–Fri of the month. Public holidays are ignored (D3).
- **REC-6** `after_completion`: only **one** unresolved occurrence exists at a time. When it's resolved as `done`, the next occurrence = **completion date + interval**, at the original time of day.
  - Example: "Change AC filter every 3 months", due Oct 1, done Oct 10 → next due Jan 10.
  - Done early (Sep 25) → next due Dec 25.
- **REC-7** `after_completion` + `skipped`: next occurrence = **the skipped occurrence's due date + interval** (skipping doesn't reset the clock to today).
- **REC-8** `after_completion` while unresolved: no new occurrences are created; the current one stays overdue (`OVD-1`).
- **REC-9** Recurrence end: RRULE `UNTIL` or `COUNT`. When the last occurrence is resolved, the reminder is archived (`DAT-3`).
- **REC-10** `after_completion` is only allowed on completable types (Task, Occasion). Meetings/Events use `fixed`.

### Editing recurring reminders

- **REC-11** Editing a recurring reminder asks: **"This one"** or **"This and future"**.
- **REC-12** "This one" → stores an override on that Occurrence only (time, alert plan). The series is unchanged.
- **REC-13** "This and future" → splits the series: the original ends before this occurrence (RRULE `UNTIL`), and a new reminder starts at this occurrence with the edits. Past occurrences keep their history.
- **REC-14** Past (resolved) occurrences cannot be edited, only viewed.
- **REC-15** Deleting a recurring reminder asks: **"This one"** (occurrence → `skipped`) or **"All"** (delete reminder, `DAT-1`).

## 3. Occurrence lifecycle (`OCC`)

### States

| State | Meaning | Terminal? |
|---|---|---|
| `pending` | Waiting; alerts scheduled | no |
| `snoozed` | User delayed the alert; re-fires at `snoozed_until` | no |
| `prepared` | Occasion only: user tapped "I'm prepared"; prep alerts stopped | no |
| `done` | Completed by user | yes |
| `skipped` | User chose to skip this occurrence | yes |
| `passed` | Time is over, no action needed (non-completable types, and occasions after their day) | yes |

"Overdue" is **not a state**: it's derived (`OVD-1`).

### Transitions

| From | Trigger | To | Rule |
|---|---|---|---|
| `pending` | Snooze action | `snoozed` | `NTF-4` |
| `snoozed` | `snoozed_until` reached (alert re-fires) | `pending` | |
| `pending` / `snoozed` | Done (Task, Occasion) | `done` | |
| `pending` / `snoozed` / `prepared` | Skip | `skipped` | |
| `pending` / `snoozed` | "I'm prepared" (Occasion) | `prepared` | `OCC-3` |
| `pending` / `snoozed` | End time passes (Meeting, Event) | `passed` | `OCC-2` |
| `pending` / `snoozed` / `prepared` | Day ends (Occasion) | `passed` | `OCC-2` |
| `done` / `skipped` | Undo | previous state | `OCC-5` |

- **OCC-1** Tasks never become `passed` — an unresolved task stays unresolved (and overdue) until done or skipped.
- **OCC-2** Meetings and Events become `passed` automatically at their end time. Occasions become `passed` at the end of their day if not done/skipped.
- **OCC-3** "I'm prepared" cancels the remaining alert stages with **offset < 0** (prep nudges) but **keeps** stages with offset ≥ 0 (the day-of reminder still fires: "Today is Mom's birthday").
- **OCC-4** Resolving an occurrence (`done`/`skipped`/`passed`) cancels all its pending alarms and removes its notifications from the notification shade.
- **OCC-5** Undo: a 5-second "Undo" snackbar after any done/skip in the app; from the occurrence detail screen, "Mark as not done" is available while the occurrence is the latest one of its series. Undo restores alarms whose fire time is still in the future.
- **OCC-6** Occurrences are created on demand (`SCH-2`). Future occurrences shown in "Later" can be computed on the fly and only need to be saved when their state changes.

## 4. Alert plans (`ALR`)

- **ALR-1** An alert plan is a list of stages: `{ offset, channels }`. Offsets can be negative (before), zero (at), using units of minutes, hours, days, weeks, or months.
- **ALR-2** Fire time = anchor (`TIM-10`) + offset. Day/week/month offsets on a `date` reminder keep the day time (e.g. `−7d` on Oct 12 → Oct 5, 09:00).
- **ALR-3** Month offsets use calendar math with month-end clamp (`−1 month` from Mar 31 → Feb 28/29).
- **ALR-4** **Any type can have any number of stages** (max 10). Type only sets the defaults:

| Type | Default alert plan |
|---|---|
| Meeting | `−10m` |
| Task (datetime) | `0` |
| Task (date) | `0` (= day time) |
| Event | `−1h` |
| Occasion | `−7d`, `−1d`, `0` (= day time on the day) |

- **ALR-5** "Start by" preset (Tasks with a due date): adds one stage at a user-chosen lead time (e.g. `−2d`) labelled "Start by" in the notification.
- **ALR-6** **Past stages at save time:** stages whose fire time is already past when a reminder is created or edited are dropped for that occurrence. If that leaves no stages and the anchor is still in the future, one alert is scheduled at the anchor.
- **ALR-7** A reminder can have **no alerts** (empty plan). It still appears in the list.
- **ALR-8** Channel in v1.0 is always `push` (local notification). `email` stages are stored but ignored until v1.1 *(v1.1+)*.

### Nag until done

- **ALR-9** Opt-in per reminder, completable types only. Intervals offered: 30 min, 1 h, 2 h (default), 4 h.
- **ALR-10** Starts after the **last** stage of an occurrence has fired, if the occurrence is still unresolved.
- **ALR-11** Nags only inside the user's **nag hours** (`PRF-4`, default **08:00–22:00**, device local time); a nag that would fall outside them moves to the start of the next window.
- **ALR-12** Stops when the occurrence is resolved. Snooze pauses nagging until `snoozed_until`, then nagging resumes.
- **ALR-13** Stops after **3 days** of nagging; the occurrence then only appears in the digest and Overdue group.

## 5. Scheduling (`SCH`)

- **SCH-1** The device schedules all alerts (exact alarms). Nothing depends on a server.
- **SCH-2** **Rolling window:** only fire times within the next **14 days** are registered with the OS. Occurrences in that window are saved to the database.
- **SCH-3** **Cap:** at most **400** registered alarms (Android allows ~500 per app). If over the cap, register the earliest 400; the rest are picked up by the next top-up.
- **SCH-4** Every alarm has a stable key: `(occurrence_id, stage_index, nag_seq)`. Registering the same key twice replaces, never duplicates.
- **SCH-5** **Top-up/rebuild** runs on: app open · daily background job · device reboot · app update · time change · time-zone change · any reminder create/edit/delete · permission granted.
- **SCH-6** **Never fire twice:** before showing a notification, check `alerts_sent` for the key; record it immediately after showing.
- **SCH-7** **Late alarms** (device off, Doze delay, rebuild after reboot), using the user's **late-alert cutoff** (`PRF-6`, default **2 hours**):
  - Fire time passed **within the cutoff** → show now, marked "(late)" in the notification time. If several are late at once, show them grouped.
  - **Beyond the cutoff** → don't notify; record as **missed** for the digest (`DIG-2`).
  - Cutoff "Always" → every late alert is shown, however late.
- **SCH-8** **Editing timing** cancels the occurrence's future alarms and recomputes from the new anchor. `alerts_sent` entries are cleared for stages whose new fire time is in the future (they can fire again).
- **SCH-9** **Exact alarm permission denied** (`PRM-2`): schedule inexact alarms with a 10-minute window instead and show a warning.
- **SCH-10** Notifications in the same minute are each shown separately; with 4 or more visible at once, Android groups them under a summary ("4 reminders").

## 6. Notifications & actions (`NTF`)

- **NTF-1** Notification title = reminder title. Body = when + stage label (e.g. "In 1 week · Oct 12", "Start by · due Friday", "Today", "Overdue since 9:00 AM"). Exact wording lives in `copy.md`.
- **NTF-2** Action buttons (max 3):

| Situation | Buttons |
|---|---|
| Task (any stage, incl. nag) | **Snooze 1h** · **Tomorrow** · **Done** |
| Occasion — prep stage (offset < 0) | **Tomorrow** · **I'm prepared** · **Done** |
| Occasion — day-of stage | **Snooze 1h** · **Done** |
| Meeting / Event | **Snooze 5m** · **Open** |
| Digest | **Open** |

- **NTF-3** Tapping the notification body opens that occurrence's detail screen.
- **NTF-4** **Snooze only delays the alert, never the due date.** "Snooze 1h" / "Snooze 5m" re-fire that stage after the delay; "Tomorrow" re-fires tomorrow at the time set by `PRF-5` (default **day time**, 09:00; alternative: same time as now). The occurrence keeps its due date (so a snoozed overdue task stays overdue). Moving the due date is a **reschedule** (`NTF-7`).
- **NTF-5** While snoozed, other future stages still fire on schedule. If one fires before the snooze ends, the snooze is cleared (the newer alert replaces it).
- **NTF-6** Swiping a notification away changes nothing: no state change, and nagging continues.
- **NTF-7** Reschedule (in-app half-sheet only, not a notification button): changes the occurrence's time for this occurrence (`REC-12`), and recomputes alerts (`SCH-8`).
- **NTF-8** Notification actions work **without opening the app** and complete within 1 s.
- **NTF-9** After **Done** or **I'm prepared** from a notification, the notification is replaced for 5 s by a confirmation ("Done · Pay rent") with **Undo**, then disappears. Undo restores the previous state (`OCC-5`).

## 7. Overdue & digest (`OVD`, `DIG`)

- **OVD-1** An occurrence is **overdue** when: type is completable · state is `pending` or `snoozed` · due time (`TIM-12`) has passed.
- **OVD-2** Overdue occurrences appear in the **Overdue** group at the top of the list, oldest first, until resolved.
- **OVD-3** After **30 days** overdue, the digest asks "Still relevant?" with **Keep** / **Skip** for that occurrence.
- **DIG-1** The digest is generated daily at the **digest time** (`PRF-7`, default **08:00** local). It appears as a card at the top of the list until dismissed or the day ends.
- **DIG-2** Contents (empty sections hidden):
  1. Overdue tasks and occasions (`OVD-1`)
  2. Missed alerts (`SCH-7`, or alerts not shown because notifications were off)
  3. Occasions in the next 7 days not yet `prepared` or `done`
  4. Calendar events with alerts that were removed from the calendar (`CAL-8`)
- **DIG-3** If the digest has content, one notification is posted ("3 overdue · 1 missed") — setting, default **on**. If empty, no notification and no card.

## 8. Quick-capture defaults (`CAP`)

Detailed parser rules and examples live in `parser-test-set.md`. These are the defaults the rest of the app relies on:

- **CAP-1** No date and no time → **tomorrow at day time**.
- **CAP-2** Date but no time → `date` timing on that date (anchor = day time).
- **CAP-3** Time but no date → **today** if that time is still ahead, otherwise **tomorrow**.
- **CAP-4** Weekday name ("Friday") → the next such day; **today** if today is that day and the time (if given) is still ahead.
- **CAP-5** Hour without am/pm: **1–6 → PM**, **7–11 → AM**, **12 → PM** — and the time chip is highlighted so the user can check it.
- **CAP-6** Type guess from keywords; default **Task**. Context guess from keywords; otherwise the type's default context.
- **CAP-7** The user always sees the parse preview before saving; nothing is saved from voice or share-sheet input without it.
- **CAP-8** The original text is saved as `raw_input`.
- **CAP-9** An explicit time zone in the input ("3pm EST", "10am Tokyo time") sets the reminder's zone; otherwise the default zone is used (`TIM-3`). The zone chip is shown only when it differs from the default.
- **CAP-10** A time range ("2–4pm", "from 2 to 4") sets start and end time (`TIM-11`).
- **CAP-11** Editing a preview chip by hand **locks** that field: further typing no longer changes it.
- **CAP-12** Shared text (share sheet): links never become the title — they are removed from the input and go into notes. Text longer than 120 characters: the first sentence is parsed as the input; the full text goes into notes. A link-only share opens with an empty input (the user types what it's about) and the link in notes.

## 8b. Templates (`TPL`)

- **TPL-1** The capture sheet shows template chips when the input is empty: **Birthday · Bill due · Renewal · Free trial · Night out · Appointment**.
- **TPL-2** Tapping a template sets and **locks** (`CAP-11`) its type, repeat, and alert fields, then focuses the input with a template-specific placeholder. The user types the rest (who/what/when); the parser fills only unlocked fields.
- **TPL-3** Template definitions (v1.0, fixed set):

| Template | Type | Repeat | Alerts | Extras | Placeholder |
|---|---|---|---|---|---|
| Birthday | Occasion | Yearly | −7d, −1d, 0 | Title gets "'s birthday" appended if the user types only a name | *Whose birthday? When?* |
| Bill due | Task | Monthly | −2d, 0 | Nag until done **on** (2h) | *Which bill? Due on the…* |
| Renewal | Task | Yearly | −1 month, −1 week, 0 | — | *What renews? When?* |
| Free trial | Task | None | −1d | Date defaults to **in 7 days**; title gets "Cancel … trial" | *Which trial?* |
| Night out | Event | None | −1d, −1h | Time defaults to 19:00 | *Where and when?* |
| Appointment | Event | None | −1d (20:00 the evening before), −1h | — | *What and when?* |

- **TPL-4** Tapping a different template replaces the locked fields; clearing the input removes the template.
- **TPL-5** *(v1.2)* User-defined custom templates.

## 9. Calendar import (`CAL`)

- **CAL-1** Only calendars the user selected are imported. Nothing is imported until the user grants calendar permission and picks calendars.
- **CAL-2** Import window: **1 day ago → 60 days ahead**. Refreshed on app open, every 6 hours (background), and when Android reports a calendar change.
- **CAL-3** Imported events are read-only, never completable, and become `passed` at their end time.
- **CAL-4** Auto-tag rules, first match wins:
  1. From the device "Birthdays"/contacts calendar → **Occasion** · Personal
  2. All-day **and** repeats yearly → **Occasion** · Personal
  3. Has at least one attendee other than the user → **Meeting** · Work
  4. Everything else → **Event** · Personal
- **CAL-5** User corrections of type/context apply to the whole recurring series and are remembered (`kind_override`, `context_override`).
- **CAL-6** Imported events have **no alerts by default**. "Remind me" adds an alert plan as an **overlay** (applies to this event, or the whole series if the user picks "All").
- **CAL-7** If an event with an overlay **moves**, its alerts move with it (anchor = new start).
- **CAL-8** If an event with an overlay is **deleted** from the calendar, its alarms are cancelled, the digest notes it once (`DIG-2`), and the overlay is purged after 30 days (kept in case the event comes back).
- **CAL-9** **Duplicate suggestion:** when a manual reminder has a similar title (similarity ≥ 0.8) **and** a start time within ±30 min of an imported event, show a "This looks like it's on your calendar" banner on the manual reminder with **Merge** / **Keep both**. Merge = move the manual reminder's alert plan onto the event as an overlay, then delete the manual reminder. Never merge automatically.
- **CAL-10** Revoking calendar permission hides imported events; overlays are kept so they return if permission is granted again.

## 9b. Contacts birthdays & anniversaries (`CON`)

- **CON-1** Optional, off until the user opts in (onboarding calendar step or Settings → Calendars & contacts). Requires the contacts permission; all processing stays on the device.
- **CON-2** Reads only **birthday** and **anniversary** dates from contacts — no phone numbers, emails, or other fields are stored.
- **CON-3** Before importing, the user sees a review list ("12 birthdays, 2 anniversaries found"), all selected, with toggles per contact. **[Import]** creates reminders.
- **CON-4** Each import becomes a **real Occasion reminder** (unlike calendar events): title "{Name}'s birthday" / "{Name}'s anniversary", `date` timing, yearly, default Occasion alerts — fully editable and completable. Source stored as `contact { contact_id, field }`.
- **CON-5** Dates without a year (common in contacts) are fine — the occasion repeats yearly from the next occurrence. Feb 29 follows `REC-4`.
- **CON-6** **Re-scan** daily and on app open (when permission is granted):
  - New contact with a birthday → added only if "Auto-add new birthdays" is on (setting, default **on**); otherwise shown as a suggestion in the digest
  - Date changed in contacts → reminder updated, **unless the user edited that reminder's date**
  - Contact deleted → reminder kept; marked "Contact removed" on its detail screen
- **CON-7** **No duplicates with the calendar:** while contacts import is on, the device "Birthdays"/contacts calendar is excluded from calendar import (`CAL-4` rule 1 no longer applies to it).
- **CON-8** Revoking the permission stops re-scans; existing occasion reminders stay.

## 10. Permissions & degraded modes (`PRM`)

- **PRM-1** **Notifications denied:** reminders still save and appear in the list. A persistent banner explains alerts are off with a button to fix it. Undelivered alerts count as missed (`DIG-2`).
- **PRM-2** **Exact alarms denied:** inexact scheduling (`SCH-9`) and a banner: "Reminders may arrive up to 10 minutes late."
- **PRM-3** **Calendar denied:** calendar features are hidden; Settings offers to enable them.
- **PRM-4** **Battery optimization active** (aggressive OEMs): one-time guide during onboarding, then a dismissible tip in Settings. Never blocks the app.
- **PRM-5** Permission state is checked on every app open and before every scheduling run; a newly revoked permission switches behavior immediately.
- **PRM-6** The notification permission is requested the first time the user **saves a reminder that has alerts**, not at first launch.
- **PRM-7** **Send test reminder** (onboarding after permissions, and Settings → Reliability):
  1. Schedules a real alert **15 seconds** ahead through the normal scheduling path (exact alarm → notification), and tells the user they can lock the phone or leave the app.
  2. When the alert fires, it shows "Test reminder — it works! 🔔" and records the actual delay.
  3. When the user returns to the app: ✅ "Reminders are working" (delay ≤ 60 s) · ⚠️ "Arrived {n} s late" with the matching fix (exact alarm, battery) · ❌ not received after 2 minutes → troubleshooting steps (notifications, exact alarm, battery optimization, Do Not Disturb).
  4. Test reminders are never saved as reminders and never appear in lists or the digest.
- **PRM-8** Contacts permission is requested only when the user opts in to birthday import (`CON-1`), with an explanation first.

## 11. Data lifecycle (`DAT`)

- **DAT-1** **Delete** is a soft delete (`deleted_at` set): hidden immediately, 5-second Undo snackbar, purged after 30 days. (Keeps v1.1 sync simple — deletions can be synced.)
- **DAT-2** Deleting a reminder cancels all its alarms and removes its notifications.
- **DAT-3** **Archive:** non-recurring reminders are archived 7 days after being resolved; recurring reminders when their series ends (`REC-9`). Archived items are found via search and a "Completed" filter, not in the main timeline.
- **DAT-4** Every record has `id` (UUID generated on device), `created_at`, `updated_at`, `device_id` — required for v1.1 sync *(v1.1+)*.
- **DAT-5** **Local backup:** export all data to a file and import it back. Import merges by `id`; on conflict, the newer `updated_at` wins.

---

## 12. User settings (`PRF`)

Every user-adjustable default the rules above depend on. **Onboarding** settings appear in one "Your schedule" step, pre-filled with defaults so the user can accept them with one tap. All settings remain editable in Settings.

| ID | Setting | Default | Options | Where | Used by |
|---|---|---|---|---|---|
| **PRF-1** | Default time zone | Device zone at first launch | Any IANA zone | Onboarding + Settings | `TIM-3`, `TIM-7` |
| **PRF-2** | Ask to switch default zone when traveling | On | On / Off | Settings | `TIM-8` |
| **PRF-3** | Day time (time for date-only items) | 09:00 | Any time | Onboarding + Settings | `TIM-10`, `ALR-2`, `CAP-1` |
| **PRF-4** | Nag hours | 08:00–22:00 | Any start/end | Onboarding + Settings | `ALR-11` |
| **PRF-5** | "Tomorrow" snooze time | Day time (09:00) | Day time / Same time as now | Onboarding + Settings | `NTF-4` |
| **PRF-6** | Late-alert cutoff | 2 hours | 30 min / 2 hours / 6 hours / Always | Settings | `SCH-7` |
| **PRF-7** | Digest time | 08:00 | Any time | Settings | `DIG-1` |
| **PRF-8** | Digest notification | On | On / Off | Settings | `DIG-3` |
| **PRF-9** | Default alert plan per type | Per `ALR-4` table | Any plan | Settings | `ALR-4` |
| **PRF-13** | Auto-add new birthdays from contacts | On | On / Off | Settings | `CON-6` |
| **PRF-12** | Completion sounds | On | On / Off (always silent when phone is on silent/vibrate) | Settings | design-direction §6 |

- **PRF-10** Changing a setting affects **future** alerts only: the scheduler rebuilds (`SCH-5`); notifications already shown are not changed.
- **PRF-11** Skipping the onboarding step applies all defaults.

---

## Decision log

| Date | Rule(s) | Decision |
|---|---|---|
| 2026-10-05 | `TIM-2`–`TIM-9` | Time zones work like Google Calendar: each timed reminder has a zone; user-set default zone; per-reminder override; option to move upcoming reminders when the default changes. Date-only reminders have no zone. |
| 2026-10-05 | `ALR-11`, `PRF-4` | Nag hours are user-adjustable in onboarding; default 08:00–22:00. |
| 2026-10-05 | `NTF-4`, `PRF-5` | "Tomorrow" snooze time is user-adjustable in onboarding; default day time (09:00). |
| 2026-10-05 | `SCH-7`, `PRF-6` | Late-alert cutoff is a user setting; default 2 hours. |
| 2026-10-05 | `TIM-11`, `TIM-12` | Tasks can optionally have an end time; due time = end if set, else start. Date-only tasks are due at end of day. |
| 2026-10-06 | `REC-4`, parser I4 | A Feb 29 yearly reminder stores `BYMONTH=2;BYMONTHDAY=29` so leap years land on Feb 29 while other years show Feb 28. Recurrence engine is our own (architecture.md §3). |
| 2026-10-06 | `PRS-2` (parser-test-set.md) | `past_date_rolled` is flagged only for one-time reminders; repeating ones roll to next year silently. Matches the acceptance table (I2–I4, F11, F13 vs N1–N2). |
| 2026-10-08 | DS14 (design-direction.md), S-61 | Device review: more iOS-like type, motion and spacing (sliding selections, press feedback, iOS transitions, fixed heights with truncation). Widget: header with a round [+] instead of the tall Add column, which covered half the 2×2 widget. Today's Day view shows the digest as one line that expands (S-41), so the hour grid keeps its height. |
| 2026-10-08 | `VW-8`, `VW-10` (screens.md), DS12–DS13 | Built to the approved mockups (`docs/design/mockups/`): Month = type dots + one short label, tapping a day lists its items under the grid; All clear is a full screen; occasion stat is factual history, not a streak. |
| 2026-10-08 | `CAP-12`, `ALR-6`, R13 | Device testing: shared links go to notes even in short text (a TikTok link had become the title). `ALR-6` fallback only for stages already past at save time (Events/Meetings were alerting twice). R13: Android shows at most ~50 notifications per app at once — accepted; all alarms still fire. |
| 2026-10-06 | Stack (architecture.md) | **Flutter** selected over React Native by the animation bake-off (`spikes/animation-bakeoff.md`). Behavior rules unchanged; parser to be written in Dart. |
| 2026-10-05 | `TPL-*`, `CON-*`, `PRM-7`, `PRM-8` | From competitive scan: templates moved to v1.0; Contacts birthday/anniversary import; "Send test reminder" reliability check. Positioning leads with occasions + bills. |
| 2026-10-05 | `VW-*` (screens.md) | Google Calendar-style views added: Schedule, Day, Month in v1.0; 3 Day, Week, Year in v1.2. Reverses the earlier "no month-grid view" cut. |
| 2026-10-05 | `NTF-9`, `CAP-11`, `CAP-12` | Added from user flows: undo from notification, chip locking, long shared text. |
| 2026-10-05 | `CAP-*`, parser | Parser rules and acceptance cases defined in `parser-test-set.md` (PRS-1 – PRS-36). |
