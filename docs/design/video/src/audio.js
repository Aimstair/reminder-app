// Scores places-promo: an original, fully synthesized soundtrack (no samples, no licences) — a calm
// pad + marimba-like plucks in F lydian at 96 BPM, a soft beat, and sound effects locked to the cues
// in places-promo.html. Writes a 48 kHz stereo WAV.
//   node audio.js out.wav
const fs = require('fs');

const SR = 48000, DUR = 15, N = SR * DUR;
const L = new Float32Array(N), R = new Float32Array(N);       // music bus
const SL = new Float32Array(N), SRr = new Float32Array(N);    // effects bus

// ---------- cue times (mirror places-promo.html) ----------
const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v));
const lerp = (a, b, u) => a + (b - a) * u;
const ioc = (t) => (t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
const oc = (t) => 1 - Math.pow(1 - t, 3);
function dotS(t) {
  if (t < 11.0) return 0;
  if (t < 11.6) return lerp(0, 170, ioc((t - 11.0) / .6));
  if (t < 12.5) return lerp(170, 800, ioc((t - 11.6) / .9));
  return lerp(800, 905, oc(clamp((t - 12.5) / .5)));
}
const HOME = { x: 420, y: 560, r: 112 }, TJ = { x: 1400, y: 650, r: 124 };
const inside = (P, t) => Math.hypot(420 + dotS(t) - P.x, 600 - P.y) <= P.r;
let T_LEAVE = 0, T_ARRIVE = 0;
for (let t = 10.9; t < 13.2; t += 1 / 600) {
  if (!T_LEAVE && !inside(HOME, t)) T_LEAVE = t;
  if (!T_ARRIVE && inside(TJ, t)) T_ARRIVE = t;
}
const TAPS = [4.64, 6.1, 7.2, 7.47, 8.3, 8.86, 9.32, 9.6, 10.03, 13.22];

// ---------- primitives ----------
const hz = (m) => 440 * Math.pow(2, (m - 69) / 12);
let seed = 7; const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647) * 2 - 1;
function add(bufL, bufR, t0, len, fn, gain = 1, pan = 0) {
  const s0 = Math.floor(t0 * SR), n = Math.floor(len * SR);
  const gl = gain * Math.cos((pan + 1) * Math.PI / 4), gr = gain * Math.sin((pan + 1) * Math.PI / 4);
  for (let i = 0; i < n; i++) { const k = s0 + i; if (k < 0 || k >= N) continue; const v = fn(i / SR); bufL[k] += v * gl; bufR[k] += v * gr; }
}
const M = (t0, len, fn, g, pan) => add(L, R, t0, len, fn, g, pan);
const S = (t0, len, fn, g, pan) => add(SL, SRr, t0, len, fn, g, pan);

// marimba-ish pluck: fundamental + 4th harmonic with fast decay
const pluck = (f, d = 1.2) => (t) => Math.exp(-t * 5 / d) * (Math.sin(2 * Math.PI * f * t) + .35 * Math.exp(-t * 30) * Math.sin(2 * Math.PI * f * 4 * t)) * Math.min(1, t * 400);
// soft bell: inharmonic partials
const bell = (f) => (t) => Math.min(1, t * 300) * (Math.exp(-t * 2.2) * Math.sin(2 * Math.PI * f * t) + .4 * Math.exp(-t * 4) * Math.sin(2 * Math.PI * f * 2.76 * t) + .2 * Math.exp(-t * 7) * Math.sin(2 * Math.PI * f * 5.4 * t));
function noiseLP(cut) { let y = 0; const a = Math.exp(-2 * Math.PI * cut / SR); return () => (y = (1 - a) * rnd() + a * y); }

