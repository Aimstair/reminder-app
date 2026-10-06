# Parser Spec & Test Set — v1.0

What the quick-capture parser must understand, and 133 example inputs with their expected results. This file is both the **spec** and the **acceptance test**: each row becomes an automated test case.

Related: [`behavior-spec.md`](behavior-spec.md) §8 (`CAP-*` rules) · [`product-decisions.md`](product-decisions.md) (D3: English, global)

**v0 exit criterion:** ≥ 90% of counted cases pass. **v1.0 release:** ≥ 95%. Stretch cases (§S) are not counted.

**Status (2026-10-06):** ✅ **133 / 133 pass** — implementation `packages/core/lib/src/parser/`, tests `packages/core/test/parser/` (cases generated from this file: `cd packages/core && dart run tool/gen_parser_cases.dart`). Stretch cases S1–S6 not yet supported.

---

## 1. Test setup

All expected results assume:

| Setting | Value |
|---|---|
| **Now** | **Monday, Oct 5, 2026, 14:00** |
| Default time zone (`PRF-1`) | `America/New_York` |
| Locale | `en-US` (unless a row says `[en-GB]`) |
| Day time (`PRF-3`) | 09:00 |

Calendar reference (Oct 2026):

```
 Su  Mo  Tu  We  Th  Fr  Sa
      5*  6   7   8   9  10      * = today
 11  12  13  14  15  16  17
 18  19  20  21  22  23  24
 25  26  27  28  29  30  31
```
Nov 1 2026 = Sunday (US DST ends) · Mar 14 2027 = Sunday (US DST begins)

## 2. Output shape

The parser returns this structure (the test harness compares it field by field):

```ts
{
  title: string            // "" if nothing left after extraction
  timing: {
    type: "datetime" | "date"
    start: string          // "2026-10-11T18:00" or "2026-10-12"
    end?: string
    tz?: string            // only when different from the default zone
  } | null                 // null only when a required date is missing (Occasion)
  kind: "task" | "meeting" | "event" | "occasion"
  context: "personal" | "work"
  rrule?: string           // RFC 5545, e.g. "FREQ=WEEKLY;BYDAY=FR"
  repeatMode?: "fixed" | "after_completion"
  alerts?: string[]        // only when the input states alerts, e.g. ["-14d","0"]
  nag?: string             // e.g. "2h"
  flags: Flag[]            // which preview chips to highlight
}

type Flag = "ambiguous_time" | "ambiguous_date" | "past_date_rolled"
          | "time_in_past" | "title_missing" | "date_missing"
```

A row **passes** when every field shown in the row matches. Title comparison ignores letter case of the first character only. Empty cells mean "default / not set".

---

## 3. Parsing rules (`PRS`)

### Dates
- **PRS-1** Absolute dates: "Oct 20", "October 20th", "20 Oct", "2026-10-20", numeric dates in locale order ("10/12" = Oct 12 in en-US, 10 Dec in en-GB).
- **PRS-2** A date without a year that is **already past** rolls to **next year** (e.g. "Mar 3" → Mar 3 2027). The `past_date_rolled` flag is set **only for one-time reminders** — for repeating ones (occasions, "every year on March 3") next year is the expected meaning, so nothing is highlighted.
- **PRS-3** Month + year without a day ("March 2027") → the **1st** of that month, flag `ambiguous_date`.
- **PRS-4** A month name **without a day number** is only a date when preceded by *in / on / by / until* or followed by a year. Otherwise it's part of the title ("Pay May rent", "March band practice").
- **PRS-5** Relative dates: *today, tomorrow, day after tomorrow, in N days/weeks/months, in a week/month*.
- **PRS-6** *next week* → Monday of next week · *this weekend / weekend* → coming Saturday · *end of week* → coming Friday · *end of month* → last day of this month.
- **PRS-7** Weekdays (full and short: *Mon, Tue, Tues, Wed, Thu, Thurs, Fri, Sat, Sun*) follow `CAP-4`. *this Friday* = same as *Friday*. *next Friday* = Friday of **next** calendar week, flag `ambiguous_date`.
- **PRS-8** *the 15th / on the 1st* → the next such day of the month.

