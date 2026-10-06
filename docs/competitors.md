# Competitive Scan — v1.0

Where Reminder App sits against the task, reminder and calendar apps people already use, and what that means for v1.0 scope and positioning.

**Checked:** 2026-10-05. Prices and features change often. Prices are US list prices found on official pages or recent third-party pricing write-ups. Items marked *(unverified)* could not be confirmed from an official source.

---

## 1. Summary

Legend: ✅ yes · ⚠️ partial / paid only / limited · ❌ no · ? unverified

| App | Android | NL capture | Repeat after completion | Nag until done | Lead-time / occasion prep | Calendar views | Device calendar import | Free tier |
|---|---|---|---|---|---|---|---|---|
| **Todoist** | ✅ | ✅ best-in-class | ✅ `every!` | ❌ | ⚠️ custom reminders are Pro | ⚠️ calendar layout is Pro | ✅ Google/Outlook (all plans) | ⚠️ 5 projects |
| **TickTick** | ✅ | ✅ | ✅ | ✅ Constant Reminder | ⚠️ Countdown/Anniversaries; multiple reminders | ✅ (full calendar is Premium) | ⚠️ subscriptions Premium | ✅ generous |
| **Google Tasks / Calendar** | ✅ | ❌ | ❌ | ❌ | ⚠️ Calendar birthdays from Contacts, no prep | ✅ Calendar app (Schedule/Day/3-Day/Week/Month) | ✅ native | ✅ fully free |
| **Microsoft To Do** | ✅ | ⚠️ dates/recurrence only | ⚠️ removed / unclear | ❌ | ❌ | ❌ (Outlook only) | ❌ | ✅ fully free |
| **Any.do** | ✅ | ✅ (AI parsing Premium) | ? | ❌ ? | ⚠️ WhatsApp reminders (Premium) | ✅ | ✅ | ⚠️ |
| **Due** (iOS) | ❌ | ✅ | ✅ ? | ✅ Auto Snooze | ❌ | ❌ | ❌ | ❌ paid app |
| **Things 3** | ❌ | ✅ | ✅ | ❌ | ⚠️ deadlines only | ❌ (shows calendar events in Today/Upcoming) | ✅ read-only | ❌ paid app |
| **Apple Reminders** | ❌ | ✅ (iOS 26) | ❌ ? | ✅ "Urgent" alarm (iOS 26.2) | ⚠️ "Early reminder" | ❌ (Calendar app separate) | n/a (system) | ✅ |
| **BZ Reminder** (Android) | ✅ | ⚠️ ? | ? | ⚠️ ? | ⚠️ birthdays from Contacts | ⚠️ simple month calendar | ? | ✅ (IAP $2.49–4.99) |
| **Reminder App (us)** | ✅ | ✅ + parse-preview chips | ✅ | ✅ opt-in | ✅ 1 wk / 1 day / day-of + "I'm prepared" | ✅ Schedule/Day/Month | ✅ as silent overlays | ✅ free, no account |

**Headline:** NL capture, repeat-after-completion and nag-until-done are **table stakes** among the strong apps (Todoist, TickTick, Due, and now Apple Reminders). The rare things are **occasion prep workflows**, **synced events that stay silent by default**, and **no account needed on Android**.

---

## 2. App by app

### Todoist
- **Platforms / price:** Android, iOS, web, desktop. Beginner (free), Pro **$7/mo or $60/yr** (raised Dec 2025, about 40% up on monthly), Business tier.
- **Does well:** Smart Quick Add is the benchmark for NL. It highlights parsed tokens inline as you type (date, `#project`, `@label`, `p1`). `every` vs `every!` gives fixed vs after-completion recurrence in one syntax. Ramble (voice to tasks, AI). Google/Outlook Calendar events appear in Today/Upcoming on every plan.
- **Gaps vs our bets:** No nag or persistent alerts. Custom reminders and calendar layout are Pro only. No occasion or birthday concept. Requires an account.
- **Complaints:** the Dec 2025 price rise; reminders that didn't fire; useful features sitting behind the paywall; the free plan capped at 5 projects.
- **Borrow:** inline highlighting of parsed tokens; the `every!` mental model (which we expose as a toggle, not syntax).

### TickTick — closest overall competitor
- **Platforms / price:** Android, iOS, web, desktop, watch. Free tier; Premium **$35.99/yr or $3.99/mo**.
- **Does well:** Covers most of our list already. NL date parsing, recurrence "by completion date" or fixed, **Constant Reminder** (repeats until handled; can be turned on separately for tasks, habits and anniversaries), multiple reminders per task, calendar views (Day/Week/Month, Premium for full use), habits, Pomodoro. In 2025 it added **Countdown** with tabs for Anniversaries, Birthdays and Holidays.
- **Gaps vs our bets:** Occasions are countdowns plus reminders. No prep sequence, no "I'm prepared" state. Dense, feature-heavy UI. Requires an account.
- **Complaints *(from reviews, not fully verified)*:** clutter and feature overload; key calendar features paywalled.
- **Borrow:** a per-item "constant" toggle (we have this); Countdown-style "N days to go" display on Occasion cards.