// ---------- music ----------
const BEAT = 60 / 96, BAR = BEAT * 4;
// F lydian: Fmaj9 · C/E add9 · Am9 · Gsus2 · Fmaj9 · Cmaj9 (resolve on the outro)
const CHORDS = [[41, 53, 57, 60, 64, 67], [40, 52, 55, 60, 62, 67], [45, 52, 55, 60, 64, 71], [43, 50, 55, 57, 62, 67], [41, 53, 57, 60, 64, 67], [36, 48, 55, 59, 62, 64]];
CHORDS.forEach((ch, b) => {
  const t0 = b * BAR, len = b === 5 ? DUR - t0 : BAR + .4;
  ch.forEach((m, k) => {
    const f = hz(m + 12 * (k === 0 ? 0 : 0));
    // warm pad: two detuned triangles-ish (sine + 3rd harmonic), slow swell
    M(t0, len, (t) => {
      const env = Math.min(1, t / .9) * Math.min(1, (len - t) / .5);
      const w = (ff) => Math.sin(2 * Math.PI * ff * t) + .12 * Math.sin(2 * Math.PI * ff * 3 * t);
      return env * (w(f * 1.003) + w(f * .997)) * .5;
    }, k === 0 ? .05 : .022, (k % 2 ? .35 : -.35));
  });
  // bass pulse on beats 1 and 3 from bar 1
  if (t0 >= BAR * .8) [0, 2].forEach((bt) => M(t0 + bt * BEAT, BEAT * 1.8, (t) => Math.exp(-t * 2.5) * Math.sin(2 * Math.PI * hz(ch[0]) * t) * Math.min(1, t * 200), .16));
  // eighth-note arpeggio (starts when the app appears, rests during the intro)
  if (b >= 1) {
    const pat = [3, 4, 5, 4, 2, 4, 3, 5];
    pat.forEach((ix, i) => {
      const tt = t0 + i * BEAT / 2;
      if (tt < 1.95 || tt > 13.5) return;
      M(tt, 1.4, pluck(hz(ch[ix] + 12), .9), i % 2 ? .07 : .095, i % 2 ? .4 : -.4);
    });
  }
});
// intro: a single bell motif while the pin drops
[[0.52, 76], [0.86, 79], [1.2, 84]].forEach(([t, m]) => M(t, 3, bell(hz(m)), .07, 0));
// soft beat 2.0 → 13.4: kick on 1 & 3, shaker on off-beats
for (let t = BAR; t < 13.4; t += BEAT) {
  const n = Math.round(t / BEAT);
  if (n % 2 === 0) M(t, .35, (x) => Math.exp(-x * 14) * Math.sin(2 * Math.PI * (48 + 70 * Math.exp(-x * 30)) * x), .28);
  const sh = noiseLP(9000); M(t + BEAT / 2, .08, (x) => Math.exp(-x * 60) * sh() * .9, .025, .3);
}
// outro bloom: Cmaj9 bells + final low C
[[13.82, 72], [13.9, 76], [13.98, 79], [14.06, 83], [14.14, 86]].forEach(([t, m], i) => M(t, 2.2, bell(hz(m)), .055, (i - 2) * .25));
M(13.82, 1.2, (t) => Math.exp(-t * 2) * Math.sin(2 * Math.PI * hz(36) * t), .25);

// ---------- effects ----------
const thock = (f = 170) => (t) => Math.exp(-t * 26) * Math.sin(2 * Math.PI * f * (1 + .6 * Math.exp(-t * 60)) * t);
function whoosh(t0, len, g = .12, up = true) {
  const n = noiseLP(1200), n2 = noiseLP(3500);
  S(t0, len, (t) => { const u = t / len, env = Math.sin(Math.PI * Math.pow(up ? u : 1 - u, .7)) ** 2; return env * (n() * .7 + n2() * .3); }, g, 0);
}
const tick = (f = 2600, d = 90) => (t) => { const n = rnd(); return Math.exp(-t * d) * (.6 * Math.sin(2 * Math.PI * f * t) + .4 * n); };
const pop = (f) => (t) => Math.exp(-t * 28) * Math.sin(2 * Math.PI * f * (1 + .5 * (1 - Math.exp(-t * 40))) * t);