### Times
- **PRS-9** Formats: *6pm, 6 pm, 6:30pm, 6.30pm, 18:00, 6:00am*. An explicit am/pm or 24h time is never ambiguous.
- **PRS-10** Bare hours follow `CAP-5` (1–6 → PM, 7–11 → AM, 12 → noon) and set `ambiguous_time`. Applies to "at 6", "6", and "9:30" without am/pm.
- **PRS-11** Time words: *morning* → day time · *noon* → 12:00 · *afternoon* → 15:00 · *evening* → 18:00 · *tonight / night* → 20:00 · *midnight* → 00:00 of the **next** day.
- **PRS-12** Relative times: *in N minutes/min/hours/hrs* → datetime from now. A number + unit **without "in"** is not a time ("5 minute meditation").
- **PRS-13** Ranges: *2-4pm, 2–4pm, 10am-1pm, from 9 to 11* set start and end (`CAP-10`). An end earlier than the start rolls to the next day.
- **PRS-14** Meal defaults when an Event has no time: *breakfast* 08:00 · *lunch / brunch* 12:00 · *dinner / drinks* 19:00.
- **PRS-15** An explicit date with a time that's already past keeps that date and sets `time_in_past` ("today 1pm" said at 14:00).

### Time zones
- **PRS-16** Zone abbreviations map to IANA zones: *ET/EST/EDT* → New_York · *CT/CST/CDT* → Chicago · *MT/MST/MDT* → Denver · *PT/PST/PDT* → Los_Angeles · *GMT/UTC* → UTC · *BST* → London · *CET/CEST* → Paris · *JST* → Tokyo · *AEST/AEDT* → Sydney · *IST* → Kolkata.
- **PRS-17** "*[city] time*" or "*[time] [city]*" for major cities (London, Paris, Berlin, Tokyo, Sydney, Singapore, Dubai, New York, Chicago, LA, San Francisco, Toronto, Manila, Mumbai) sets that zone.
- **PRS-18** Relative dates ("tomorrow") are resolved in the **user's** zone; the time is then read in the stated zone.

### Recurrence
- **PRS-19** *every day / daily* · *every weekday* · *every Monday / Mondays* · *every Mon and Thu* · *every other week / every 2 weeks* · *weekly / monthly / yearly / annually* · *quarterly* (= every 3 months) · *every month on the 15th / on the 1st every month* · *last business day of the month* · *every N days/weeks/months*.
- **PRS-20** *until [date]* → `UNTIL` · *for N weeks/times* → `COUNT`.
- **PRS-21** **After completion:** *after done · after completion · after last one · after I last did it · since last time* → `repeatMode: after_completion`, and forces kind **Task** (`REC-10`).
- **PRS-22** If a recurrence has no start date, the first occurrence follows `CAP-1` (tomorrow).
- **PRS-23** Units the app can't schedule ("every 5000 miles") are not parsed; the text stays in the title.

### Alerts
- **PRS-24** *remind me X before* → replaces the default alert plan with `[-X]`; Occasions also keep the day-of stage `0`.
- **PRS-25** *the night before* → a stage at 20:00 the previous day · *the day before* → `-1d`.
- **PRS-26** *start [weekday/date]* on a Task with a due date → a "Start by" stage (`ALR-5`) plus the due stage `0`.
- **PRS-27** *nag me / until done* → `nag` with the default interval (2h).
- **PRS-28** *no alert / no reminder* → empty alert plan (`ALR-7`).

### Type & context
- **PRS-29** Type keywords (first match in this order wins):
  1. **Occasion:** *birthday, bday, anniversary* — unless followed by *party / dinner / drinks* (then Event)
  2. **Meeting:** *meeting, call with, standup, sync, 1:1, interview, sprint planning, retro, demo with*
  3. **Task (action verb at the start):** *buy, order, book, call, email, text, pay, send, submit, pick up, prepare, finish, review, renew, cancel, return, clean, fix, check, follow up, remind…* — an input starting with one of these is a Task even if it contains an Event word ("book table for dinner")
  4. **Event:** *dinner, lunch, brunch, breakfast, drinks, party, concert, game, flight, appointment, dentist, doctor, physio, haircut, wedding, date night, webinar, workshop, class, practice*
  5. Otherwise **Task**
