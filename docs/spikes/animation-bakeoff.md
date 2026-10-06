# Spike: Animation Bake-off — React Native vs Flutter

**Question:** Which framework should the app be built in, given our animation plans?
**Method:** build the same throwaway prototype in both, timeboxed, then compare with the same measurements.
**Status:** ✅ complete — **Flutter selected** (2026-10-06) · **Decision owner:** you · **Feeds:** `docs/architecture.md` stack decision, `CLAUDE.md`

---

## 1. Rules
- **Same spec, same assets, same device** for both prototypes.
- **Timebox: 2 working days each.** Unfinished parts count against the framework.
- **Throwaway code** in `spikes/rn-animation/` and `spikes/flutter-animation/` — never copied into the real app.
- Built entirely with AI (as the real app will be); log every time the AI produced broken or outdated code.
- Measure in **release/profile builds** on a **real mid-range Android phone** (emulators don't show real performance).

## 2. What to build (identical in both)

### Scene A — Nudges demo (onboarding, `design-direction.md` §5)
- Phone mockup + horizontal slider for a 7-day week
- Dragging the slider drives a **Rive state machine** (bell mascot placeholder: idle → nudge/ring at 1 week, 1 day, day-of)
- Notification cards slide into the mockup at each stage with spring motion
- Tap **[I'm prepared]** in the mockup → remaining cards fade out, bell switches to happy

### Scene B — Schedule list + completion (`design-direction.md` §6)
- List of **200 reminders** in groups (Overdue / Today / Tomorrow / Later), rows per the Things 3 style
- **Completion animation:** checkbox fills with type color, spring 1 → 1.15 → 1, checkmark draws, strike-through draws, 600 ms hold, row collapses; haptic + sound (`PRF-12`)
- **Swipe right** to complete (follows finger, springs back)
- Rapid test: complete 10 rows in under 5 seconds — no stutter, no queueing
- **Undo** snackbar reverses the animation

### Scene C — Capture sheet
- **[+]** opens a bottom sheet with spring
- Typing a fixed phrase ("Mom's birthday Oct 12") makes chips **pop in one by one** (stub parser: keyword match, not the real parser)
- **[Save]** → the new row **flies into its group** in the list

### Scene D — Milestone celebration
- Completing the last Today item triggers **"All clear"**: Rive celebration (bell happy) + confetti, ≤ 1.5 s, tap to skip
- **Reduce Motion** on: celebration skipped, checkbox just fills

### Shared assets
- **Rive file:** a placeholder character with a state machine (inputs: `state` number, `progress` 0–100, `ring` trigger). Use a sample from Rive's official examples or community — **check its license** — or a quick bell made in the Rive editor. The real AI-made bell comes later.
- Font: Inter · Colors/tokens: `design-direction.md` §3 · Light and dark theme
- Sound: any short free-license "pop" sound

### Stack for each
| | React Native | Flutter |
|---|---|---|
| App shell | Expo (dev build), TypeScript | Flutter stable, Dart |
| Motion | Reanimated, Gesture Handler | Built-in animation APIs (`AnimationController`, implicit animations, physics/springs) |
| Rive | rive-react-native | rive (official Flutter runtime) |
| List | FlashList | `ListView.builder` / slivers |
| Sheet | @gorhom/bottom-sheet | `showModalBottomSheet` / DraggableScrollableSheet |
| Haptics / sound | expo-haptics, expo-audio | `HapticFeedback`, audioplayers (or similar) |

## 3. Measurements

| # | Metric | How | Weight |
|---|---|---|---|
| M1 | **Smoothness** — janky frames during each scene (A slider drag, B rapid completion, B scroll, C sheet + chips, D celebration) | RN: `adb shell dumpsys gfxinfo <package> framestats` · Flutter: DevTools performance view / overlay in profile mode · both: screen recording at 60 fps for side-by-side | **30%** |
| M2 | **Build effort with AI** — hours spent, number of AI fixes needed, outdated/invented APIs hit, scenes finished within the timebox | Log while building | **25%** |
| M3 | **Feel & design fidelity** — how close to the Things 3 / Notion Calendar look; spring feel; touch response | Your hands-on score 1–5 per scene | **20%** |
| M4 | **Tooling friction** — setup time, build errors, hot reload reliability, release build pain | Log while building | **15%** |
| M5 | **Size & startup** — release APK size, cold start time | APK file size · `adb shell am start -W` (3 runs, median) | **10%** |

**Known factors not tested here** (add to the decision, not the score):
- **Parser:** React Native can build on chrono-node; Flutter needs a parser written from scratch (more work for the core feature).
- **Web (v3):** React Native Web produces normal web pages; Flutter Web draws on a canvas (heavier, weaker accessibility/SEO).
- **Tooling:** Expo cloud builds iOS without a Mac and supports over-the-air updates; Flutter needs a Mac or a cloud CI (e.g. Codemagic) for iOS, and a third-party service for over-the-air updates.

## 4. Decision rule
- Score each framework 1–5 per metric → weighted total.
- **Flutter wins** if its weighted score beats React Native's by **≥ 0.5** (enough to outweigh the parser and web factors above).
- Otherwise **React Native** (current plan) stays.
- Record the result and scores in `docs/architecture.md` and the decision log in `docs/behavior-spec.md`.

## 4b. Build log

### Environment (affects both, not scored)
- Slow network: npm requests took 2–120 s each; first `npm install` timed out and was retried with long timeouts. Not a framework issue.

### React Native (Expo SDK 57, RN 0.86.3, Reanimated 4.5.1, rive-react-native 9.8.5)
| # | Event | Type |
|---|---|---|
| 1 | Scaffold + installs with `npx expo install` (SDK-matched versions) | Setup |
| 2 | `StyleSheet.absoluteFillObject` removed in RN 0.86 — AI used the old API; replaced with explicit style | Outdated API (1) |
| 3 | Used Reanimated `Animated.FlatList` + layout animations instead of FlashList for the row-collapse animation | Design note |
| 4 | Placeholder Rive file: Rive's public "avatar" example via URL (state machine `avatar`, inputs `isHappy`/`isSad`); code-animated bell fallback if Rive fails | Asset |
| 5 | Typecheck clean after fix #2 | — |

| 6 | Android prebuild warns dark mode needs `expo-system-ui` — one extra package for something Flutter does by default | Setup friction |
| 7 | First release build killed by Claude Code (PC low on RAM: 1.2 GB free of 11.7 GB). Rebuilt with Gradle capped at 1.5 GB, 2 workers, arm64 only | Environment |
| 8 | Native (C++) build of react-native-worklets failed: `ninja: manifest 'build.ninja' still dirty after 100 tries`. Not stale files or timestamps — caused by **spaces in the project path** on Windows. A `subst` drive didn't work (Node resolves it back to the real path → "different roots" codegen error). Fix: copied the prototype to `C:\dev\bakeoff-rn` and built there. **Real project must live in a path without spaces** | Tooling friction (Windows) |
| 9 | Kotlin compile of rive-react-native ran out of memory at a 1.5 GB Gradle heap; succeeded at 2.5 GB. Total release build: ~19 min first time (8 + 11), 822 tasks | Tooling (build weight) |
| 10 | ✅ Release APK built: **46.8 MB** (arm64-v8a only, Expo defaults, no R8/shrinking) | M5 |

### Flutter (Flutter 3.47.6 stable, rive 0.14.11, audioplayers 6.8.1)
| # | Event | Type |
|---|---|---|
| 1 | SDK install: git clone + first-run download; Android needs cmdline-tools + license acceptance (manual) | Setup |
| 2 | Rive 0.14 uses a new API (`RiveWidgetBuilder`, `FileLoader`, `RiveNative.init()`) — AI had to read package source before writing code | API drift (learned, not broken) |
| 3 | First theme draft by AI was malformed (misplaced import, hand-rolled spring math) — rewritten to use Flutter's `SpringSimulation` | AI quality (1) |
| 4 | Name clash: custom `Feedback` class vs Flutter's built-in `Feedback` — renamed | AI slip (1) |
| 5 | Title inside first `AnimatedList` item would animate away with the Overdue group — switched to `CustomScrollView` + `SliverAnimatedList` | Design fix |
| 6 | `flutter analyze` clean except: Rive Flutter deprecates state-machine inputs in favor of **Data Binding** (RN runtime still supports inputs) — affects how the real bell's Rive file should be built | Info — important for DS9 |
| 7 | No spring animation primitive equivalent to Reanimated's `.springify()` for list/enter animations — wrote a small `SpringCurve` from `SpringSimulation` | Effort note |
| 8 | Flutter template sets Gradle heap to 8 GB (more than free RAM) — lowered to 2.5 GB, 2 workers; built in `C:\dev\bakeoff-flutter` (no spaces) for parity with RN | Environment |
| 9 | First release build failed after **58 min** at `rive_native:runRiveNativeSetup`: the step shells out to `dart`, which wasn't on this session's PATH (Flutter added to PATH mid-session). Ran `dart run rive_native:setup -p android` manually (downloads prebuilt Rive libs), then rebuilt | Tooling friction (Rive Flutter needs a download step at build time) |
| 10 | Second build failed after 6 min (cause not captured — only the log tail was saved); third build with full logging succeeded in 89 s with no changes. Counted as one unexplained flaky failure | Tooling (flaky) |
| 11 | ✅ Release APK built: **39.4 MB** (arm64 only, Flutter defaults — tree-shaking on). Total first-time build ≈ 66 min across 3 attempts | M5 |

| 12 | Flutter capture sheet buttons rendered **under the Android navigation bar** (edge-to-edge, no bottom inset) — scripted tap hit Home. Fixed with `useSafeArea` + bottom padding. AI-written layout bug | AI quality (1) |

### Measurement setup (M1, M5)
- **Device:** Samsung Galaxy A73 5G (SM-A736B), Android 15, adaptive 60/120 Hz, animation scale 1.0
- **Builds:** release APKs, arm64 only, built in `C:\dev\` (no spaces)
- **Script:** `spikes/tools/measure.sh` — identical adb-driven taps/swipes per scenario, with a guard that aborts if the test app isn't in the foreground
- **Metric:** SurfaceFlinger TimeStats present-to-present intervals for the app's drawing layer. Android's FrameTimeline "jank" counters don't cover Flutter's SurfaceView, so they can't be compared. Both prototypes redraw every vsync (FPS meters), so an interval **> 20 ms = dropped frame(s)** (robust to 60/120 Hz switching); **> 33 ms = visible stutter**
- Raw results: `spikes/results/m1-results.csv` (2 runs per app)

### M1 results (2 runs, ranges)
| Scenario | RN dropped % | RN stutter % | RN frames | Flutter dropped % | Flutter stutter % | Flutter frames |
|---|---|---|---|---|---|---|
| B1 scroll (12 flings) | 2.3–2.4 | 0.2–0.3 | ~1,525 | **0.0** | **0.0** | ~1,935 |
| B2 rapid ×10 complete | 4.9–5.9 | **1.8** | ~550 | **0.0** | **0.0** | ~895 |
| C capture sheet | 0.2–0.3 | 0.2–0.3 | ~935 | 0.0–0.1 | 0.0 | ~977 |
| A nudges slider + Rive | 0.5–0.6 | 0.2 | ~1,157 | 0.0–0.1 | 0.0 | ~1,647 |

Flutter also delivered **more frames per second** in every scenario (≈ 120+ fps vs RN ≈ 80–100), i.e. it held the 120 Hz refresh rate more often. Caveat: the RN list uses `Animated.FlatList` (needed for layout animations), not FlashList; heavier optimization might narrow the gap, but both prototypes received equal AI effort per the bake-off rules.

### M5 results
| | React Native | Flutter |
|---|---|---|
| APK size (arm64, release) | 46.8 MB | **39.4 MB** |
| Cold start to first frame (median of 3) | **252 ms** | 597 ms |

Cold-start caveat: "first frame" isn't "usable" — RN's first frame is blank while fonts load; Flutter waits for Rive init before its first frame.

## 5. Results
*(fill in after the bake-off)*

| Metric (weight) | React Native | Flutter | Notes |
|---|---|---|---|
| M1 Smoothness (30%) | 3 | **5** | Flutter 0–0.1% dropped frames in all scenes vs RN 0.2–5.9% (1.8% visible stutter in rapid completion); Flutter held ~120 fps more often |
| M2 Build effort with AI (25%) | **4** | 3 | RN: 1 outdated API. Flutter: malformed first theme draft, `Feedback` name clash, sheet under nav bar, hand-written spring curve, had to read Rive source |
| M3 Feel (20%) | 2 | **4** | Hands-on (owner, Galaxy A73): "React Native animation is jumping up and down violently… Flutter is better for animation integration". Scores inferred from this feedback |
| M4 Tooling (15%) | 3 | 3 | RN: path-with-spaces native build failure, Kotlin OOM, extra package for dark mode. Flutter: SDK + Android setup, 8 GB default heap, Rive native download step failed (58 min), one unexplained failure; ~66 min first build |
| M5 Size & startup (10%) | 4 | 4 | RN faster first frame (252 vs 597 ms, with caveats); Flutter smaller APK (39.4 vs 46.8 MB) |
| **Weighted** | **3.15** | **3.90** | Margin **0.75** ≥ 0.5 threshold |

Fairness note: RN's jumping likely comes partly from how the AI wired list layout animations (springy `LinearTransition` on rows); an expert could reduce it. Per the bake-off rules (equal AI effort — the same way the real app will be built), it counts.

**Decision:** **Flutter** wins under the decision rule (2026-10-06). Accepted trade-offs carried into the plan:
- **Parser** must be written in Dart from scratch (no chrono-node) — the 117-case `parser-test-set.md` is the spec
- **Web (v3)** will use Flutter Web (canvas-based) — revisit at v3 whether a separate web client is better
- **iOS builds (v2)** need a Mac or cloud CI (e.g. Codemagic); over-the-air updates need a third-party service (e.g. Shorebird)
- **Rive:** build the real bell with **Data Binding** (state-machine inputs are deprecated in Rive Flutter)
- **Windows dev:** keep the real project in a path **without spaces** (e.g. `C:\dev\reminder-app`)
