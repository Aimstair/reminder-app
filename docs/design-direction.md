# Design Direction — v1.0

The look, feel, and motion of the app. Screens are listed in [`screens.md`](screens.md); this file defines how they should *feel*.

## Decisions

| # | Decision | Value | Decided |
|---|---|---|---|
| DS1 | Aesthetic | **Apple-style** (inspired by Apple's Human Interface Guidelines), on Android | 2026-10-05 |
| DS2 | Themes | **Light and dark**, following the system setting by default | 2026-10-05 |
| DS3 | Onboarding | **Interactive, animated** | 2026-10-05 |
| DS4 | Task completion | **Fires an animation** | 2026-10-05 |
| DS5 | Visual blend | **Notion Calendar's structure for calendar views + Things 3's style for everything** | 2026-10-05 |
| DS6 | Illustration style | **Duolingo-style**: bold, flat, bright, with an original mascot | 2026-10-05 |
| DS7 | Completion sound | **A setting, default on** | 2026-10-05 |
| DS8 | Mascot | **A friendly bell** | 2026-10-05 |
| DS9 | Art production | **AI-generated mascot & illustrations, animated in Rive** | 2026-10-05 |
| DS10 | Overall style confirmed | **Calm Things 3 style.** A heavily gamified, Duolingo-like direction (XP, streaks, levels, badges, mascot on every screen) was mocked up and **rejected** — too playful for the long-term enterprise goal (D5). The bell stays limited to key moments. | 2026-10-06 |
| DS11 | Visual reference | **Approved mockups:** [Reminder App Screens canvas](https://claude.ai/artifact/ArygfCSr3DBPg4pTmz8kMG), page "Calm · Things 3 style (chosen)" — rendered copies in [`docs/design/mockups/`](design/mockups/README.md) (the canvas lives in another account; use the images) | 2026-10-06 |
| DS12 | Mockup over earlier text | Where the mockups show more than the written patterns, **build to the mockups**: Month view = type dots + one short label + selected-day list (`VW-8`, `VW-10` updated); **All clear is a full screen** (stats, Today in review, Coming up, Plan tomorrow, share), not a pop-up | 2026-10-08 |
| DS14 | More life, closer to iOS | After device review ("too bland", "make it feel made by Apple"): the **iOS type scale** (sizes, weights, line heights) with SF-like size-dependent tracking on Inter; **iOS page transitions** (slide + parallax, edge swipe back); **bouncing scroll**, no Material ripples (cells turn grey while pressed); **press feedback** (shrink + dim) on cards and buttons; **selection highlights slide** to the new choice (filter chips, segmented controls, day strips, month selection); views cross-fade; lists and cards **ease in** staggered; illustrations **float** gently. Layout: **fixed heights** for rows, cards, pills and chips, single-line text that **truncates**, even 12/16 spacing, separators aligned with the text. All of it off under Reduce Motion. | 2026-10-08 |
| DS13 | No streak framing | The occasion detail's third stat card is **factual history** ("Done 3 years" — years completed, any order), not "years in a row" (DS10) | 2026-10-08 |

### Patterns established by the approved mockups (DS11)
| Pattern | Where | Notes |
|---|---|---|
| **Colored banner header** with illustration + overlapping stat cards | Occasion detail, All clear | Banner tinted in the item's type color (pink occasion, green success); stat cards overlap the banner's bottom edge |
| **Home cards** above the list | Schedule (home) | "Up next" countdown card (meeting tint) + occasion spotlight (gift illustration, prep progress, "I'm prepared"); greeting + daily progress ring; week strip with type-colored dots; filter chips |
| **Icon tiles** | Rows, agenda, cards | Rounded-square tile tinted in type color with a line icon (bill, bag, phone, people…) |
| **iOS form for capture** | Quick capture | Cancel / title / Save bar · input card with voice + template tag · grouped Details rows (Date, Time, Repeat, Alerts, each with colored icon + chevron) · Nag switch · Type and Personal/Work segmented controls · one-line "first alert" summary |
| **Notion-style grids** | Day, Week, Month | Hairline grid, tinted blocks with 3 px type-color bar, faded + struck-through when done, red now line, today column tinted |
| **No game mechanics** | Everywhere | No XP, streaks, levels or badges; stats are factual (completed, on time, missed) |

### The blend in one sentence
**Calm Things 3 interface, clean Notion Calendar grids, and a playful Duolingo-style mascot that appears only at key moments.**

| Layer | Source | Where |
|---|---|---|
| **Structure of calendar views** | Notion Calendar | Day, Month, 3 Day, Week, Year (S-13–S-17) |
| **Look & feel of the whole app** | Things 3 | Schedule, capture, detail, settings, sheets — and the finish on calendar views |
| **Personality** | Duolingo illustrations | Onboarding, empty states, celebrations, permission explainers |

The interface stays quiet and neutral; **the illustrations carry the color and personality**. Never mix them on the same surface as dense data (no mascot inside the calendar grid or the list).

---

## 1. Inspiration board

Study these apps for the specific thing listed. Screenshots of most can be browsed on **Mobbin** (mobbin.com), a library of real app screens.

### Overall aesthetic (Apple-style calm)
| App | Look at |
|---|---|
| **Things 3** | The benchmark: whitespace, quiet typography, one accent color, satisfying checkbox, "Magic Plus" button, gentle motion |
| **Apple Reminders** | Grouped rounded lists, smart-list cards, native iOS spacing and colors |
| **Craft** | Refined materials, soft shadows, polished dark mode |
| **Apple Calendar** | Clean Day/Month views, restrained color use |

### Quick capture & natural language
| App | Look at |
|---|---|
| **Fantastical** | The closest match to our capture: type a sentence, see a live preview of what was understood |
| **Todoist** | Quick Add that highlights recognized dates in the text as you type |
| **Things 3** | "When" picker: Today / This Evening / Someday shortcuts |

### Calendar views
| App | Look at |
|---|---|
| **Fantastical** | Day ticker + list hybrid, compact Month view |
| **Notion Calendar** | Minimal calendar grid, excellent dark theme |
| **Structured** | Colorful vertical timeline for the day, playful blocks — good reference for Day view |
| **Amie** | Calendar + to-dos together, delightful micro-animations |

### Onboarding (interactive)
| App | Look at |
|---|---|
| **Duolingo** | "Try it before you commit": you do the core action during onboarding |
| **Headspace** | Calm, character-driven animations; one idea per screen |
| **Fantastical** | Short feature tour with live, animated demos |

### Completion & celebration
| App | Look at |
|---|---|
| **Things 3** | Checkbox fill + item gently leaving the list |
| **Apple Fitness** | Ring-closing celebration — a model for "All clear for today" |
| **Streaks** | Bold, playful completion feedback |
| **Clear** (classic to-do app) | Gesture-driven completion with sound and motion |

### Dark theme
| App | Look at |
|---|---|
| **Linear** | Deep, layered dark surfaces with clear contrast |
| **Things 3 / Notion Calendar** | Dark modes that keep color meaning without glare |

**Rule:** take *inspiration*, not copies — no Apple icons, trademarks, or exact screen clones; no characters resembling Duolingo's owl.

### 1a. What to take from each (DS5, DS6)

**From Notion Calendar — calendar structure**
- Monochrome, minimal chrome: the grid is almost invisible (hairline lines), so the reminders stand out
- Events as **soft tinted blocks** with a thin colored accent bar on the left, title in primary text
- Strong date typography in headers (big day number, small weekday)
- Compact all-day section above the time grid
- Thin red current-time line with a dot
- Month cells: small, quiet day numbers; today marked with a filled circle

**From Things 3 — overall style and finish**
- Generous whitespace and calm hierarchy; content over chrome
- **Round checkbox** in the type color — the heart of the completion animation (§6)
- Floating **[+]** button that feels tactile (Things' "Magic Plus": can be dragged to a spot in the list to insert there — *v1.2 idea*)
- Soft cards and sheets, subtle depth, quiet section headers
- Gentle, physical motion

**From Duolingo — illustration style**
- See §4b: flat, bold, rounded shapes, bright colors, expressive mascot

### Calendar block style (tokens)
| Token | Light | Dark |
|---|---|---|
| `block.fill` | type color @ 12% | type color @ 24% |
| `block.accentBar` | type color, 3 dp wide | type color, 3 dp wide |
| `block.text` | `text.primary` | `text.primary` |
| `block.done` | fill @ 6%, strike-through, `text.secondary` | fill @ 12%, strike-through |
| `grid.line` | `separator` @ 50% (hairline) | `separator` @ 50% |
| `grid.nowLine` | `danger` 1.5 dp + 6 dp dot | `danger` |
| `month.today` | filled `accent` circle, white number | same |

---

## 2. Apple-style on Android

The app **looks** Apple-inspired but **behaves** like a good Android app. Users on Android expect certain system behaviors; breaking them feels broken, not premium.

**Adopt from Apple style**
- Large titles that shrink on scroll; grouped, inset rounded lists
- Generous whitespace, few lines and borders, one accent color
- Soft, spring-based motion; translucent blurred bars where supported (Android 12+, solid fallback below)
- Bottom sheets with rounded tops and a grabber

**Keep Android behavior**
- System back gesture and predictive back animation
- Android notification layout (the system controls it)
- Android share sheet, widget picker, Quick Settings tile
- Font scaling and TalkBack support

**Font:** Apple's SF Pro is licensed for Apple platforms only. Use **Inter** (free, open source, very close to SF Pro's feel), set to the iOS type scale with Inter's size-dependent tracking (`tracking()` in `lib/ui/theme.dart`), which brings it close to SF Pro's optical sizes (DS14).

**Icons:** **Phosphor** (decided 2026-10-08 over Lucide: SF Symbols-like, and has filled versions for selected/solid states). Regular weight for line icons, Fill only for solid shapes (status ticks, dots). All icons go through `lib/ui/icons.dart` (`AppIcons`). Don't use Apple's SF Symbols.

---

## 3. Design tokens (starting values)

Values follow Apple's system palette closely so the app feels familiar to Apple-style eyes. Final values are tuned during visual design.

### Color
| Token | Light | Dark |
|---|---|---|
| `bg.grouped` (screen background) | `#F2F2F7` | `#000000` |
| `surface` (rows, cards) | `#FFFFFF` | `#1C1C1E` |
| `surface.elevated` (sheets) | `#FFFFFF` | `#2C2C2E` |
| `text.primary` | `#000000` | `#FFFFFF` |
| `text.secondary` | `#3C3C43` @ 60% | `#EBEBF5` @ 60% |
| `separator` | `#3C3C43` @ 29% | `#545458` @ 60% |
| `accent` *(🧑 your choice)* | `#007AFF` | `#0A84FF` |
| `danger` / overdue | `#FF3B30` | `#FF453A` |
| `success` / done | `#34C759` | `#30D158` |
| `warning` (flagged chips) | `#FF9500` | `#FF9F0A` |

**Type colors** (used in rows, grid blocks, filters):
| Type | Light | Dark |
|---|---|---|
| Task | `#007AFF` blue | `#0A84FF` |
| Meeting | `#5856D6` indigo | `#5E5CE6` |
| Event | `#FF9500` orange | `#FF9F0A` |
| Occasion | `#FF2D55` pink | `#FF375F` |

All text/background pairs must meet WCAG AA contrast (4.5:1 body, 3:1 large text); type colors are never the only signal — each type also has an icon.

### Typography (Inter, sizes in sp — scale with system font size)
iOS text styles at the default Dynamic Type size (DS14). Line height in brackets; tracking from Inter's dynamic-metrics formula (tighter as text gets bigger).
| Style | Size / weight | Use |
|---|---|---|
| Large title | 34 (41) / Bold | Screen titles (Good morning, October, Just type it.) |
| Title 1 | 28 (34) / Bold | Detail title, drawer title |
| Title 2 | 22 (28) / Bold | Sheet and panel headers |
| Title 3 | 20 (25) / Semibold–Bold | Schedule group headers |
| Headline | 17 (22) / Semibold | Buttons, emphasized row titles |
| Body | 17 (22) / Regular | Row titles, input text, form values |
| Subheadline | 15 (20) / Regular | Times, metadata, chips (semibold) |
| Footnote | 13 (18) / Regular | Hints, group captions (uppercase) |
| Caption | 12 (16) / Medium | Grid labels, badges |

### Shape & spacing
- **Spacing:** 4-pt grid — 4, 8, 12, 16, 20, 24, 32. Screen side margin **16**; inset list margin **16**.
- **Corner radius:** chips **10** · rows/inset groups **12** · cards **16** · sheets **24** (top). Use smooth ("squircle") corners where the rendering library supports it.
- **Elevation:** almost flat; separation by background contrast, not shadows. Sheets get one soft shadow.
- **Touch targets:** minimum **48 × 48 dp** (Android guideline; slightly larger than Apple's 44).

---

## 4. Motion

### Principles
1. **Springs, not linear easing** — everything settles naturally (Flutter physics springs: shared `Springs.snappy` / `Springs.soft` presets and a `SpringCurve`, proven in the bake-off).
2. **Fast where it's frequent** — capture, swipes, and repeated completions must never wait on animation.
3. **Delight where it's rare** — big moments (onboarding, "All clear") get rich animation.
4. **Motion explains** — things move to where they went (a saved reminder flies into its group).
5. **Respect Reduce Motion** — when the system setting is on, replace movement with simple fades and skip celebrations.

### Timing
| Token | Duration | Use |
|---|---|---|
| `motion.micro` | 120–180 ms | Chip pop-in, checkbox, toggles |
| `motion.standard` | 250–300 ms | Sheets, row move/collapse, view switch |
| `motion.emphasized` | 400–500 ms | Saved item flying into the list, view transitions |
| `motion.celebration` | ≤ 1.5 s | Milestones only; always skippable by tapping |

### Tools
- **Flutter animation APIs** — `AnimationController` + `SpringSimulation`, implicit animations, `SliverAnimatedList`, `CustomPainter` (checkbox, confetti, time grid); gestures via `GestureDetector` / drag callbacks
- **Rive** — illustrations and interactive animations (onboarding, empty states, celebrations). Rive's state machines let animations react to touch and sliders — needed for interactive onboarding.
- **Haptics** — light tick on chip lock and toggles; confirm haptic on completion (Android 11+, gracefully skipped on older devices).

### Motion plan — where animation lives
| Moment | Treatment | Tool |
|---|---|---|
| Onboarding | **Rich & interactive** (see §5) | Rive + Flutter animations |
| Task completion | **Signature animation** (see §6) | Flutter animations + `CustomPainter` (+ Rive for milestones) |
| Capture sheet open / chips appearing | Quick spring; chips pop in one by one as parsed | Flutter animations |
| Save → item flies into its group | Emphasized motion | `SliverAnimatedList` insert + slide |
| Swipe actions | Follows the finger, springs back | Drag gestures + `SpringSimulation` |
| View switch (Schedule ↔ Day ↔ Month) | Cross-fade with a slight rise; the view pill resizes and its label cross-fades | `SwapFade` (`lib/ui/motion.dart`) |
| Choosing an option (filter chip, segment, day) | The highlight **slides** to the new choice with a spring | `SlidingHighlightRow`, `SlidingCells` |
| Tapping cards and buttons | Shrink to 97% + dim while pressed, spring back | `Pressable` |
| Lists and home cards appearing | Fade + 14dp rise, staggered 35 ms per group | `FadeSlideIn` |
| Pushed screens | iOS slide with parallax; swipe from the edge to go back | `CupertinoPageTransitionsBuilder` |
| Numbers (progress, counts) | Count up to the new value | `CountText` |
| Empty states | Gentle looping illustration | Rive |
| Notification actions | **None** — handled by Android; must be instant | — |
| Permission explainers | Small animated illustration (phone ringing, clock) | Rive |

---

## 4b. Illustration style & mascot (DS6)

**Style rules (Duolingo-inspired, original artwork)**
- Flat vector shapes, **rounded and chunky**; no thin lines, no gradients
- **Bright, saturated palette** built from the type colors (blue, indigo, orange, pink) plus a warm yellow and a fresh green
- Simple shading: one highlight tone and one shadow tone per color
- Characters with **big expressive eyes** and exaggerated poses; readable at small sizes
- Same artwork works in light and dark themes (characters sit on their own shape, not directly on the background)

**Mascot: a friendly bell** (DS8) — the face of the app. A bell *is* a reminder, and ringing is a natural way to "nudge".

**Character brief**
- Round, chunky **warm-yellow bell** body with a slightly darker rim; one highlight tone, one shadow tone
- **Big expressive eyes** on the bell body; small mouth; short stubby arms
- The **clapper** peeks out at the bottom like little feet — it can hop, and swings when the bell rings
- Small loop/handle on top that can droop (sleepy) or perk up (excited)
- Must look clearly different from the **UI bell icon** (plain line icon for alerts) — the mascot is a character, never used as a UI icon
- Original design; check it doesn't resemble existing bell mascots or logos before finalizing
- Name: 🧑 to choose

**States** (one Rive file with a state machine):

| State | Bell behavior | Used in |
|---|---|---|
| Idle | Blinks, gentle sway | Empty states, welcome |
| Wave / hello | Waves an arm, little hop | Welcome, first launch |
| Typing / thinking | Eyes follow the text; taps chin | "Just type it" demo while chips appear |
| **Nudge** | **Rings** — body swings, clapper dings, sound lines | Nudges demo, permission explainer |
| Sleepy / night | Handle droops, eyes half-closed, "zzz" | Nag-hours sky animation outside hours |
| Happy / celebrate | Jumps, rings joyfully, confetti | Milestone celebrations ("All clear", occasion done) |
| Worried | Sweat drop, muffled clapper | Notifications-off and exact-alarm banners (small version) |

**Sound tie-in:** the completion chime (DS7) is the bell's own soft "ding", so sound and mascot feel like one character.

### AI art pipeline (DS9)

The mascot, illustrations, and animations are made with AI tools. Steps:

1. **Style guide prompt** — write one reusable prompt describing the style rules above (flat, chunky, rounded, palette, shading). Reuse it for every image so the style stays consistent.
2. **Concepts** — generate many bell character concepts with an image model; pick one.
3. **Character sheet** — generate the chosen bell from front/side views and in each of the 7 states' key poses, using the chosen concept as the reference image for consistency.
4. **Vectors** — produce clean SVGs: use a vector-native AI generator, or trace the images and clean them up. Rive needs vector shapes, not flat pictures.
5. **Split into parts** — separate body, rim, eyes, mouth, arms, clapper, and handle into their own layers so they can move independently.
6. **Animate in Rive** — import the parts, rig them, animate each state, and build the state machine with **Data Binding** (view-model properties like `mood`, `ring`, `progress` for the onboarding slider — state-machine inputs are deprecated in Rive Flutter). This step happens in the Rive editor; AI can help plan and troubleshoot, but expect hands-on time here.
7. **Integrate** — the app drives the state machine through the Rive Flutter runtime (`rive`), using **Data Binding** (state-machine inputs are deprecated in Rive Flutter).

**Checks before release**
- The AI tools' terms allow **commercial use** of generated images
- Style is consistent across all states and illustrations (same proportions, palette, line weight)
- Each Rive file stays small (target < 500 KB) and runs without dropped frames on a mid-range Android phone (bake-off device: Galaxy A73)

**Where illustrations appear:** onboarding (S-01–S-07), empty states (G1, G6–G8), milestone celebrations (§6), reliability/permission screens. **Never** in rows, calendar grids, notifications, or the capture sheet (except the onboarding demo).

---

## 5. Interactive onboarding

Replaces the static Welcome in FL-1. Every screen has **[Skip]**; the goal of < 60 s to the first saved reminder still applies (interactive screens are measured in beta and trimmed if they slow people down).

| Step | Screen | Interaction |
|---|---|---|
| 1 | **Welcome** — "One place for everything you can't forget" | Scattered notes, sticky notes, and calendar cards drift on screen and **gather into one list** when the user taps **[Get started]**. |
| 2 | **"Just type it"** | An input types out *"Mom's birthday Oct 12"* by itself; chips pop in one by one (**Occasion · Oct 12 · Every year**). Then: "Try your own" — the user types anything and the **real parser** responds live. **[Save this]** makes it their first reminder. |
| 3 | **"We nudge you before it matters"** | A phone mockup and a week timeline. The user **drags a slider** through the week; notifications appear at *1 week*, *1 day*, *the day*. A tap on **[I'm prepared]** in the mockup shows the remaining nudges disappear. |
| 4 | **Your schedule** | Settings from S-02. The nag-hours slider drives a **sky animation** (sunrise → night) so the hours feel tangible. |
| 5 | **Connect calendar** | Calendar cards slide into the timeline when connected. |
| 6 | **Permissions** (on first save) | Animated phone ringing on time; explains why before the system dialog. |

Steps 2–3 teach the two differentiators (fast capture, escalating nudges) by **doing**, not reading.

---

## 6. Completion animation

Fires whenever a task (or occasion) is marked done **in the app** — checkbox tap or swipe right.

**Standard completion** (every time, ≤ ~1 s total, never blocks the next action):
1. **Checkbox:** circle fills with the type color, springs 1 → 1.15 → 1; checkmark draws in (≈ 300 ms) + confirm haptic.
2. **Title:** strike-through line draws left to right; text fades to secondary color (≈ 200 ms).
3. **Hold** ≈ 600 ms so the user sees it and can tap **[Undo]**.
4. **Exit:** in Schedule, the row collapses and the list closes the gap (≈ 250 ms). In Day/Month views, it stays in faded "done" style (`VW-6`).
5. Snackbar **[Undo]** for 5 s (`OCC-5`); undo plays the animation in reverse.
- Completing several in a row: each animation runs independently; no queueing or waiting.

**Milestone celebrations** (rare, Rive, ≤ 1.5 s, tap to skip):
| Trigger | Celebration |
|---|---|
| Last item in **Today** completed | "All clear" — ring-closing animation + short message |
| **Occasion** marked done | Small burst of confetti in the occasion color |
| **Repeat-after-completion** task done | "Next: Jan 10" chip slides out of the row (FL-14) |
| First reminder ever completed | One-time welcome celebration |

**Sound (DS7):** setting **"Completion sounds"**, default **on** (`PRF-12`).
- Standard completion: a short, soft "pop/chime" (< 400 ms) timed with the checkmark
- Milestone celebrations: a slightly richer chime
- Undo: no sound
- **Silent when the phone is on silent or vibrate** (ringer mode respected); plays at a modest volume relative to system sounds
- Sound assets must be original or properly licensed

**Not animated:** completion from a notification (Android shows its own confirmation, `NTF-9`), and anything while Reduce Motion is on (checkbox simply fills).

---

## 7. Accessibility baseline
- WCAG AA contrast in both themes; type is never shown by color alone
- All text scales with system font size up to 200% without clipping (rows grow, grids show fewer labels)
- Every control has a TalkBack label; custom gestures (swipe) also available as buttons on the detail screen
- Reduce Motion respected everywhere (§4)
- Touch targets ≥ 48 dp

---

## 8. Open items 🧑

1. **Accent color** — Apple blue (`#007AFF`) as placeholder, or a brand color of your own?
2. **App icon & name** — tied to the final name (D2); the mascot could appear in the icon.
3. **Mascot name** — the bell needs a name.
4. **Inspiration picks** — after browsing §1, note the 3–5 screens you like most; they become the visual brief.

### Resolved
- Illustration style → Duolingo-style with original mascot (DS6)
- Completion sound → setting, default on (DS7)
- Mascot → friendly bell (DS8)
- Art production → AI tools + Rive (DS9)