- **PRS-30** Occasions get `FREQ=YEARLY` automatically (contextual default).
- **PRS-31** Work context keywords: *client, team, report, invoice, deck, slides, contract, timesheet, board, sprint, manager, office, roadmap, candidate, webinar, workshop, budget*. Meetings default to Work regardless.
- **PRS-32** Explicit prefixes *work:* / *personal:* set the context and are removed from the title.

### Title
- **PRS-33** Remove all parsed date, time, zone, recurrence, and alert phrases, plus fillers: *remind me to, don't forget to, remember to, at, on, by, for, due* (only when attached to a parsed phrase).
- **PRS-34** Trim, collapse spaces, capitalize the first letter, keep everything else as typed (names, numbers, punctuation).
- **PRS-35** Duplicate date words are tolerated ("tomorrow tomorrow buy milk").
- **PRS-36** Empty title → `title_missing` (save disabled until the user types one). Occasion with no date → `timing: null`, `date_missing` (save disabled; tomorrow makes no sense for a birthday).

---

## 4. Test cases

Notation for **When**: `Oct 11 18:00` = datetime · `Oct 12 (date)` = date-only · `Oct 6 14:00–16:00` = range · year 2026 unless shown · `[PT]` = zone differs from default.
Types: **T** Task · **M** Meeting · **E** Event · **O** Occasion. Context: **P** Personal · **W** Work.

### A. Basic dates & times
| # | Input | Title | When | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| A1 | call mom Sunday 6pm | Call mom | Oct 11 18:00 | T | P | | |
| A2 | dentist Oct 20 at 2:30pm | Dentist | Oct 20 14:30–15:30 | E | P | | |
| A3 | pay electricity bill on the 15th | Pay electricity bill | Oct 15 (date) | T | P | | PRS-8 |
| A4 | submit report Friday 5pm | Submit report | Oct 9 17:00 | T | W | | |
| A5 | buy flowers tomorrow | Buy flowers | Oct 6 (date) | T | P | | CAP-2 |
| A6 | team meeting tomorrow at 10am | Team meeting | Oct 6 10:00–10:30 | M | W | | |
| A7 | renew passport March 2027 | Renew passport | 2027-03-01 (date) | T | P | | `ambiguous_date` PRS-3 |
| A8 | pick up dry cleaning today | Pick up dry cleaning | Oct 5 (date) | T | P | | Due end of day; 09:00 alert already past → none (ALR-6) |
| A9 | doctor appointment Nov 3 9am | Doctor appointment | Nov 3 09:00–10:00 | E | P | | |
| A10 | send invoice to ACME Oct 30 | Send invoice to ACME | Oct 30 (date) | T | W | | |
| A11 | flight to Chicago Thursday 7:15am | Flight to Chicago | Oct 8 07:15–08:15 | E | P | | |
| A12 | return shoes by Nov 2 | Return shoes | Nov 2 (date) | T | P | | "by" removed |
| A13 | on December 24 wrap presents | Wrap presents | Dec 24 (date) | T | P | | Date first |
| A14 | 2026-11-15 car inspection | Car inspection | Nov 15 (date) | T | P | | ISO date |
| A15 | October 31st halloween party 8pm | Halloween party | Oct 31 20:00–21:00 | E | P | | |

### B. Relative dates & times
| # | Input | Title | When | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| B1 | take out trash tonight | Take out trash | Oct 5 20:00 | T | P | | PRS-11 |
| B2 | stretch in 30 minutes | Stretch | Oct 5 14:30 | T | P | | |
| B3 | check oven in 2 hours | Check oven | Oct 5 16:00 | T | P | | |
| B4 | follow up with John in 3 days | Follow up with John | Oct 8 (date) | T | P | | |
| B5 | cancel Netflix trial in 7 days | Cancel Netflix trial | Oct 12 (date) | T | P | | |
| B6 | call grandma next week | Call grandma | Oct 12 (date) | T | P | | PRS-6 |
| B7 | clean garage this weekend | Clean garage | Oct 10 (date) | T | P | | |
| B8 | pay credit card end of month | Pay credit card | Oct 31 (date) | T | P | | |
| B9 | finish slides end of week | Finish slides | Oct 9 (date) | T | W | | |
| B10 | water plants tomorrow morning | Water plants | Oct 6 09:00 | T | P | | morning = day time |
| B11 | call the bank this afternoon | Call the bank | Oct 5 15:00 | T | P | | |
| B12 | dentist checkup in 6 months | Dentist checkup | 2027-04-05 (date) | E | P | | |
| B13 | review contract in a week | Review contract | Oct 12 (date) | T | W | | |
| B14 | book hotel day after tomorrow | Book hotel | Oct 7 (date) | T | P | | |