### Google Tasks + Google Calendar
- **Platforms / price:** Android (preinstalled), iOS, web. Free.
- **Does well:** Default on Android. Tasks show in Calendar, and recurrence (daily, weekdays, custom, end conditions) now exists in both apps. Google Reminders has been folded into Tasks. Calendar has the views we're copying (Schedule/Day/3-Day/Week/Month) and shows **birthdays from Contacts** automatically.
- **Gaps vs our bets:** No NL parsing in Tasks. No after-completion recurrence, no nagging, no prep nudges. Tasks feel thin.
- **Borrow:** the Schedule view layout; contact-birthday import.

### Microsoft To Do
- **Platforms / price:** Android, iOS, web, Windows. Free with a Microsoft account.
- **Does well:** clean "My Day" daily-planning ritual; NL recognition of dates, reminders and recurrence.
- **Gaps:** after-completion recurrence existed but appears removed or unreliable *(per user forums)*. No nag. No calendar view. Microsoft is putting its task investment into Planner and Copilot, and To Do has no public roadmap.
- **Complaints:** stagnation; reminders on recurring tasks deactivating after completion *(forum reports)*.
- **Borrow:** the "My Day" pick-today ritual as a way into the daily digest. **Opportunity:** a stagnant install base we could win over.

### Any.do
- **Platforms / price:** Android, iOS, web, desktop. Free tier; Premium about **$4.99/mo billed annually (~$7.99 monthly)**; Family $9.99/mo.
- **Does well:** combined tasks + calendar view, "Moment" daily planning, **WhatsApp reminders** (Premium), location reminders, NL/AI parsing including recurrence.
- **Gaps:** advanced recurrence and AI parsing are Premium. Persistent reminders and after-completion recurrence not confirmed *(unverified)*. No occasion concept.
- **Complaints:** aggressive upsell and payment prompts; limited depth.
- **Borrow:** the daily-planning prompt; meeting users where they already look (a reminder outside the app, as with WhatsApp; for us that could be email in v1.1).

### Due (iOS / macOS)
- **Platforms / price:** iOS, iPadOS, watchOS, macOS. **No Android.** One-time purchase (~$9.99 US) plus an optional Upgrade Pass.
- **Does well:** the purest "can't forget" app. **Auto Snooze** re-notifies overdue items every 1/5/10/15/30/60 min (default 5 repeats, up to 10, or indefinitely). Natural date parsing ("in 45 minutes"). Complex recurrence. Quick-time buttons for fast capture.
- **Gaps:** no calendar, no occasions, no Android.
- **Borrow:** **the nag spec itself**: user-chosen interval, a repeat count cap, and reschedule straight from the notification. Quick-time preset buttons next to the NL field.

### Things 3
- **Platforms / price:** Apple only (no Android, web or Windows). One-time: $9.99 iPhone, $19.99 iPad, $49.99 Mac.
- **Does well:** design benchmark (calm, typographic, satisfying completion). Smooth NL ("Call Sarah tomorrow at 10am"). Today/Upcoming with calendar events shown inline (read-only). Repeat after completion. Deadlines separate from start dates.
- **Gaps:** no nag. Weak reminders overall. No calendar grid views. No Android.
- **Complaints:** no cross-platform; slow feature pace; reminders not first-class.
- **Borrow:** the Today/Upcoming list with calendar events interleaved; separating "when I'll do it" from "deadline" (which maps to our Occasion date vs prep nudges).

### Apple Reminders
- **Platforms / price:** iOS/iPadOS/macOS, iCloud web. Free. No Android.
- **Does well:** iOS 26 added a "New Reminder" control (Lock Screen / Control Center / Action button), NL dates in the quick panel, and auto-categorized lists. **iOS 26.2 added "Urgent"**: a full-screen alarm that rings through Silent/Focus until snoozed, stopped, or (optionally) completed. Early reminders.
- **Gaps:** no Android; no occasion prep; after-completion recurrence not confirmed *(unverified)*.
- **Borrow:** **an alarm option with a "Complete" button on the alarm screen**; capture from system surfaces (our equivalents are the QS tile and widget).

### BZ Reminder (added: strong simple Android reminder app)
- **Platforms / price:** Android (also iOS). Free with in-app purchases ($2.49–$4.99).
- **Does well:** lightweight and reliable. **Imports birthdays from Contacts**, color tags, widgets, simple calendar, Wear OS voice capture, hourly reminders.
- **Gaps:** birthdays are plain yearly reminders; NL depth, nag and after-completion recurrence *(unverified)*.
- **Borrow:** contact-birthday import as one-tap Occasion seeding; a watch quick-capture path later.