// intro pin drop + ripples
whoosh(.1, .45, .07);
S(.52, .4, thock(150), .55); S(.52, .05, tick(4000, 140), .1);
// pin flies into the phone, screen opens
whoosh(1.35, .65, .09);
S(1.97, .3, pop(880), .12);
[2.05, 2.14, 2.23].forEach((t, i) => S(t, .25, pop(980 + i * 160), .1, (i - 1) * .4));
whoosh(1.98, .5, .05);
// map pan / pinch (soft drags)
whoosh(3.05, .5, .035); whoosh(3.85, .45, .03);
// taps
TAPS.forEach((t) => S(t, .06, tick(2200, 120), .16, .2));
// phone swings to scene 2 + picker opens
whoosh(4.62, .65, .11);
// typing
for (let i = 0; i < 12; i++) S(5.35 + i * (.55 / 12), .04, tick(3200 + (i % 3) * 300, 160), .07, .25);
for (let i = 0; i < 8; i++) S(8.95 + i * (.35 / 8), .04, tick(3200 + (i % 3) * 300, 160), .07, .25);
// results drop down, map flies, pin drops
S(5.6, .25, pop(1300), .05); whoosh(6.1, .65, .07);
S(6.76, .4, thock(190), .45);
// icon + colour picks
S(7.22, .25, pop(1250), .09); S(7.5, .25, pop(1450), .09);
// slider detents 100 → 300 m
for (let k = 1; k <= 20; k++) { const u = k / 20; const tt = 7.72 + .4 * (u < .5 ? Math.cbrt(u / 4) : 1 - Math.cbrt((1 - u) / 4)); S(tt, .03, tick(4200, 260), .035, .3); }
// form sheet, Arrive toggle, Repeats, rows open
whoosh(8.4, .45, .06);
S(9.33, .08, tick(1800, 90), .14); S(9.36, .2, pop(1600), .06);
S(9.62, .2, pop(1100), .06);
// Save → check: two-note chime
S(10.06, 1.2, bell(hz(88)), .07, .1); S(10.16, 1.4, bell(hz(95)), .07, -.1);
// screen sleeps, wakes on the lock screen; world comes in
S(10.25, .25, thock(90), .18); whoosh(10.45, .6, .07);
// geofence crossings + notifications: ring swell, vibration buzz, tri-tone
function notify(t, base) {
  S(t, .9, (x) => Math.exp(-x * 3.5) * Math.sin(2 * Math.PI * hz(base - 12) * x) * Math.min(1, x * 50), .12); // crossing swell
  const tn = t + .1;
  S(tn, .45, (x) => (x % .1 < .07 ? 1 : .2) * Math.exp(-x * 2) * Math.sin(2 * Math.PI * 155 * x) * Math.sign(Math.sin(2 * Math.PI * 31 * x)), .11); // buzz
  [[0, 0], [.1, 4], [.2, 7]].forEach(([d, s]) => S(tn + d, 1.2, pluck(hz(base + s), .7), .14, (s - 3) * .1));
}
notify(T_LEAVE, 79); notify(T_ARRIVE, 84);
// clock rolls through the day
[11.8, 11.87, 11.94].forEach((t) => S(t, .04, tick(5200, 200), .05)); whoosh(11.75, .7, .04);
// Done collapses the notification
S(13.24, 1, bell(hz(91)), .06); S(13.3, .2, pop(1200), .06);
// outro: transition, logo, orbit pins
whoosh(13.42, .55, .1);
S(13.84, .5, pop(700), .14);
for (let k = 0; k < 6; k++) S(13.62 + k * .045 + .25, .2, pop(1100 + k * 120), .05, (k - 2.5) * .25);

// ---------- space: short stereo reverb on both buses ----------
function reverb(inL, inR, mix, fb = .55) {
  const taps = [[1123, 1291], [1559, 1433], [1931, 2087], [2381, 2251]];
  const bufs = taps.map(([a, b]) => [new Float32Array(a), new Float32Array(b)]);
  const ix = taps.map(() => [0, 0]);
  let lpL = 0, lpR = 0;
  for (let i = 0; i < N; i++) {
    let oL = 0, oR = 0;
    for (let k = 0; k < taps.length; k++) {
      const [bL, bR] = bufs[k], [iL, iR] = ix[k];
      const yL = bL[iL], yR = bR[iR];
      oL += yL; oR += yR;
      bL[iL] = inL[i] + yR * fb; bR[iR] = inR[i] + yL * fb; // cross-feed for width
      ix[k][0] = (iL + 1) % bL.length; ix[k][1] = (iR + 1) % bR.length;
    }
    lpL += .35 * (oL - lpL); lpR += .35 * (oR - lpR); // darken tails
    inL[i] += lpL * mix / taps.length; inR[i] += lpR * mix / taps.length;
  }
}
reverb(L, R, .45); reverb(SL, SRr, .3);

// ---------- mix, fade, soft limit, write ----------
const out = Buffer.alloc(44 + N * 4);
let peak = 0;
const mixL = new Float32Array(N), mixR = new Float32Array(N);
for (let i = 0; i < N; i++) {
  const t = i / SR, fade = Math.min(1, t / .15) * Math.min(1, (DUR - t) / .6);
  mixL[i] = (L[i] * .9 + SL[i]) * fade; mixR[i] = (R[i] * .9 + SRr[i]) * fade;
  peak = Math.max(peak, Math.abs(mixL[i]), Math.abs(mixR[i]));
}
const norm = .85 / Math.max(peak, 1e-6);
const lim = (x) => Math.tanh(x * norm * 1.15) / Math.tanh(1.15);
out.write('RIFF', 0); out.writeUInt32LE(36 + N * 4, 4); out.write('WAVE', 8); out.write('fmt ', 12);
out.writeUInt32LE(16, 16); out.writeUInt16LE(1, 20); out.writeUInt16LE(2, 22); out.writeUInt32LE(SR, 24);
out.writeUInt32LE(SR * 4, 28); out.writeUInt16LE(4, 32); out.writeUInt16LE(16, 34); out.write('data', 36); out.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) {
  out.writeInt16LE(Math.round(clamp(lim(mixL[i]), -1, 1) * 32767), 44 + i * 4);
  out.writeInt16LE(Math.round(clamp(lim(mixR[i]), -1, 1) * 32767), 46 + i * 4);
}
fs.writeFileSync(process.argv[2] || 'places-promo.wav', out);
console.log(`leave ${T_LEAVE.toFixed(3)}s · arrive ${T_ARRIVE.toFixed(3)}s · peak ${peak.toFixed(2)}`);