### C. Weekdays
| # | Input | Title | When | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| C1 | gym Monday | Gym | Oct 5 (date) | T | P | | `ambiguous_date` — today is Monday (CAP-4) |
| C2 | gym Monday 7pm | Gym | Oct 5 19:00 | T | P | | Still ahead today |
| C3 | gym Monday 9am | Gym | Oct 12 09:00 | T | P | | Passed today → next week |
| C4 | lunch with Sara Wednesday | Lunch with Sara | Oct 7 12:00–13:00 | E | P | | PRS-14 |
| C5 | next Friday drinks with team | Drinks with team | Oct 16 19:00–20:00 | E | W | | `ambiguous_date` PRS-7 |
| C6 | this Friday submit timesheet | Submit timesheet | Oct 9 (date) | T | W | | |
| C7 | call dad on Sat | Call dad | Oct 10 (date) | T | P | | |
| C8 | thurs 3pm haircut | Haircut | Oct 8 15:00–16:00 | E | P | | |

### D. Time formats & ambiguity
| # | Input | Title | When | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| D1 | call Alex at 6 | Call Alex | Oct 5 18:00 | T | P | | `ambiguous_time` |
| D2 | gym at 7 | Gym | Oct 6 07:00 | T | P | | `ambiguous_time`; 07:00 passed → tomorrow |
| D3 | standup at 9:30 | Standup | Oct 6 09:30–10:00 | M | W | | `ambiguous_time` |
| D4 | pick up kids at 3:30 | Pick up kids | Oct 5 15:30 | T | P | | `ambiguous_time` |
| D5 | call Lee at 12 | Call Lee | Oct 6 12:00 | T | P | | `ambiguous_time`; noon passed |
| D6 | meds at 20:00 | Meds | Oct 5 20:00 | T | P | | 24h, not ambiguous |
| D7 | lunch at noon tomorrow | Lunch | Oct 6 12:00–13:00 | E | P | | |
| D8 | submit form by midnight | Submit form | Oct 6 00:00 | T | P | | PRS-11 |
| D9 | call Ana 6 pm Friday | Call Ana | Oct 9 18:00 | T | P | | |
| D10 | workout 6:00am tomorrow | Workout | Oct 6 06:00 | T | P | | Explicit am beats CAP-5 |
| D11 | yoga 5.30pm | Yoga | Oct 5 17:30 | T | P | | Dot separator |

### E. Undated & empty input
| # | Input | Title | When | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| E1 | buy milk | Buy milk | Oct 6 (date) | T | P | | CAP-1 |
| E2 | remind me to call the plumber | Call the plumber | Oct 6 (date) | T | P | | Filler removed |
| E3 | don't forget to email Priya | Email Priya | Oct 6 (date) | T | P | | |
| E4 | Tuesday | *(empty)* | Oct 6 (date) | T | P | | `title_missing` |
| E5 | *(empty string)* | *(empty)* | Oct 6 (date) | T | P | | `title_missing`; save disabled |
| E6 | asdfgh | Asdfgh | Oct 6 (date) | T | P | | |

