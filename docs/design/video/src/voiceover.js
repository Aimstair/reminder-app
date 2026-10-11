// Voiceover cut of places-promo: lays narration lines over the soundtrack and ducks the music under
// the voice. Lines are spoken by Piper (offline neural TTS) with the en_US-ljspeech-high voice —
// trained on the public-domain LJ Speech dataset, so it is free to use.
//   piper -m en_US-ljspeech-high.onnx --length_scale 0.95 -f l1.wav  < "Reminders that know where you are."
//   node voiceover.js <soundtrack.wav> <dir with l1..l6.wav> <out.wav>
const fs = require('fs');
const path = require('path');

// [file, start s] — each line lands on its scene's caption (see places-promo.html)
const LINES = [
  ['l1.wav', 0.35],  // Reminders that know where you are.          (intro headline)
  ['l2.wav', 2.5],   // See every place, at a glance.                (Browse)
  ['l3.wav', 5.15],  // Search a spot. Drop a pin. Set the radius.  (Create)
  ['l4.wav', 8.6],   // Arrive, leave, or both.                     (Create · form)
  ['l5.wav', 10.95], // And it rings the moment you get there.      (Get reminded)
  ['l6.wav', 13.86], // Places.                                     (logo lands)
];

function readWav(file) {
  const b = fs.readFileSync(file);
  let off = 12, fmt = null, data = null;
  while (off < b.length) {
    const id = b.toString('ascii', off, off + 4), size = b.readUInt32LE(off + 4);
    if (id === 'fmt ') fmt = { ch: b.readUInt16LE(off + 10), sr: b.readUInt32LE(off + 12) };
    if (id === 'data') data = b.subarray(off + 8, off + 8 + size);
    off += 8 + size + (size & 1);
  }
  const n = data.length / 2 / fmt.ch, chans = [...Array(fmt.ch)].map(() => new Float32Array(n));
  for (let i = 0; i < n; i++) for (let c = 0; c < fmt.ch; c++) chans[c][i] = data.readInt16LE((i * fmt.ch + c) * 2) / 32768;
  return { sr: fmt.sr, chans };
}

const [bedFile, dir, outFile] = process.argv.slice(2);
const bed = readWav(bedFile), SR = bed.sr, N = bed.chans[0].length;
const voice = new Float32Array(N);
for (const [f, start] of LINES) {
  const v = readWav(path.join(dir, f)), src = v.chans[0], k = v.sr / SR;
  // resample (linear) 22.05 kHz → 48 kHz, gentle 4 ms fades at the edges
  const len = Math.floor(src.length / k), s0 = Math.round(start * SR);
  for (let i = 0; i < len && s0 + i < N; i++) {
    const x = i * k, j = Math.floor(x), u = x - j;
    const s = src[j] * (1 - u) + (src[j + 1] ?? 0) * u;
    const edge = Math.min(1, i / (SR * .004), (len - i) / (SR * .004));
    voice[s0 + i] += s * edge;
  }
}
// warmth: a touch of low-shelf via one-pole split, and a light presence lift
let lp = 0; for (let i = 0; i < N; i++) { lp += .08 * (voice[i] - lp); voice[i] = voice[i] * 1.0 + lp * .35; }
// side-chain duck: follow the voice envelope (fast attack, slow release) and pull the bed down ~11 dB
const duck = new Float32Array(N); let env = 0;
for (let i = 0; i < N; i++) { const a = Math.abs(voice[i]); env = a > env ? env + (a - env) * .02 : env * .99993; duck[i] = env; }
let peakV = 0; for (const v of voice) peakV = Math.max(peakV, Math.abs(v));
const vg = .9 / peakV; // voice sits on top
const out = [new Float32Array(N), new Float32Array(N)];
let peak = 0, eV = 0, eB = 0;
for (let i = 0; i < N; i++) {
  const d = Math.min(1, duck[i] * vg * 6); // 0 … 1 while speaking
  const g = 1 - .72 * d;                   // ≈ −11 dB under the voice
  for (let c = 0; c < 2; c++) { out[c][i] = bed.chans[c][i] * g * .75 + voice[i] * vg * .9; peak = Math.max(peak, Math.abs(out[c][i])); }
  if (d > .5) { eV += (voice[i] * vg * .9) ** 2; eB += (bed.chans[0][i] * g * .75) ** 2; }
}
const norm = .95 / Math.max(peak, .95);
const buf = Buffer.alloc(44 + N * 4);
buf.write('RIFF', 0); buf.writeUInt32LE(36 + N * 4, 4); buf.write('WAVE', 8); buf.write('fmt ', 12);
buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22); buf.writeUInt32LE(SR, 24);
buf.writeUInt32LE(SR * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34); buf.write('data', 36); buf.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) for (let c = 0; c < 2; c++) buf.writeInt16LE(Math.round(Math.max(-1, Math.min(1, out[c][i] * norm)) * 32767), 44 + (i * 2 + c) * 2);
fs.writeFileSync(outFile, buf);
console.log(`voice is ${(10 * Math.log10(eV / eB)).toFixed(1)} dB over the music while speaking · voice peak ${peakV.toFixed(2)} · mix peak ${peak.toFixed(2)}`);
