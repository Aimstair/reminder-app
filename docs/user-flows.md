# User Flows — v1.0

Step-by-step flows for every core path in v1.0. Each flow has an ID (`FL-6`) used by the screen inventory and tests. Rule IDs in backticks point to [`behavior-spec.md`](behavior-spec.md); parser behavior is in [`parser-test-set.md`](parser-test-set.md).

**Conventions:** **[Button]** = tap target · *System dialog* = Android-owned screen · → = next step · ⤷ = branch.

| ID | Flow | Section |
|---|---|---|
| FL-1 | First launch & onboarding | A |
| FL-2 | Quick capture (in app, typed or voice) | B |
| FL-3 | Capture from widget | B |
| FL-4 | Capture from Quick Settings tile | B |
| FL-5 | Capture from share sheet | B |
| FL-6 | Hero 1 — Occasion with prep | C |
| FL-7 | Hero 2 — Bill with nag until done | C |
| FL-8 | Hero 3 — Quick errand | C |
| FL-9 | Hero 4 — Calendar event + "Remind me" | C |
| FL-10 | Acting on a notification | D |
| FL-11 | Reschedule | D |
| FL-12 | Browsing the list | E |
| FL-13 | Edit & delete | E |
| FL-14 | Completing a repeat-after-completion task | E |
| FL-15 | Daily digest | E |
| FL-16 | Time zone change & travel | F |
| FL-17 | Backup export & import | F |
| FL-18 | Empty, error & permission states | G |

---

## A. Onboarding

### FL-1 First launch & onboarding
Goal: first reminder saved in **under 60 seconds**. Every step except Welcome can be skipped; skipping applies defaults (`PRF-11`). No account, no sign-in in v1.0.

Onboarding is **interactive and animated** — animation details in [`design-direction.md`](design-direction.md) §5.

```
Welcome ─► Just type it ─► Nudges demo ─► Your schedule ─► Calendar (optional) ─► Home
              │ [Save this] = first reminder                                    (capture sheet open
              ▼                                                                  if nothing saved yet)
          [save] ─► Notification permission ─► Exact alarm permission ─► Battery tip (some phones)
```

1. **Welcome** — app promise in one line; scattered notes gather into one list on **[Get started]**.
2. **Just type it** — an input types *"Mom's birthday Oct 12"* by itself while chips pop in. "Try your own": the user types anything and the real parser responds live.
   - **[Save this]** → saves it as their first reminder (triggers step 7 permissions) → continue
   - **[Next]** / **[Skip]** → continue without saving
