# Screens & Navigation — v1.0

Every screen, sheet, and dialog in the app: what it shows, what you can do there, and where it leads. This is the brief for UI design. **Approved mockups:** rendered in [`design/mockups/`](design/mockups/README.md) (from the [Reminder App Screens canvas](https://claude.ai/artifact/ArygfCSr3DBPg4pTmz8kMG), page "Calm · Things 3 style (chosen)"; patterns in `design-direction.md` DS11). **Build to the mockup images.** Flow IDs (`FL-*`) → [`user-flows.md`](user-flows.md); rule IDs → [`behavior-spec.md`](behavior-spec.md).

**Version tags:** screens are v1.0 unless marked **v1.2**.

---

## 1. Views (inspired by Google Calendar)

The home screen can show reminders in several **views**, switched from the top bar or the side drawer — the same model as Google Calendar's Schedule / Day / 3 Day / Week / Month / Year. All views show the **same reminders with the same filters**; only the layout changes.

| View | What it shows | Best for | Version |
|---|---|---|---|
| **Schedule** *(default)* | Scrolling list grouped Overdue · Today · Tomorrow · This week · Later, then by month | Daily use, "what's next" | v1.0 |
| **Day** | One day: all-day strip on top, hourly time grid below | Planning today / a specific day | v1.0 |
| **Month** | Month grid with colored labels per day | Seeing what's coming, finding free days | v1.0 |
| **3 Day** | Three-column time grid | Short-range planning | v1.2 |
| **Week** | Seven-column time grid | Work weeks, busy schedules | v1.2 |
| **Year** | 12 mini months with marked days; occasions highlighted | Birthdays, renewals, expiries at a glance | v1.2 |

**Why this phasing:** Day, 3 Day, and Week share one time-grid component; building it for Day in v1.0 makes 3 Day and Week mostly reuse in v1.2. Year is simple but most useful once people have many yearly items.

### View rules (`VW`)

- **VW-1** The last-used view is remembered and reopened on launch (setting "Start in", default **Last used**).
- **VW-2** Filters (types, contexts, calendars) set in the drawer apply to **every** view.
- **VW-3** **Placement:**
  - `datetime` items → time grid at their start; height = duration. Tasks without an end are drawn as a fixed short block.
  - `date` items (date-only tasks, occasions, all-day calendar events) → **all-day strip** at the top of Day/3 Day/Week, and as labels in Month.
- **VW-4** **Colors by type** (like calendars in Google Calendar): each type has a color; Work items get a small work badge. Imported events use their type color plus a calendar icon; a bell icon means alerts are set.
- **VW-5** **Overdue:**
  - Schedule → Overdue group at the top
  - Day view **for today** → a collapsible "Overdue (3)" row at the top of the all-day strip
  - Month / Week / Year → shown on their original date in overdue style (no carry-over)
- **VW-6** **Completed items:** hidden in Schedule (visible via the Completed screen). In Day/3 Day/Week/Month they stay visible, faded and struck through (setting "Show completed", default **on**, like completed tasks in Google Calendar).
- **VW-7** Recurring items are shown for **any** date you scroll to, computed on the fly (`OCC-6`). The 14-day window only limits alarms, not what's displayed.
- **VW-8** **Tap empty space:**
  - Time slot in Day/3 Day/Week → capture sheet pre-filled with that date and time (chips locked, `CAP-11`)
  - Day cell in Month → **selects** that day and lists its items in a panel under the grid (tap an item → detail; tap the panel's date heading → **Day** view). Changed 2026-10-08 to match the approved mockups.
  - **Long-press** a Month day → capture sheet pre-filled with that date
- **VW-9** **Swipe left/right** moves to the next/previous day, period, or month. **[Today]** in the top bar jumps back to now.
- **VW-10** **Month cells** show up to 3 dots (one per type present, in type color) and **one short label** for the day's first all-day item (e.g. *Mom*, *Rent*, *Party*). Today = filled accent circle; selected day = ring. Above the grid: month summary chips (*N occasions · N bills due · N meetings*, each shown as its type icon + count; the name is read out by TalkBack). (Changed 2026-10-08 from "up to 3 labels + N" to match the approved mockups.)
- **VW-11** **Time grid** shows a current-time line; on open it scrolls to one hour before now (today) or to day time (`PRF-3`) for other days. Overlapping items sit side by side (max 3 columns, then "+N").
- **VW-12** **Schedule** scrolls forward indefinitely; after "Later" it switches to month headers ("November 2026"). It doesn't scroll into the past (history is in Day/Month views and the Completed screen).
- **VW-13** *(v1.2)* **Drag to reschedule** in Day/3 Day/Week: drag a block to a new time. Same rules as reschedule (`NTF-7`): recurring items change this occurrence only.
- **VW-14** *(v1.2)* **Year view:** tapping a day opens Day view; tapping a month opens Month view.
- **VW-15** **Home cards** (Schedule, above Overdue; mockup 02). Two cards side by side (one fills the row alone):
  - **Meeting card** — the next Meeting (own or from the calendar) that hasn't ended and starts within **7 days**. Label **Up next** (**Now** once it has started), a countdown pill (*in 45 min · in 3 hours · Tomorrow · Thu*), title, time range. Its look follows the subtype (`SUB-1`): Video call → camera tile and a **Join** button when the reminder has a link (its first link, else the first web address in its notes; opens it, `ATT-4`); Phone call → phone tile; In person → people tile; the footer names the subtype.
  - **Occasion card** — the next unresolved Occasion within **30 days**: "In 6 days" / "Today", title, prep progress (one segment per alert stage), **I'm prepared** (`OCC-3`). Each subtype has its own color and illustration: Birthday → pink, gift · Anniversary → red, hearts · Holiday → gold, a holiday picture (tree for Christmas, champagne for New Year, star otherwise) · Memorial → calm teal, lotus · Other → pink, confetti.
  - A card is hidden when the quick filter excludes its type.
- **VW-16** **Ticking a row** on Schedule fills the checkbox with a small burst, strikes the title through, then the row folds away (≈ 0.7 s; instant with Reduce Motion) before Done is recorded and Undo is offered.

---

## 2. Navigation map

```
                         ┌─────────────── Drawer (S-11) ───────────────┐
                         │ Views · Filters · Calendars · Completed ·    │
                         │ Settings · Help                              │
                         └──────────────────────────────────────────────┘
                                         ▲ ☰
 Onboarding (S-01…S-07) ──► HOME (S-10) ─┼─ Schedule (S-12) / Day (S-13) / Month (S-14)
                                         │   [3 Day / Week / Year — v1.2]
                                         │
          ┌──────────────┬───────────────┼──────────────┬─────────────────┐
          ▼              ▼               ▼              ▼                 ▼
   Capture sheet    Reminder detail  Event detail    Search (S-40)   Settings (S-50)
     (S-20)            (S-30)          (S-31)                          └─ sub-screens
      ├ Chip pickers    ├ Editor (S-22)  └ Remind me (S-32)               S-51…S-58
      │  (S-21)         ├ Reschedule (S-33)
      └ Editor (S-22)   └ Scope dialog (S-34)

 Outside the app: Notifications (S-60) · Widget (S-61) · QS tile (S-62) · Share target (S-63)
   └─ all open Capture sheet (S-20) or Reminder detail (S-30)
```

---

## 3. Screen inventory

### Onboarding (FL-1)

| ID | Screen | Contents | Actions → |
|---|---|---|---|
| S-01 | **Welcome** | App name, one-line promise, Rive hero: scattered notes gather into one list | **[Get started]** → S-01a |
| S-01a | **Just type it** | Self-typing demo input with chips popping in; then live input using the real parser | **[Save this]** (→ S-05 permissions) · **[Next]** / **[Skip]** → S-01b |
| S-01b | **Nudges demo** | Phone mockup + draggable week slider showing 1 week / 1 day / day-of nudges; tappable **[I'm prepared]** | **[Next]** / **[Skip]** → S-02 |
| S-02 | **Your schedule** | Time zone, day time, nag hours (slider drives sky animation), "Tomorrow" snooze time — all pre-filled (`PRF-1,3,4,5`) | **[Looks good]** / **[Skip]** → S-03 |
| S-03 | **Connect calendar** | Explanation (read-only, no alerts unless asked) | **[Connect]** → system dialog → S-04 · **[Not now]** → S-08 |
| S-04 | **Pick calendars** | List of device calendars with color + toggle (all on) | **[Done]** → S-08 |
| S-08 | **Contact birthdays** | Ask to import birthdays/anniversaries (`CON-1`) → after permission: review list with per-contact toggles, counts (`CON-3`) | **[Add birthdays]** → system dialog → review → **[Import]** · **[Not now]** → Home + capture |
| S-05 | **Notification explainer** | Why notifications matter; shown on first save with alerts (`PRM-6`) | **[Continue]** → system dialog |
| S-06 | **Precise timing explainer** | Why exact alarms matter (`PRM-2`) | **[Open settings]** → system setting · **[Not now]** |
| S-07 | **Reliability tip** | Phone-specific battery steps (`PRM-4`) | **[Show me]** / **[Later]** |

### Home & views

| ID | Screen | Contents | Actions → |
|---|---|---|---|
| S-10 | **Home shell** | **Top bar:** ☰ drawer · title (month/date — tap to open mini month picker, like Google Calendar) · 🔍 search · **[Today]** · view switcher. **Below:** banners (G2–G4, G10) · active filter chips · current view · **[+]** floating button | ☰ → S-11 · 🔍 → S-40 · **[+]** → S-20 · item → S-30/S-31 |
| S-11 | **Drawer** | **Views:** Schedule, Day, Month *(3 Day, Week, Year v1.2)* · **Types:** Meeting, Task, Event, Occasion (checkbox + color) · **Context:** Personal, Work · **Calendars:** each imported calendar (checkbox) · **Completed** · **Settings** · **Help & feedback** | Select view / toggle filters / → S-42, S-50 |
| S-12 | **Schedule view** | Greeting + daily progress ring ("2/6 done") · week strip with type-colored dots · filter chips (All · Personal · Work · **Bills** · Occasions · Events · Meetings; Bills shows a **Due this month** card, `BIL-6`) · home cards (`VW-15`): **Up next** meeting (countdown, subtype tile, Join) and **occasion spotlight** (per-subtype color and illustration, prep progress, I'm prepared) · ticking a row animates (`VW-16`) · digest card (S-41) · groups Overdue / Today / Tomorrow / This week / Later / months with count badges · reminder rows with icon tiles (`VW-12`) | Swipe right = Done · swipe left = Reschedule (S-33) · tap → detail |
| S-13 | **Day view** | Date header · all-day strip (incl. "Overdue (n)" for today) · hourly grid with current-time line (`VW-3`, `VW-5`, `VW-11`) | Swipe = prev/next day · tap slot → S-20 prefilled · tap item → detail |
| S-14 | **Month view** | Month title + ‹ › · summary chips · grid with type dots + one short label (`VW-10`) · selected day's items listed below | Swipe or ‹ › = prev/next month · tap day → select + list (`VW-8`) · date heading → S-13 · long-press → S-20 prefilled |
| S-15 | **3 Day view** — v1.2 | Three-column time grid | As Day; drag to reschedule (`VW-13`) |
| S-16 | **Week view** — v1.2 | Month + week range header ("Oct 4 – 10 · Week 41") with prev/next · day header row (today circled) · all-day row (multi-day items span columns; overdue marker on today) · seven-column hour grid, today tinted, weekends shaded, red now line in today's column · titles wrap to 2 short lines on phones; week start per locale | As Day; drag to reschedule |
| S-17 | **Year view** — v1.2 | 12 mini months; dots on days with items; occasion days highlighted | Tap day → S-13 · tap month → S-14 |
| S-18 | **Mini month picker** | Small month calendar dropping down from the title | Tap date → jumps current view to that date |

### Capture

| ID | Screen | Contents | Actions → |
|---|---|---|---|
| S-20 | **Capture sheet** | iOS-form layout: **Cancel · New Reminder · Save** bar · input card (text + 🎤 voice + removable template tag) · **template row when input is empty** (`TPL-1`) · grouped **Details** rows parsed from the text — Date, Time, Ends (`CAP-13`), Time zone, Repeat, Alerts (colored icon, value, chevron; flagged values in warning style) · **Nag until done** switch · one-line "first alert" summary · **Type** (Task · Meeting · Event · Occasion · Bill) and **Personal/Work** segmented controls; for a Bill also **Payment · Subscription · Free trial** and an **Amount** row (`BIL-1`, `BIL-2`) · **Notes, links & files** group (Add note · Add link · Add file, `ATT-*`). A type badge left of the input shows the parsed type; the details slide in as the sheet grows (DS15). While typing, rows update live; the keyboard collapses to review | Row → S-21 picker · Save / Enter → closes + snackbar |
| S-21 | **Chip pickers** (small sheets) | a Date · b Time (+ end time) · c Time zone · d Type · e Context · f Repeat (incl. "after completion") · g Alerts (stages, start-by, nag) | Done → back to S-20 (field locked, `CAP-11`) |
| S-22 | **Full editor** | Type badge, then all fields (bills: kind and amount): title, date/time/end, zone, type, context, repeat, alerts, nag until done, notes, links & files (`ATT-*`) | **[Save]** · ⤷ recurring → S-34 |
| S-23 | **Overlay capture host** | S-20 shown over the home screen / current app (widget, tile, share) | Save/close → back to where the user was |

### Details & actions

| ID | Screen | Contents | Actions → |
|---|---|---|---|
| S-30 | **Reminder detail** | Bills: amount card, **Paid** / **Got it** · **I cancelled it**; free trial: "Your trial ends …" with **Keep it** (monthly / yearly) and **I cancelled** (`BIL-5`). Title, type/context chips, when (+ original zone if different), repeat summary, alert plan, notes (links tappable, `ATT-5`), links & files (tap to open, `ATT-4`), occurrence state, merge banner if duplicate (`CAL-9`) | **[Done]** / **[I'm prepared]** · **[Reschedule]** → S-33 · **[Skip]** · **[Edit]** → S-22 · **[Delete]** |
| S-31 | **Calendar event detail** | Title, time, calendar name/color, attendee count, type chip (changeable, `CAL-5`), alerts if set | **[Remind me]** → S-32 · type chip → S-21d |
| S-32 | **Remind me picker** | Presets: 10 min, 1 hour, 1 day before, Custom; multi-select | **[Save]** → ⤷ series → S-34 |
| S-33 | **Reschedule sheet** | Later today · This evening · Tomorrow · Next week · Pick date & time | Tap → saved, sheet closes |
| S-34 | **Scope dialog** | "This one" / "This and future" (edit) or "This one" / "All" (delete, series alerts) | Choice → apply |

### Other screens

| ID | Screen | Contents | Actions → |
|---|---|---|---|
| S-40 | **Search** | Search field, live results (active + archived), empty state G7 | Result → detail · **[Create '…']** → S-20 |
| S-41 | **Digest card** (component on S-12; on today's S-13 a one-line bar that expands into the card) | Overdue · Missed · Coming up · Removed from calendar (`DIG-2`) | Per-item actions · **[Dismiss]** |
| S-42 | **Completed** | Done/archived reminders, newest first, searchable | Tap → detail (read-only for resolved) · **[Mark as not done]** |

### Settings

| ID | Screen | Contents |
|---|---|---|
| S-50 | **Settings home** | Sections linking to S-51…S-58 |
| S-51 | **Your schedule** | Same fields as S-02 |
| S-52 | **Time zone** | Default zone picker → change dialog (`TIM-7`) · travel prompt toggle (`PRF-2`) |
| S-53 | **Default alerts** | Default alert plan per type (`PRF-9`) |
| S-54 | **Notifications & digest** | Digest time, digest notification, late-alert cutoff (`PRF-6–8`) |
| S-55 | **Calendars & contacts** | Connect/disconnect calendars, pick calendars · contact birthdays on/off, review list, auto-add new birthdays (`PRF-13`) · permission status |
| S-56 | **Views & appearance** | Start in (last used / Schedule / Day / Month), show completed, theme (system / light / dark), completion sounds (`PRF-12`) |
| S-57 | **Reliability** | Status of notifications, exact alarms, battery optimization — each with **[Fix]** · **[Send test reminder]** with last result (`PRM-7`) |
| S-58 | **Backup & about** | Export / import (FL-17), privacy policy, feedback, **Replay intro** (FL-1 again; data and settings kept, ends back here), licences, version |

### Outside the app

| ID | Surface | Contents |
|---|---|---|
| S-60 | **Notifications** | Layouts per `NTF-2`; grouped summary (`SCH-10`); 5 s Done/Undo replacement (`NTF-9`); digest notification; late-alerts group (G5) |
| S-61 | **Home-screen widget** | **4×2 by default** (mockup 05): day + date and "N left" on top, the next 3 items with type-colored bars, a tall **[+ Add]** on the right. Resizable from 3 columns |
| S-62 | **Quick Settings tile** | "+ Reminder" |
| S-63 | **Share target** | "Reminder App" in the Android share sheet |

---

## 4. Shared components

Design these once; they appear across many screens.

| Component | Used in |
|---|---|
| Reminder row (title, time, type color, icons: repeat, bell, calendar, work badge, overdue style, done style) | S-12, S-40, S-42, S-41 |
| Time-grid block | S-13, S-15, S-16 |
| All-day strip item | S-13, S-15, S-16 |
| Month cell label | S-14 |
| Preview chip (normal / warning / locked) | S-20 |
| Group header (Overdue, Today…) | S-12 |
| Banner (info / warning) | S-10 |
| Snackbar with Undo | everywhere |
| Bottom sheet frame | S-20, S-21, S-32, S-33 |
| Empty state (illustration + text + action) | S-12, S-13, S-40, S-42 |
| Type icon + color set (4 types) | everywhere |

---

## 5. Screen ↔ flow check

| Flow | Screens |
|---|---|
| FL-1 Onboarding | S-01, S-01a, S-01b, S-02–S-08, S-20 |
| FL-2–FL-5 Capture | S-20, S-21, S-22, S-23, S-61–S-63 |
| FL-6–FL-8 Hero use cases | S-20, S-60, S-12, S-30 |
| FL-9 Calendar + Remind me | S-31, S-32, S-34, S-30 (merge banner) |
| FL-10 Notifications | S-60, S-30 |
| FL-11 Reschedule | S-33, S-34 |
| FL-12 Browsing | S-10–S-18, S-40, S-42 |
| FL-13 Edit & delete | S-30, S-22, S-34 |
| FL-14 Repeat after completion | S-30, S-60 |
| FL-15 Digest | S-41, S-60 |
| FL-16 Time zones | S-52 |
| FL-17 Backup | S-58 |
| FL-18 States | S-10 banners, S-12–S-14 empty states, S-40, S-57 |