---

## 3. Where we're differentiated

| Our bet | Verdict | Why |
|---|---|---|
| (1) NL quick capture + parse-preview chips, widget, QS tile, share sheet | **Table stakes** | Todoist, TickTick, Things, Due, Any.do and now Apple all parse NL; Todoist already highlights tokens. Winning here means *faster and more accurate*, not new. The QS tile + share sheet + widget combination is uncommon on Android but easy to copy. |
| (2) Occasions with escalating prep (1 wk / 1 day / day-of) + "I'm prepared" | **Genuinely rare** | Competitors treat birthdays as yearly reminders or countdowns (TickTick, Google Calendar, BZ). None model *prep* as a state that stops the nudges. This is our clearest wedge. |
| (3) Nag until done | **Common** | TickTick Constant Reminder, Due Auto Snooze, Apple Urgent, Memorigi "Nag Me". It is expected for a "can't forget" app; not a reason to switch. |
| (4) Repeat after completion | **Table stakes** | Todoist, TickTick, Things, Due. Microsoft To Do and Google Tasks lack it, so it helps win switchers from them. |
| (5) Device calendar import, events silent unless asked | **Somewhat rare** | Others either show events read-only (Things, Todoist) or are the calendar (Google). An explicit "overlay alerts on synced events" model is uncommon. |
| (6) Google Calendar-style views | **Table stakes** | Google Calendar sets the bar, free. TickTick/Todoist/Any.do have views (often paywalled). Free views help, but they're parity. |
| (7) Daily digest of overdue/missed | **Partial parity** | "My Day" (To Do), "Moment" (Any.do), Today views exist. A *missed-items* catch-up summary is less common. |
| (8) Apple-style design + mascot + completion delight | **Rare on Android** | Things-level polish isn't available on Android. A mascot adds personality, but it's a risk if it clashes with a calm Things feel (see Risks). |
| Local-first, no account, free | **Rare on Android** | TickTick, Todoist, Any.do, To Do and Google all require an account. Only small apps (BZ) don't. |

**Honest read:** the defensible position is **"the reminder app for things with consequences: occasions and bills"** together with **"no account, all free, works offline"**, not "smart capture" or "nagging".

---

## 4. Patterns to borrow

1. **Inline token highlighting** (Todoist): colour the parsed span in the text field *and* show chips; tapping a chip removes or edits it.
2. **Quick-time preset buttons** beside the NL field (Due): `+1h`, `Tonight`, `Tomorrow 9am`. These are a fallback when parsing fails.
3. **Nag config** (Due): interval (1/5/10/15/30/60 min), max repeats or "until done", reschedule and complete actions on the notification.
4. **Alarm-grade alert with Complete on the alarm screen** (Apple Urgent): an opt-in for critical bills, using Android full-screen intent.
5. **Countdown chip on occasions** (TickTick): "Mum's birthday · 6 days" on the card, plus "turns 60" when the year is known.
6. **Contact birthday import** (Google Calendar, BZ): one-tap seeding of Occasions during onboarding. This fills the app on day 1.
7. **"Pick today" ritual** (To Do My Day / Any.do Moment): fold it into the daily digest ("3 missed · 5 today · plan your day").
8. **Calendar events interleaved in list views** (Things/Todoist): Schedule view shows events greyed and tasks in full weight.
9. **Fixed vs after-completion as one plain toggle** (TickTick): "Repeat from: due date / when I complete it".

---

## 5. Risks

- **Strong free incumbents on Android.** Google Tasks/Calendar are preinstalled and free; TickTick's free tier already has NL, nag and after-completion recurrence. "Free" alone won't win, so the hook has to be occasions and bills.
- **Feature-parity expectations.** Reviewers will compare us with TickTick on day one: habits, location reminders, sharing, sync, web. Missing **cloud sync/backup** is the most likely 1-star complaint for a local-only app ("lost everything when I changed phones").
- **Reminder reliability on Android.** This is the top complaint across the category (Todoist reviews, To Do forums). OEM battery killers (Samsung, Xiaomi), the exact-alarm permission and full-screen-intent restrictions on Android 14+ can silently break nags. One missed bill reminder costs us the user.
- **Apple is closing the gap** (Urgent alarms, NL, Control Center capture). This matters when we go to iOS; our iOS pitch has to rest on occasions and cross-platform use.
- **Tone clash.** A Duolingo-style mascot alongside a "Things 3 calm" look can read as inconsistent, and some users find gamified nagging grating. Keep the mascot optional or subtle.
- **Discoverability.** "Reminder App" competes in a crowded store category (see D2).

---

## 6. Recommendations for v1.0

