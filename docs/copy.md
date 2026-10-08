# Copy & Notification Text — v1.0

Every word the user reads: notifications, onboarding, capture hints, empty states, dialogs, settings. For a reminder app, **notification wording is the product** — it's what people see most.

Related: [`behavior-spec.md`](behavior-spec.md) (`NTF-*` rules) · [`screens.md`](screens.md) (screen IDs) · [`design-direction.md`](design-direction.md) (bell mascot)

**String keys** (e.g. `notif.task.due`) are the IDs used in code. All strings go through the translation layer (D3) — no hard-coded text. `{placeholders}` are filled at runtime.

---

## 1. Voice & tone

| Principle | Do | Don't |
|---|---|---|
| **Brief** | "Pay rent · Today" | "This is a reminder that you need to pay rent today." |
| **Calm, never guilt-tripping** | "Still to do" | "You forgot!", "Overdue again!" |
| **Plain words** | "Done", "Snooze", "Skip" | "Complete", "Defer", "Dismiss occurrence" |
| **Specific** | "Mon, Oct 12" | "Soon" |
| **Playful only where the bell appears** | Onboarding, empty states, celebrations | Notifications, errors, settings |

**Word list** — use consistently:
- **reminder** (not item, entry, task — unless it's specifically a Task)
- **Done** · **Snooze** · **Skip** · **Reschedule** · **I'm prepared**
- **Overdue** (in the app) · **Still to do** (in notifications)
- **alerts** (the notifications a reminder sends) — not "pings" or "triggers"
- **Personal** / **Work**

**Bell mascot voice:** short, warm, a little cheeky — speaks only in onboarding, empty states, and celebrations. Never sarcastic about missed things.

### Date & time formatting
- 12h/24h follows the device; date order follows the locale (D3).
- **Relative first, absolute second:** "Tomorrow · 6:00 PM", "In 1 week · Mon, Oct 12".
- Relative labels: **Now** · **In {n} min** · **In {n} h** · **Today** · **Tomorrow** · **In {n} days** (2–6) · **In 1 week** · **In {n} weeks** · **In 1 month** / **In {n} months**.
- Absolute: same week → "Thu 3:00 PM" · this year → "Mon, Oct 12" · other year → "Mon, Oct 12, 2027".
- Different time zone (`TIM-6`): "6:00 PM (3:00 PM London)".

---

## 2. Notifications (S-60)

### Android notification channels
Users see these names in Android's notification settings.

| Channel | Name | Description | Importance |
|---|---|---|---|
| `reminders` | Reminders | Alerts for your reminders | High (sound + heads-up) |
| `nag` | Nagging reminders | Repeat alerts until you mark something done | High |
| `digest` | Daily digest | Your morning summary of overdue and upcoming items | Default |
| `system` | App status | Late alerts, time zone changes, reliability tips | Low |

### Alert notifications
Title is always the reminder title. Body = **stage label · when**. Buttons per `NTF-2`.

| Key | Situation | Body | Buttons |
|---|---|---|---|
| `notif.atTime` | Task / reminder at its time | Now · {time} *(date-only: "Today")* | Snooze 1h · Tomorrow · Done |
| `notif.before` | Any stage before the time | In {relative} · {absolute} — e.g. "In 1 week · Mon, Oct 12" | per type |
| `notif.meeting` | Meeting / Event before start | In {n} min · {time} — e.g. "In 10 min · 10:00 AM" | Snooze 5m · Open |
| `notif.startBy` | "Start by" stage (`ALR-5`) | Start today · due {absolute} | Snooze 1h · Tomorrow · Done |
| `notif.occasion.prep` | Occasion prep stage | In {relative} · {absolute} | Tomorrow · I'm prepared · Done |
| `notif.occasion.today` | Occasion day-of | Today | Snooze 1h · Done |
| `notif.nag` | Nag repeat (`ALR-9`) | Still to do · due {time or "since {day}"} | Snooze 1h · Tomorrow · Done |
| `notif.late` | Late alert (`SCH-7`) | {normal body} · was {time} | as normal |
| `notif.doneUndo` | 5 s after Done (`NTF-9`) | Title: "Done" · Body: {title} | Undo |
| `notif.preparedUndo` | 5 s after I'm prepared | Title: "Prepared" · Body: {title} | Undo |

**Examples**
> **Mom's birthday**
> In 1 week · Mon, Oct 12
> [Tomorrow] [I'm prepared] [Done]

> **Pay rent**
> Still to do · due today
> [Snooze 1h] [Tomorrow] [Done]

> **Client call**
> In 10 min · 10:00 AM
> [Snooze 5m] [Open]

### Summary & system notifications
| Key | Title | Body | Buttons |
|---|---|---|---|
| `notif.group` | {n} reminders | {title1}, {title2}, and {n-2} more | — |
| `notif.lateGroup` (G5) | {n} reminders while your phone was off | Tap to see them | — |
| `notif.digest` (`DIG-3`) | Your day | {n} overdue · {n} missed · {n} coming up *(empty parts omitted)* | Open |
| `notif.travel` (`TIM-8`) | You're in {city} | Switch your default time zone? | Switch · Keep {old city} |

**Button labels:** Done · Snooze 1h · Snooze 5m · Tomorrow · I'm prepared · Open · Undo · Switch · Keep {city}

---

## 3. Onboarding (S-01 – S-07)

| Screen | Copy |
|---|---|
| **S-01 Welcome** | Title: **Never forget the things that matter.** · Sub: Birthdays, bills, meetings, errands — one place, gentle nudges. · Button: **Get started** |
| **S-01a Just type it** | Title: **Just type it.** · Sub: Write it like you'd say it. We'll handle the rest. · Demo text: *Mom's birthday Oct 12* · After demo: **Try your own** · Placeholder: *e.g. Pay rent on the 1st every month* · Buttons: **Save this** / **Next** · Bell (thinking): "Ooh, a birthday. Got it." |
| **S-01b Nudges demo** | Title: **Nudged before it matters.** · Sub: Drag through the week. For big days, you get a heads-up early — not just on the day. · Hint under slider: *Drag me →* · After tapping I'm prepared in the mockup: "Prepared? We'll stop the early nudges." · Button: **Next** |
| **S-02 Your schedule** | Title: **Your schedule** · Sub: We picked sensible defaults. Change anything you like. · Rows: **Time zone** · **Date-only reminders at** — *For things without a time, like "pay rent on the 1st"* · **Repeat reminders between** — *We only nag you during these hours* · **"Tomorrow" means** — *Tomorrow at 9:00 AM / Same time tomorrow* · Buttons: **Looks good** / **Skip** |
| **S-03 Connect calendar** | Title: **See your calendar here too** · Sub: Your events show up next to your reminders. Read-only — we'll never change your calendar, and events won't ring unless you ask. · Buttons: **Connect calendar** / **Not now** |
| **S-04 Pick calendars** | Title: **Which calendars?** · Sub: You can change this anytime in Settings. · Button: **Done** |
| **S-08 Contact birthdays** | Title: **Never miss a birthday** · Sub: Add birthdays and anniversaries from your contacts. Only the dates are used — nothing leaves your phone. · Buttons: **Add birthdays** / **Not now** · Review: {n} birthdays, {n} anniversaries found · Button: **Import** · Bell (happy): "Party planning starts now." |
| **Test reminder** (`PRM-7`) | Prompt: **Want to make sure it works?** · Sub: We'll send a test reminder in 15 seconds. Lock your phone to try it for real. · Buttons: **Send test reminder** / **Skip** · Notification: *Test reminder* — *It works! 🔔* · Results: ✅ **Reminders are working** · ⚠️ **Arrived {n} seconds late** — {fix} · ❌ **The test didn't arrive** — Let's fix it: {steps} |
| **S-05 Notifications** | Title: **Let us ring the bell** · Sub: Allow notifications so your reminders reach you on time. · Button: **Continue** · Bell: rings |
| **S-06 Precise timing** | Title: **Right on time** · Sub: Allow "Alarms & reminders" so alerts arrive on the minute, not up to 10 minutes late. · Buttons: **Open settings** / **Not now** |
| **S-07 Reliability tip** | Title: **Keep reminders reliable** · Sub: Your {brand} phone may pause apps to save battery. One quick setting keeps your reminders on time. · Buttons: **Show me how** / **Later** |

---

## 4. Capture (S-20 – S-23)

**Input placeholder** — rotates through examples each time the sheet opens:
- *Call mom Sunday 6pm*
- *Pay rent on the 1st every month*
- *Mom's birthday Oct 12*
- *Dentist Friday 2:30pm*
- *Change AC filter every 3 months after done*

**Chip labels:** {title} · {date} · {time} · {zone} · Task / Meeting / Event / Occasion · Personal / Work · {repeat summary} · Alerts: {summary} · Nag every {interval}

**Repeat summaries:** Every day · Every weekday · Every {weekday} · Every 2 weeks · Every month on the {nth} · Last business day of the month · Every year · Every 3 months after done

**Alert summaries:** At time · {n} min before · 1 week, 1 day, on the day · No alerts

**Warning hints** (shown under a highlighted chip):
| Flag | Hint |
|---|---|
| `ambiguous_time` | Did you mean {time}? Tap to change. |
| `ambiguous_date` | That's {absolute}. Tap to change. |
| `past_date_rolled` | Moved to next year ({absolute}). |
| `time_in_past` | This time has already passed. |
| `title_missing` | Add a title |
| `date_missing` | When is it? |

**Templates** (`TPL-3`): Birthday · Bill due · Renewal · Free trial · Night out · Appointment
Placeholders: *Whose birthday? When?* · *Which bill? Due on the…* · *What renews? When?* · *Which trial?* · *Where and when?* · *What and when?*

**Buttons:** Save · More options · 🎤 (label: "Speak")
**Saved snackbar:** Saved · {when} — **Undo**
**Share sheet saved toast:** Reminder saved

---

**Shared text (CAP-12):** under the input when links or long text went to notes — "Shared text and links saved in notes"

## 5. Home, views & lists (S-10 – S-18)

**Group headers:** Overdue · Today · Tomorrow · This week · Later · {Month Year}
**Day view:** All day · Overdue ({n})
**Month view:** +{n} more
**Drawer:** Schedule · Day · Month · Types · Context · Calendars · Completed · Settings · Help & feedback

Calendars section is collapsed by default; when some are filtered out it shows "{count} hidden". Same-named calendars show their account underneath.
**Top bar:** Today · Search

### Empty states (with bell)
| ID | Where | Title | Sub | Button |
|---|---|---|---|---|
| G1 | No reminders yet | **Nothing to remember… yet** | What's on your mind? | Tap an example chip |
| G6 | Nothing today | **Nothing due today** | Enjoy the quiet. | — |
| G7 | No search results | **No matches for "{query}"** | — | Create "{query}" |
| G8 | Filter shows nothing | **No {filter} reminders** | — | Clear filters |
| — | Completed is empty | **Nothing done yet** | Finished reminders will show up here. | — |

### Banners
| ID | Text | Button |
|---|---|---|
| G2 | Notifications are off — you won't be reminded. | Turn on |
| G3 | Reminders may arrive up to 10 minutes late. | Fix |
| G4 | Calendar access was turned off. | Reconnect |
| G10 | Your phone may be delaying reminders. | Show me how |

### Digest card (S-41)
- Title: **Your day** · Dismiss: **Dismiss**
- Sections: **Overdue** · **Missed while you were away** · **Coming up** · **Removed from your calendar**
- Old overdue (`OVD-3`): "Overdue for a month. Still relevant?" — **Keep** / **Skip**

---

## 6. Details, actions & dialogs

**Reminder detail buttons:** Done · I'm prepared · Reschedule · Skip · Edit · Delete
**Detail status card:** Pending · Overdue · Done · Skipped · Prepared · Passed · "Snoozed until {time}" (while a snooze is pending, even if the item is past due)
**Calendar event detail:** "From {calendar name}" · **Remind me**
**Remind me picker:** 10 min before · 1 hour before · 1 day before · Custom…

**Reschedule sheet:** Later today · This evening · Tomorrow · Next week · Pick date & time

**Scope dialogs (S-34):**
| Situation | Title | Options |
|---|---|---|
| Edit recurring | Change which reminders? | This one · This and future |
| Delete recurring | Delete which reminders? | This one · All |
| Remind me on recurring event | Apply to which events? | This event · All events in series |

**Snackbars:** Done — Undo · Skipped — Undo · Deleted — Undo · Rescheduled to {when} — Undo

**Duplicate banner (`CAL-9`):** This looks like it's on your calendar. — **Merge** / **Keep both**

**Time zone dialogs (FL-16):**
- Title: **Change default time zone?** — Options: **Only new reminders** / **Also move upcoming reminders**
- Confirm: {n} upcoming reminders will keep their clock time in {zone}. — **Confirm** / **Cancel**

**Backup (FL-17):**
- Import summary: {n} reminders found · {n} newer than yours · {n} already here — **Import**
- Error: This file isn't a Reminder App backup.
- Success: Imported {n} reminders.

---

## 7. Completion & celebrations

| Moment | Copy |
|---|---|
| Standard completion | *(no text — animation, sound, and Undo snackbar "Done")* |
| Repeat after completion (FL-14) | Done · Next: {date} |
| Skip on repeat after completion | Skipped · Next: {date} |
| **All clear** (last of Today done) | **All clear!** · Nothing left for today. |
| Occasion done | Hope it's a great one! |
| First reminder ever completed | **Your first one!** · That's how it's done. |

---

## 8. Settings (S-50 – S-58)

| Setting | Label | Description |
|---|---|---|
| PRF-1 | Default time zone | New reminders use this time zone. |
| PRF-2 | Ask when I travel | Offer to switch time zones when you're somewhere new. |
| PRF-3 | Date-only reminders at | Alert time for reminders without a time. |
| PRF-4 | Nag hours | Repeat alerts only between these times. |
| PRF-5 | "Tomorrow" means | When "Tomorrow" on a notification brings it back. |
| PRF-6 | Late alerts | If your phone was off, still show alerts up to this late. |
| PRF-7 | Digest time | When your daily summary arrives. |
| PRF-8 | Digest notification | Get a notification when your digest is ready. |
| PRF-9 | Default alerts | Alerts new reminders start with, by type. |
| PRF-12 | Completion sounds | Play a sound when you complete a reminder. |
| VW-1 | Start in | Last used · Schedule · Day · Month |
| VW-6 | Show completed in calendar views | — |
| — | Theme | System · Light · Dark |

**Reliability screen (S-57):** Notifications — On / Off · Precise timing — On / Off · Battery optimization — Off / On (may delay reminders) — each with **Fix**.

---

## 9. Errors

| Situation | Message |
|---|---|
| Voice not available | Voice input isn't available on this phone. |
| Didn't catch speech | Didn't catch that. Try again? |
| Save failed (storage) | Couldn't save. Please try again. |
| Calendar read failed | Couldn't load your calendar. Pull to retry. |
| Generic | Something went wrong. Please try again. |

Error messages never blame the user, never show codes, and always say what to do next.
