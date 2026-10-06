#!/usr/bin/env bash
# Bake-off M1: scripted, identical interactions in both apps; frame stats from SurfaceFlinger TimeStats
# (counts janky frames the same way for any framework). Device: Galaxy A73 (1080x2400).
# Usage: bash spikes/tools/measure.sh [runs]   → prints CSV: app,run,scenario,frames,janky,jank%,avgFPS
export MSYS_NO_PATHCONV=1
RUNS=${1:-2}

declare -A ACT=( [rn]=app.aimstair.bakeoff.rn/.MainActivity [flutter]=app.aimstair.bakeoff_flutter/.MainActivity )
declare -A PKG=( [rn]=app.aimstair.bakeoff.rn [flutter]=app.aimstair.bakeoff_flutter )
# Coordinates from uiautomator dumps (see animation-bakeoff.md)
declare -A RAPID=( [rn]="913 335" [flutter]="911 370" )
FAB="942 2116"
declare -A TYPEDEMO=( [rn]="626 1696" [flutter]="624 2156" )
declare -A SAVE=( [rn]="928 1696" [flutter]="927 2156" )
NUDGES_TAB="180 175"
declare -A KNOB_Y=( [rn]=2128 [flutter]=2093 )
declare -A RESET=( [rn]="540 2245" [flutter]="540 2245" ) # upper part of Reset — lower part sits under the nav bar in both apps

start() { adb shell am start -S -n "${ACT[$1]}" >/dev/null; sleep 6; }
# Safety: never send input unless the test app is in the foreground (stops the run otherwise)
tap() { # app x y
  if ! adb shell dumpsys window | grep -m1 mCurrentFocus | grep -q "${PKG[$1]}"; then
    echo "ABORT: ${PKG[$1]} is not in the foreground" >&2; exit 1; fi
  adb shell input tap "$2" "$3"
}
swipe() { # app x1 y1 x2 y2 ms
  if ! adb shell dumpsys window | grep -m1 mCurrentFocus | grep -q "${PKG[$1]}"; then
    echo "ABORT: ${PKG[$1]} is not in the foreground" >&2; exit 1; fi
  adb shell input swipe "$2" "$3" "$4" "$5" "$6"
}
clear_stats() { adb shell dumpsys SurfaceFlinger --timestats -clear >/dev/null; }

# Framework-neutral metric: present-to-present intervals of the app's busiest layer
# (RN draws in the activity layer; Flutter in a SurfaceView layer, which has no FrameTimeline jank data).
# Both prototypes redraw every vsync (on-screen FPS meters), so an interval > 20 ms = dropped frame(s),
# robust to the phone switching between 60 and 120 Hz. Also reports intervals > 33 ms (visible stutter).
report() { # app run scenario
  adb shell dumpsys SurfaceFlinger --timestats -dump | tr -d '\r' | awk -v pkg="${PKG[$1]}" -v app="$1" -v run="$2" -v sc="$3" '
    /^layerName = / { layer = $0; next }
    /^present2present histogram is as below:/ { grab = 1; next }
    grab { grab = 0
           if (index(layer, pkg) == 0) next
           n = split($0, bins, " "); tot = 0; j20 = 0; j33 = 0
           for (i = 1; i <= n; i++) { split(bins[i], kv, "ms="); ms = kv[1] + 0; c = kv[2] + 0
                                      tot += c; if (ms > 20) j20 += c; if (ms > 33) j33 += c }
           if (tot > best) { best = tot; b20 = j20; b33 = j33 } }
    END { p20 = best ? 100*b20/best : 0; p33 = best ? 100*b33/best : 0
          printf "%s,%s,%s,%d,%d,%.1f,%d,%.1f\n", app, run, sc, best, b20, p20, b33, p33 }'
}

echo "app,run,scenario,frames,dropped_gt20ms,dropped_pct,stutter_gt33ms,stutter_pct"
for run in $(seq 1 "$RUNS"); do
  for app in rn flutter; do
    # B1 — scroll the 200-row list (6 flings down, 6 up)
    start $app; clear_stats
    for i in 1 2 3 4 5 6; do swipe $app 540 1700 540 500 150; sleep 0.8; done
    for i in 1 2 3 4 5 6; do swipe $app 540 600 540 1800 150; sleep 0.8; done
    sleep 1; report $app $run B1-scroll

    # B2 — rapid completion ×10 (checkbox, strike, hold, collapse, sound, haptic)
    start $app; clear_stats
    tap $app ${RAPID[$app]}; sleep 7
    report $app $run B2-rapid-complete

    # C — capture sheet: open, auto-type (chips pop in), save (row flies in)
    clear_stats
    tap $app $FAB; sleep 1.5
    tap $app ${TYPEDEMO[$app]}; sleep 3
    tap $app ${SAVE[$app]}; sleep 2.5
    report $app $run C-capture

    # A — nudges: slow drag through the week twice (cards, Rive bell, haptics)
    tap $app $NUDGES_TAB; sleep 2; clear_stats
    swipe $app 82 ${KNOB_Y[$app]} 998 ${KNOB_Y[$app]} 4000; sleep 2
    tap $app ${RESET[$app]}; sleep 1.5
    swipe $app 82 ${KNOB_Y[$app]} 998 ${KNOB_Y[$app]} 3000; sleep 2
    report $app $run A-nudges
  done
done
adb shell am force-stop app.aimstair.bakeoff.rn; adb shell am force-stop app.aimstair.bakeoff_flutter