### F. Recurrence (fixed)
| # | Input | Title | When (first) | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| F1 | take vitamins every day at 8am | Take vitamins | Oct 6 08:00 | T | P | `FREQ=DAILY` | 08:00 passed today |
| F2 | daily standup 9:30am | Standup | Oct 6 09:30–10:00 | M | W | `FREQ=DAILY` | |
| F3 | every weekday 9am check email | Check email | Oct 6 09:00 | T | P | `FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR` | |
| F4 | timesheet every Friday 3pm | Timesheet | Oct 9 15:00 | T | W | `FREQ=WEEKLY;BYDAY=FR` | |
| F5 | pay rent on the 1st every month | Pay rent | Nov 1 (date) | T | P | `FREQ=MONTHLY;BYMONTHDAY=1` | |
| F6 | pay rent monthly on the 31st | Pay rent | Oct 31 (date) | T | P | `FREQ=MONTHLY;BYMONTHDAY=31` | Clamp in short months (REC-3) |
| F7 | invoice ACME last business day of the month | Invoice ACME | Oct 30 (date) | T | W | `FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1` | |
| F8 | trash every Tuesday night | Trash | Oct 6 20:00 | T | P | `FREQ=WEEKLY;BYDAY=TU` | |
| F9 | every other Monday 1:1 with Dana 3pm | 1:1 with Dana | Oct 5 15:00–15:30 | M | W | `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO` | "1:1" is not a time |
| F10 | water plants every 3 days | Water plants | Oct 6 (date) | T | P | `FREQ=DAILY;INTERVAL=3` | PRS-22 |
| F11 | car insurance renews every year on March 3 | Car insurance renews | 2027-03-03 (date) | T | P | `FREQ=YEARLY` | |
| F12 | every 2 weeks clean fridge | Clean fridge | Oct 6 (date) | T | P | `FREQ=WEEKLY;INTERVAL=2` | |
| F13 | quarterly tax payment Jan 15 | Tax payment | 2027-01-15 (date) | T | P | `FREQ=MONTHLY;INTERVAL=3` | |
| F14 | every Mon and Thu 6pm soccer practice | Soccer practice | Oct 5 18:00–19:00 | E | P | `FREQ=WEEKLY;BYDAY=MO,TH` | |
| F15 | review goals weekly on Sunday 7pm | Review goals | Oct 11 19:00 | T | P | `FREQ=WEEKLY;BYDAY=SU` | |
| F16 | standup every weekday at 9:30am until Dec 31 | Standup | Oct 6 09:30–10:00 | M | W | `FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;UNTIL=20261231` | |
| F17 | physio every Wednesday for 6 weeks | Physio | Oct 7 (date) | E | P | `FREQ=WEEKLY;BYDAY=WE;COUNT=6` | |

### G. Repeat after completion
| # | Input | Title | When (first) | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| G1 | change AC filter every 3 months after done | Change AC filter | Oct 6 (date) | T | P | `FREQ=MONTHLY;INTERVAL=3` · after_completion | |
| G2 | haircut every 6 weeks after last one | Haircut | Oct 6 (date) | T | P | `FREQ=WEEKLY;INTERVAL=6` · after_completion | Forced to Task (PRS-21) |
| G3 | water plants 3 days after I last did it | Water plants | Oct 6 (date) | T | P | `FREQ=DAILY;INTERVAL=3` · after_completion | No "every" needed |
| G4 | descale coffee machine every 2 months since last time | Descale coffee machine | Oct 6 (date) | T | P | `FREQ=MONTHLY;INTERVAL=2` · after_completion | |
| G5 | oil change every 5000 miles | Oil change every 5000 miles | Oct 6 (date) | T | P | | PRS-23 — not parsed |

### H. Type & context detection
| # | Input | Title | When | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| H1 | meeting with client Thursday 11am | Meeting with client | Oct 8 11:00–11:30 | M | W | | |
| H2 | call with Sarah about budget tomorrow 2pm | Call with Sarah about budget | Oct 6 14:00–14:30 | M | W | | "call with" → Meeting |
| H3 | interview candidate Friday 10am | Interview candidate | Oct 9 10:00–10:30 | M | W | | |
| H4 | dinner with parents Saturday | Dinner with parents | Oct 10 19:00–20:00 | E | P | | PRS-14 |
| H5 | concert Nov 14 8pm | Concert | Nov 14 20:00–21:00 | E | P | | |
| H6 | prepare deck for board Tuesday | Prepare deck for board | Oct 6 (date) | T | W | | |
| H7 | pay water bill Friday | Pay water bill | Oct 9 (date) | T | P | | |
| H8 | sprint planning Monday 10am | Sprint planning | Oct 12 10:00–10:30 | M | W | | |
| H9 | date night Friday 7pm | Date night | Oct 9 19:00–20:00 | E | P | | |
| H10 | 1:1 with manager Wed 4pm | 1:1 with manager | Oct 7 16:00–16:30 | M | W | | "1:1" is not a time |
| H11 | kids soccer game Saturday 10am | Kids soccer game | Oct 10 10:00–11:00 | E | P | | |
| H12 | email the landlord tomorrow | Email the landlord | Oct 6 (date) | T | P | | |
| H13 | work: update roadmap Friday | Update roadmap | Oct 9 (date) | T | W | | PRS-32 |
| H14 | client lunch Thursday | Client lunch | Oct 8 12:00–13:00 | E | W | | |
| H15 | book table for dinner Friday | Book table for dinner | Oct 9 (date) | T | P | | Action verb beats Event word |