1. **Lead positioning with Occasions + bills, not NL/nagging.** Suggested tagline direction: "Never miss a birthday. Never pay a late fee." Present NL capture and nag as supporting features.
2. **Add contact-birthday import to v1.0** (Android Contacts permission, opt-in during onboarding). It's cheap, it fills the app with Occasions on day 1, and it shows off the prep feature immediately.
3. **Make reliability a v1.0 feature:** onboarding check for exact-alarm permission and battery optimisation (with OEM-specific guidance), plus a "test reminder" button. Track missed or late notifications as a quality metric (fits D4).
4. **Ship the nag with Due-style controls and an opt-in alarm mode** (full-screen, with a Complete button) for critical items.
5. **Add bill/renewal templates to quick capture** ("Netflix renews 12th monthly", "trial ends in 7 days" → set the nudge 2 days before). This makes the "late fee" hero case concrete. A minimal amount/payee field is optional.
6. **Plan backup before sync:** at minimum, a v1.0 local export/import (file) so "changed phones, lost everything" can't happen before cloud ships.
7. **Treat the mascot as a light accent** (empty states, completion moments), not a constant presence, to keep the Things-like calm.

---

## Sources (checked 2026-10-05)

- Todoist: [Pricing](https://www.todoist.com/pricing), [Recurring dates help](https://todoist.com/help/articles/introduction-to-recurring-due-dates-YUYVJJAV), [Calendar integration help](https://www.todoist.com/help/todoist/integrations/use-the-calendar-integration-rCqwLCt3G), [Routine: Todoist pricing 2026](https://routine.co/blog/posts/todoist-pricing), [Morgen: Todoist pricing & limits](https://morgen.so/blog-posts/todoist-pricing)
- TickTick: [20 lesser-known features (official blog)](https://blog.ticktick.com/2020/12/08/20-lesser-known-ticktick-features/), [What's New (official help)](https://help.ticktick.com/articles/7082552170989486080), [AlternativeTo: Countdown launch](https://www.alternativeto.net/news/2025/5/ticktick-adds-countdown-feature-to-track-important-events-and-deadlines/), [Lifestack: TickTick pricing](https://lifestack.ai/blog/ticktick-pricing)
- Google: [Chrome Unboxed: Tasks recurrence in Calendar](https://chromeunboxed.com/google-tasks-calendar-recurring-update), [PhoneArena: recurring tasks in Tasks app](https://www.phonearena.com/news/google-tasks-app-repeats-certain-chores-on-a-recurring-basis_id140045)
- Microsoft To Do: [Smart due date recognition (Microsoft Support)](https://support.microsoft.com/en-us/ToDo/smart-due-date-reminder-recognition-in-microsoft-to-do), [Tech Community: after-completion recurrence request](https://techcommunity.microsoft.com/discussions/to-do/new-recurring-task-type-x-days-after-finishing-the-previous-instance/3979398), [WindowsForum: To Do not retiring, Planner prioritised](https://windowsforum.com/windows-news.4/microsoft-to-do-is-not-retiring-but-planner-and-copilot-take-priority.441339/)
- Any.do: [Capterra pricing](https://www.capterra.com/p/173614/Any-do/pricing/), [Capterra reviews](https://www.capterra.com/p/173614/Any-do/reviews/), [App Store listing](https://apps.apple.com/us/app/any-do-to-do-list-task-manager/id497328576)
- Due: [dueapp.com](https://www.dueapp.com/), [App Store listing](https://apps.apple.com/app/id390017969)
- Things 3: [TechRepublic review](https://www.techrepublic.com/article/things-3-review/), [TechRadar: iOS 26 vs Things](https://www.techradar.com/computing/websites-apps/after-years-of-using-things-3-ios-26-could-move-me-to-reminders)
- Apple Reminders: [9to5Mac: everything new in iOS 26 Reminders](https://9to5mac.com/2025/10/13/heres-everything-new-in-reminders-with-ios-26/), [9to5Mac: iOS 26.2 Urgent reminders](https://9to5mac.com/2025/11/05/ios-26-2s-new-reminders-feature-is-exactly-what-ive-wanted-for-years/), [MacMost: Urgent reminders with alarms](https://macmost.com/urgent-reminders-with-alarms-on-iphone.html)
- BZ Reminder: [Android Authority: best reminder apps](https://www.androidauthority.com/bestreminder-apps-for-android-654628), [App Store listing](https://apps.apple.com/us/app/-/id682815939)
- Category: [Toolfinder: best reminder apps 2026](https://www.toolfinder.com/best/reminder-apps)

**Not verified:** Any.do persistent reminders and after-completion recurrence; Apple Reminders after-completion recurrence; BZ Reminder NL/nag depth; Due after-completion option; whether TickTick Constant Reminder is free or Premium; Reddit sentiment (search returned review sites, not Reddit threads, so complaints are summarized from review aggregators and forums).
