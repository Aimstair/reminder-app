# Places launch film

`places-promo.mp4` is a 15-second, 1920×1080, 60 fps film introducing place reminders (`LOC-*`).

**How it's built.** The film isn't screen-recorded. `src/places-promo.html` rebuilds the screens of mockups 11–15 from the app's tokens, Inter and Phosphor, so every chip, pin, row and sheet can move on its own. Everything outside the phone follows the app's calm Things 3 / Apple look (DS1, DS10): a flat #F5F5F7 canvas, no gradients or glows, an accent-blue label, a near-black semibold Inter headline, grey body text, and lines that fade up one by one. `seek(t)` sets every element's pose as a pure function of time. To look at any frame, open `src/places-promo.html?t=7.5` in a browser.

| Time | Beat |
|---|---|
| 0–2 s | A pin drops onto ripples, then flies into the phone and becomes the Home pin |
| 2–4.7 s | Places screen (S-19) builds itself; the map pans and pinches; tap **+** |
| 4.7–8.4 s | Picker (S-24): search, tap the result, pin drops, pick icon and color, drag the radius to 300 m |
| 8.4–10.4 s | Form (S-25): title, Arrive, Repeats → weekdays 9–5, Save |
| 10.4–13.5 s | Leave Home at 8:05 AM, arrive at Trader Joe's at 4:45 PM. Each crossing rings its notification (LOC-9 copy), and Done collapses it |
| 13.5–15 s | Outro: Places · "Remind me when I get there." |

**Sound.** `src/audio.js` synthesizes the whole soundtrack: a calm pad with marimba-like plucks in F lydian at 96 BPM, a soft beat, and effects timed to the cues (pin drops, taps, typing, slider detents, the Save chime, the vibration and tri-tone for each notification, the outro bloom). There are no samples, so there is nothing to license.

**Rendering.** Needs headless Edge and two npm packages kept outside the repo:

```
npm i puppeteer-core ffmpeg-static            # in any folder
NODE_PATH=<that folder>/node_modules node src/render.js video silent.mp4 60 1
NODE_PATH=<that folder>/node_modules node src/render.js stills 2.9,7.9,12.9 out/   # review frames
```

Use `1` as the last argument (no sub-frame blending, because blending ghosts fast text). Then add the sound:

```
node src/audio.js promo.wav
ffmpeg -i silent.mp4 -i promo.wav -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart places-promo.mp4
```

**Voiceover cut.** `places-promo-voiceover.mp4` is the same film with narration. The lines are spoken by [Piper](https://github.com/rhasspy/piper), an offline neural text-to-speech engine, using the `en_US-ljspeech-high` voice. That voice is trained on the public-domain LJ Speech dataset, so it's free to use. `src/voiceover.js` places each line on its scene and lowers the music about 11 dB while the voice speaks:

| Time | Line |
|---|---|
| 0.35 s | Reminders that know where you are. |
| 2.5 s | See every place, at a glance. |
| 5.15 s | Search a spot. Drop a pin. Set the radius. |
| 8.6 s | Arrive, leave, or both. |
| 10.95 s | And it rings the moment you get there. |
| 13.86 s | Places. |

```
echo "See every place, at a glance." | piper -m en_US-ljspeech-high.onnx --length_scale 0.95 -f vo/l2.wav   # one per line
node src/voiceover.js promo.wav vo/ promo-vo.wav
ffmpeg -i silent.mp4 -i promo-vo.wav -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart places-promo-voiceover.mp4
```