### I. Occasions
| # | Input | Title | When | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| I1 | Mom's birthday Oct 12 | Mom's birthday | Oct 12 (date) | O | P | `FREQ=YEARLY` · default −7d, −1d, 0 | |
| I2 | our anniversary June 18 | Our anniversary | 2027-06-18 (date) | O | P | `FREQ=YEARLY` | |
| I3 | Jake bday 3/14 | Jake bday | 2027-03-14 (date) | O | P | `FREQ=YEARLY` | en-US order |
| I4 | Leap baby birthday Feb 29 | Leap baby birthday | 2027-02-28 (date) | O | P | `FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=29` | REC-4: shown Feb 28 in non-leap years; rule keeps Feb 29 for leap years |
| I5 | wedding anniversary today | Wedding anniversary | Oct 5 (date) | O | P | `FREQ=YEARLY` | All stages past today → no alerts this year |
| I6 | Sam's birthday party Saturday 3pm | Sam's birthday party | Oct 10 15:00–16:00 | E | P | | "birthday party" → Event, no repeat |
| I7 | Dad's birthday | Dad's birthday | *(none)* | O | P | `FREQ=YEARLY` | `date_missing` PRS-36 |

### J. Alerts & lead time
| # | Input | Title | When | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| J1 | Mom's birthday Oct 12 remind me 2 weeks before | Mom's birthday | Oct 12 (date) | O | P | `FREQ=YEARLY` · alerts −14d, 0 | PRS-24 |
| J2 | dentist Friday 10am remind me 30 minutes before | Dentist | Oct 9 10:00–11:00 | E | P | alerts −30m | |
| J3 | report due Friday start Wednesday | Report | Oct 9 (date) | T | W | alerts −2d (Start by), 0 | PRS-26 |
| J4 | pay rent on the 1st every month nag me | Pay rent | Nov 1 (date) | T | P | `FREQ=MONTHLY;BYMONTHDAY=1` · nag 2h | PRS-27 |
| J5 | passport expires June 2027 remind me 6 months before | Passport expires | 2027-06-01 (date) | T | P | alerts −6mo | `ambiguous_date` |
| J6 | flight Friday 6am remind me the night before | Flight | Oct 9 06:00–07:00 | E | P | alerts −10h (Thu 20:00) | PRS-25 |
| J7 | dinner Friday 7pm no alert | Dinner | Oct 9 19:00–20:00 | E | P | alerts *(none)* | PRS-28 |

### K. Time zones & ranges
| # | Input | Title | When | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| K1 | call with Tokyo team 9am JST tomorrow | Call with Tokyo team | Oct 6 09:00–09:30 [Asia/Tokyo] | M | W | | Shows "8:00 PM Mon (9:00 AM Tokyo)" |
| K2 | webinar 3pm PT Thursday | Webinar | Oct 8 15:00–16:00 [America/Los_Angeles] | E | W | | |
| K3 | call London office 10am London time Friday | Call London office | Oct 9 10:00 [Europe/London] | T | W | | Starts with "call" → Task |
| K4 | standup 9:30am EST | Standup | Oct 6 09:30–10:00 | M | W | | Same as default zone → no tz |
| K5 | work on report 2-4pm tomorrow | Work on report | Oct 6 14:00–16:00 | T | W | | Due 16:00 (TIM-12) |
| K6 | focus time from 9 to 11 tomorrow | Focus time | Oct 6 09:00–11:00 | T | P | | `ambiguous_time` |
| K7 | workshop Oct 20 10am-1pm | Workshop | Oct 20 10:00–13:00 | E | W | | |
| K8 | party 9pm-1am Saturday | Party | Oct 10 21:00 – Oct 11 01:00 | E | P | | End rolls to next day |