3. **Nudges demo** — user drags a slider through a week on a phone mockup; nudges appear at 1 week / 1 day / the day; tapping **[I'm prepared]** in the mockup removes the remaining nudges. **[Next]** / **[Skip]**
4. **Your schedule** — pre-filled defaults, editable inline (`PRF-1`, `PRF-3`, `PRF-4`, `PRF-5`); the nag-hours slider drives a sunrise-to-night sky animation:
   - Time zone: *America/New_York* (device zone)
   - Day time for date-only reminders: *9:00 AM*
   - Nag hours: *8:00 AM – 10:00 PM*
   - "Tomorrow" snooze: *Tomorrow at 9:00 AM* / *Same time tomorrow*
   - **[Looks good]** · **[Skip]**
5. **Calendar** — "See your calendar events alongside your reminders?" Explains: read-only, events won't ring unless you ask. Calendar cards slide into the timeline when connected.
   - **[Connect calendar]** → *System dialog: allow calendar access*
     - ⤷ Allowed → **Pick calendars** (all on by default, toggle each) → **[Done]**
     - ⤷ Denied → continue; calendar can be enabled later in Settings (`PRM-3`)
   - **[Not now]** → continue
   - Then: **"Add birthdays from your contacts?"** (`CON-1`) — **[Add birthdays]** → explanation → *System dialog: contacts* → **review list** (`CON-3`, all selected) → **[Import]** → occasions animate into the timeline · **[Not now]** → continue
6. **Home** — if no reminder was saved in step 2, the capture sheet opens with example chips to tap: *"Mom's birthday Oct 12"*, *"Pay rent on the 1st every month"*, *"Call mom Sunday 6pm"* → FL-2. Otherwise Home shows the saved reminder animated into place.
7. **On first save of a reminder with alerts** (`PRM-6`) — whenever it happens (step 2 or 6):
   1. Explainer with animated ringing phone: "Allow notifications so we can remind you." **[Continue]** → *System dialog: notifications*
      - ⤷ Denied → reminder still saved; banner on Home (FL-18 G2)
   2. If exact alarms aren't allowed (Android 12+): explainer "Allow precise timing so reminders arrive on the minute." **[Open settings]** → *System settings: Alarms & reminders* → user toggles → returns to app
      - ⤷ Not granted → inexact mode + banner (FL-18 G3)
   3. On phones known to kill background apps (Samsung, Xiaomi, OnePlus, etc.): one-time tip "Keep reminders reliable" with phone-specific steps. **[Show me]** / **[Later]** (`PRM-4`)
   4. **"Want to make sure it works?"** — **[Send test reminder]** → alert arrives in 15 s (lock the phone to try) → result ✅ / ⚠️ / ❌ with fixes (`PRM-7`) · **[Skip]**. Also available anytime in Settings → Reliability.
8. Onboarding complete; Home in Schedule view.

---

## B. Capture

### FL-2 Quick capture (in app)
1. Home → **[+]** (floating button) → **capture sheet** slides up, keyboard open, cursor in the input.
   - ⤷ **Template:** while the input is empty, a row of templates shows — *Birthday · Bill due · Renewal · Free trial · Night out · Appointment*. Tap one → its type, repeat, and alerts are set and locked; placeholder asks for the rest (e.g. *"Which bill? Due on the…"*) (`TPL-1`–`TPL-4`).
2. User types. **Preview chips** update live under the input (`CAP-7`):
   `Call mom` · `Sun, Oct 11` · `6:00 PM` · `Task` · `Personal` · *(Repeat)* · *(Alerts: at time)*
   - Highlighted chips (`ambiguous_time`, `ambiguous_date`, `past_date_rolled`, `time_in_past`) are drawn in a warning style.
   - Zone chip appears only if different from default (`CAP-9`).
3. ⤷ **Edit a chip:** tap → small picker for that field only (date picker, time picker, type selector, context toggle, repeat picker, alert plan picker). Editing a chip **locks** it: later typing no longer changes that field.
4. ⤷ **Voice:** **[🎤]** → speech recognition → recognized text fills the input → same preview. Never saves on its own (`CAP-7`).
5. ⤷ **More options:** **[⋯]** → expands to the full editor (notes, end time, time zone, nag until done, start-by).
6. **[Save]** (or keyboard Enter):
   - ⤷ `title_missing` or `date_missing` → Save disabled; the missing chip pulses.
   - Saved → sheet closes → item animates into its group → snackbar "Saved · Sun, Oct 11, 6:00 PM" **[Undo]** (5 s).
7. First-save permission steps if not yet done (FL-1 step 5).

**Target:** simple capture (open → saved) < 3 s (D4).

### FL-3 Capture from widget
1. Home-screen widget shows **[+]** and the next 3 reminders.
2. **[+]** → capture sheet opens **over the home screen** (lightweight screen, not the full app) → FL-2 steps 2–6 → closes back to the home screen.
3. Tapping a listed reminder → opens the app on that reminder's detail.

### FL-4 Capture from Quick Settings tile
1. Pull down notification shade → **[+ Reminder]** tile → shade collapses → capture sheet over current app → FL-2 → returns to the previous app.

### FL-5 Capture from share sheet
1. In any app, select text or a message → **Share** → **Reminder App**.
2. Capture sheet opens over the source app with the shared text in the input, parsed.
   - Text longer than 120 characters: the first sentence goes in the input; the full text goes in **notes**.
   - Shared links are kept in notes.
3. FL-2 steps 2–6 → **[Save]** → returns to the source app with a toast "Reminder saved".

---

## C. Hero use cases

### FL-6 Hero 1 — Occasion with prep
1. Capture "Mom's birthday Oct 12" → preview: `Mom's birthday` · `Oct 12` · `Occasion` · `Every year` · `Alerts: 1 week, 1 day, on the day` → **[Save]**.
2. **7 days before, 9:00 AM** — notification: *Mom's birthday · In 1 week · Mon, Oct 12* — **[Tomorrow]** **[I'm prepared]** **[Done]**
   - ⤷ **[Tomorrow]** → re-alerts tomorrow at the "Tomorrow" time (`NTF-4`)
   - ⤷ **[I'm prepared]** → state `prepared`; prep alerts stop; day-of alert stays (`OCC-3`)
   - ⤷ Ignored → next stage still fires
3. **1 day before** (unless prepared) — *In 1 day · tomorrow*, same buttons.
4. **On the day, 9:00 AM** — *Today is Mom's birthday* — **[Snooze 1h]** **[Done]**.
5. **[Done]** or day ends → occurrence resolved; **next year's** occurrence is waiting with the same alerts.
6. Daily digest lists this occasion during the 7 days before if not prepared/done (`DIG-2`).

### FL-7 Hero 2 — Bill with nag until done
1. Capture "pay rent on the 1st every month nag me" → preview: `Pay rent` · `1st of every month` · `Task` · `Nag every 2h` → **[Save]**.
2. **1st, 9:00 AM** — *Pay rent · Today* — **[Snooze 1h]** **[Tomorrow]** **[Done]**.
3. ⤷ Ignored or swiped away (`NTF-6`) → **11:00 AM** nag: *Still to do · Pay rent* → every 2 h within nag hours → **10:00 PM** last → resumes **8:00 AM** next day (`ALR-11`).
4. ⤷ **[Snooze 1h]** → nag paused 1 h, then resumes (`ALR-12`).
5. **[Done]** (from notification or app) → nags stop; next occurrence: 1st of next month.
6. ⤷ Not done after 3 days of nagging → nags stop; stays in **Overdue** and in the digest (`ALR-13`).

### FL-8 Hero 3 — Quick errand
1. Widget **[+]** → "buy milk" → preview: `Buy milk` · `Tomorrow` · `Task` → **[Save]** → back to home screen. (≤ 3 s)
2. **Tomorrow, 9:00 AM** — *Buy milk · Today* — **[Snooze 1h]** **[Tomorrow]** **[Done]**.
3. ⤷ **[Done]** → resolved, archived after 7 days (`DAT-3`).
4. ⤷ Ignored → stays in **Today** until end of day → becomes **Overdue** the next day (`TIM-12`) → appears in the digest.

### FL-9 Hero 4 — Calendar event + "Remind me"
1. Imported events appear in the list with a calendar icon and **no bell** (no alerts by default, `CAL-6`).
2. Tap event "Client call Thu 10:00" → **event detail** (read-only: title, time, calendar, attendees count) with **[Remind me]**.
3. **[Remind me]** → alert picker: *10 min before* · *1 hour before* · *1 day before* · *Custom…* (multiple allowed).
4. If the event repeats → "Apply to **[This event]** or **[All events in series]**?"
5. Saved as overlay → bell icon appears on the event in the list.
6. ⤷ **Event moved in calendar** → alerts move with it (`CAL-7`).
7. ⤷ **Event deleted in calendar** → alerts cancelled; next digest notes "Removed from your calendar: Client call" (`CAL-8`).
8. ⤷ **Wrong type** (e.g. tagged Event, should be Meeting) → tap type chip on detail → choose → applies to the series and is remembered (`CAL-5`).
9. ⤷ **Duplicate:** a manual reminder "client call Thursday 10am" matches an imported event → banner on the manual reminder's detail: "This looks like it's on your calendar." **[Merge]** / **[Keep both]** (`CAL-9`).

---

## D. Notifications & rescheduling

### FL-10 Acting on a notification
Buttons per situation are defined in `NTF-2`. All actions run without opening the app (`NTF-8`).

| Action | Result | Feedback |
|---|---|---|
| **[Done]** | Occurrence `done`; other alerts for it cancelled (`OCC-4`) | Notification is replaced for 5 s by *"Done · Pay rent"* **[Undo]** (`NTF-9`) |
| **[I'm prepared]** | `prepared`; prep stages cancelled (`OCC-3`) | Same 5 s replacement with **[Undo]** |
| **[Snooze 1h] / [Snooze 5m]** | Alert re-fires after delay (`NTF-4`) | Notification dismissed |
| **[Tomorrow]** | Alert re-fires tomorrow at `PRF-5` time | Notification dismissed |
| **[Open]** / tap body | Opens app on occurrence detail (`NTF-3`) | — |
| Swipe away | Nothing changes (`NTF-6`) | — |

### FL-11 Reschedule
Entry points: swipe left on a list item · **[Reschedule]** on detail · from digest.
1. **Reschedule half-sheet** with quick options:
   - *Later today* (+3 h, rounded to the hour) · *This evening* (18:00) · *Tomorrow* (day time) · *Next week* (Monday, day time) · *Pick date & time…*
2. Tap an option → saved → sheet closes → item moves to its new group with animation.
3. ⤷ Recurring reminder → changes **this occurrence only** (`NTF-7`, `REC-12`); to change the series, use Edit (FL-13).
4. Alerts recomputed from the new time (`SCH-8`).

---

## E. Managing reminders

### FL-12 Browsing the list
1. **Home** opens in the last-used view (`VW-1`). Default **Schedule** = one timeline grouped: **Overdue** · **Today** · **Tomorrow** · **This week** · **Later** (`OVD-2`). Digest card on top when present (FL-15).
   - ⤷ **Switch view** (top bar or ☰ drawer): **Day** (time grid) · **Month** (grid) — *3 Day, Week, Year in v1.2*. Swipe to move between days/months; **[Today]** jumps back; tap the title for a mini month picker (`VW-8`, `VW-9`). Full view rules: `screens.md` §1.
   - ⤷ **Tap an empty time slot** (Day) → capture pre-filled with that time · **tap a day** (Month) → Day view · **long-press a day** (Month) → capture pre-filled with that date.
2. **Filters** in the ☰ drawer, like calendars in Google Calendar: types (Meeting / Task / Event / Occasion, each with its color), context (Personal / Work), imported calendars. Active filters show as chips under the top bar with **[Clear]**. Filters apply to every view (`VW-2`).
3. **Search** icon → search field; results across active and archived reminders as you type (`DAT-3`).
4. **Swipe right** → Done (completable only; others: no action) with **[Undo]** snackbar (`OCC-5`).
5. **Swipe left** → Reschedule (FL-11).
6. **Tap** → detail.
7. **"Completed"** filter shows archived/done items.

### FL-13 Edit & delete
1. Detail → **[Edit]** → full editor (all fields).
2. **[Save]**:
   - ⤷ Recurring → "**[This one]** or **[This and future]**?" (`REC-11`–`REC-13`)
   - Alerts recomputed (`SCH-8`).
3. Detail → **[Delete]**:
   - ⤷ Recurring → "**[This one]** or **[All]**?" (`REC-15`)
   - Item disappears → snackbar **[Undo]** (5 s) (`DAT-1`).

### FL-14 Completing a repeat-after-completion task
1. "Change AC filter" (every 3 months after done) is due → user taps **[Done]** (notification, swipe, or detail).
2. Snackbar confirms the next date: *"Done · Next: Jan 10"* **[Undo]** (`REC-6`).
3. ⤷ **[Skip]** from detail → next date counted from the skipped due date (`REC-7`); snackbar *"Skipped · Next: Jan 1"*.

### FL-15 Daily digest
1. At digest time (08:00 default) → if there's content, notification *"3 overdue · 1 missed · 1 birthday this week"* **[Open]** (`DIG-3`).
2. Home shows the **digest card** at the top with sections (`DIG-2`):
   - Overdue — each with **[Done]** / **[Reschedule]**; after 30 days overdue: *"Still relevant?"* **[Keep]** / **[Skip]** (`OVD-3`)
   - Missed alerts — each with **[Done]** / **[Reschedule]**
   - Coming up — occasions in the next 7 days not prepared — **[I'm prepared]**
   - Removed from calendar — informational
3. **[Dismiss]** hides the card until tomorrow's digest. Nothing in it → no card, no notification.

---

## F. Settings flows

### FL-16 Time zone change & travel
**Changing the default time zone** (Settings → Time zone):
1. Pick a new zone → dialog: "**[Only new reminders]**" or "**[Also move upcoming reminders]**" (`TIM-7`).
2. Second option shows the count first: "12 upcoming reminders will stay at the same clock time in the new zone." **[Confirm]**.

**Traveling** (`TIM-8`):
1. Device zone changes (e.g. lands in London) → next app open, or a silent notification if reminders are due within 24 h: "You're in London. Switch your default time zone?" **[Switch]** / **[Keep New York]**.
2. Either way, reminders display converted with their original zone shown when different: *"6:00 PM (1:00 PM New York)"* (`TIM-6`).
3. Asked once per zone change; can be turned off (`PRF-2`).

### FL-17 Backup export & import
1. Settings → Backup → **[Export]** → *System file picker* → saves a backup file.
2. **[Import]** → pick file → summary: *"42 reminders found · 3 newer than yours · 39 already here"* **[Import]** → merges by id, newer wins (`DAT-5`) → alarms rebuilt (`SCH-5`).
3. ⤷ Invalid file → *"This file isn't a Reminder App backup."*

---

## G. Empty, error & permission states (FL-18)

| ID | State | What the user sees | Action |
|---|---|---|---|
| G1 | **Empty list** (no reminders yet) | Illustration/animation + "What do you want to remember?" + example chips | Tap chip → capture prefilled |
| G2 | **Notifications off** (`PRM-1`) | Persistent banner on Home: "Notifications are off — you won't be reminded." | **[Turn on]** → system notification settings |
| G3 | **Exact alarms off** (`PRM-2`) | Banner: "Reminders may arrive up to 10 minutes late." | **[Fix]** → Alarms & reminders setting |
| G4 | **Calendar access revoked** (`CAL-10`) | Imported events hidden; one-time banner "Calendar access was turned off." | **[Reconnect]** / **[Dismiss]** |
| G5 | **Late alerts after reboot** (`SCH-7`) | One grouped notification: "3 reminders while your phone was off" | Tap → Home with those items highlighted |
| G6 | **Nothing today** | Today group shows "Nothing due today" (other groups still visible) | — |
| G7 | **No search results** | "No reminders match '…'" | **[Create '…']** → capture prefilled with the search text |
| G8 | **Filter shows nothing** | "No [Work] reminders" | **[Clear filters]** |
| G9 | **Save with past time** (`time_in_past`) | Highlighted time chip + hint "This time has passed" — saving is still allowed | — |
| G10 | **Battery optimization detected** on a known aggressive phone, after a late alert (`PRM-4`) | Tip card: "Your phone may be delaying reminders." | **[Show me how]** / **[Dismiss]** |

---

## Coverage check — use cases → flows

| Use case | Flow(s) |
|---|---|
| Birthdays & anniversaries | FL-6 |
| Bills, rent, pet meds (recurring + nag) | FL-7 |
| Errands, follow-ups | FL-8, FL-11 |
| Meetings & prep from calendar | FL-9 *(prep reminders linked to events: v1.2)* |
| Appointments, dinner plans, events | FL-2 |
| Deadlines, school forms ("start by") | FL-2 (⋯ More options), parser J3 |
| Free trials, returns | FL-2 (parser B5, A12) |
| Document expiry, certifications (month lead times) | FL-2, parser J5 |
| Home maintenance (repeat after completion) | FL-14 |
| Recurring work admin, invoicing | FL-2, parser F4, F7 |
| Travel across time zones | FL-16 |
| Medication several times a day | *v1.2* |