### L. Locale
| # | Input | Title | When | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| L1 | dentist 10/12 | Dentist | Oct 12 (date) | E | P | | en-US |
| L2 | `[en-GB]` dentist 10/12 | Dentist | Dec 10 (date) | E | P | | en-GB day/month |
| L3 | `[en-GB]` pay rent 5 Nov | Pay rent | Nov 5 (date) | T | P | | |
| L4 | `[en-GB]` meeting 14:00 Friday | Meeting | Oct 9 14:00–14:30 | M | W | | |
| L5 | `[en-GB]` dentist 2026-12-10 | Dentist | Dec 10 (date) | E | P | | ISO is locale-independent |

### M. False positives (numbers & words that aren't dates)
| # | Input | Title | When | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| M1 | buy 2 tickets for Friday | Buy 2 tickets | Oct 9 (date) | T | P | | |
| M2 | read chapter 5 tomorrow | Read chapter 5 | Oct 6 (date) | T | P | | |
| M3 | order 10 pizzas for the party Saturday | Order 10 pizzas for the party | Oct 10 (date) | T | P | | Action verb beats "party" |
| M4 | room 404 meeting at 3pm | Room 404 meeting | Oct 5 15:00–15:30 | M | W | | |
| M5 | watch Ocean's 11 Friday 9pm | Watch Ocean's 11 | Oct 9 21:00 | T | P | | |
| M6 | pay May rent | Pay May rent | Oct 6 (date) | T | P | | PRS-4 |
| M7 | march band practice Thursday | March band practice | Oct 8 (date) | E | P | | PRS-4 |
| M8 | buy a 3-pack of socks | Buy a 3-pack of socks | Oct 6 (date) | T | P | | |
| M9 | 5 minute meditation tonight | 5 minute meditation | Oct 5 20:00 | T | P | | PRS-12 |

### N. Edge cases
| # | Input | Title | When | Type | Ctx | Repeat / alerts | Flags · notes |
|---|---|---|---|---|---|---|---|
| N1 | Mar 3 car registration | Car registration | 2027-03-03 (date) | T | P | | `past_date_rolled` |
| N2 | pay invoice Oct 1 | Pay invoice | 2027-10-01 (date) | T | W | | `past_date_rolled` (4 days ago) |
| N3 | call mom today 1pm | Call mom | Oct 5 13:00 | T | P | | `time_in_past` PRS-15 |
| N4 | Nov 1 1:30am pay bill | Pay bill | Nov 1 01:30 (EDT, first) | T | P | | DST overlap (TIM-14) |
| N5 | Mar 14 2027 2:30am backup server | Backup server | 2027-03-14 03:30 | T | P | | DST gap (TIM-13) |
| N6 | tomorrow tomorrow buy milk | Buy milk | Oct 6 (date) | T | P | | PRS-35 |

### S. Stretch (not counted toward pass rate)
| # | Input | Expected |
|---|---|---|
| S1 | half past 3 tomorrow | Oct 6 15:30 |
| S2 | Sunday school prep Saturday | Title "Sunday school prep", Oct 10 (date) |
| S3 | remind me tomorrow at 5 to remind Tom about the meeting | Title "Remind Tom about the meeting", Oct 6 17:00, Task |
| S4 | book club every second Tuesday of the month 7pm | `FREQ=MONTHLY;BYDAY=2TU`, first Oct 13 19:00 |
| S5 | the first Monday of November | Nov 2 (date) |
| S6 | Christmas shopping by Christmas | Dec 25 (date) |

---

## 5. Not supported in v1

These should produce a sensible fallback (text kept in the title, default date), never an error:
- Languages other than English
- Holidays by name ("Christmas", "Thanksgiving") — stretch S6
- Location or context triggers ("when I get home", "after work")
- Reminders relative to other reminders ("2 days before the trip") — v1.2 prep reminders
- Non-time units ("every 5000 miles")

## 6. How to use this file

- The test harness lives in `packages/core/test/parser/` (e.g. `parser_cases_test.dart`) and mirrors these tables exactly — **one test per row**, named by its ID (`A1`, `F9`…).
- When the parser gets an input wrong in real use, **add it here first** as a new row, then fix the parser.
- Changing an expected result here is a spec change: note it in the decision log of `behavior-spec.md`.
