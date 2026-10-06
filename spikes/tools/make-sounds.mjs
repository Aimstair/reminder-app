// Generates license-free placeholder sounds for the animation bake-off.
// Usage: node spikes/tools/make-sounds.mjs  → writes spikes/assets/pop.wav and chime.wav
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const SAMPLE_RATE = 44100;
const outDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'assets');
mkdirSync(outDir, { recursive: true });

function wav(samples) {
  const data = Buffer.alloc(samples.length * 2);
  samples.forEach((s, i) => data.writeInt16LE(Math.max(-1, Math.min(1, s)) * 32767, i * 2));
  const header = Buffer.alloc(44);
  header.write('RIFF', 0);
  header.writeUInt32LE(36 + data.length, 4);
  header.write('WAVE', 8);
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20); // PCM
  header.writeUInt16LE(1, 22); // mono
  header.writeUInt32LE(SAMPLE_RATE, 24);
  header.writeUInt32LE(SAMPLE_RATE * 2, 28);
  header.writeUInt16LE(2, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36);
  header.writeUInt32LE(data.length, 40);
  return Buffer.concat([header, data]);
}

// Soft "pop": short pitch drop with fast decay (~180 ms)
function pop() {
  const n = Math.floor(SAMPLE_RATE * 0.18);
  const out = new Float32Array(n);
  let phase = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const freq = 900 * Math.exp(-t * 18) + 420;
    phase += (2 * Math.PI * freq) / SAMPLE_RATE;
    const env = Math.min(1, t / 0.004) * Math.exp(-t * 28);
    out[i] = Math.sin(phase) * env * 0.6;
  }
  return out;
}

// Bell-like chime: two bell partials, longer ring (~900 ms)
function chime() {
  const n = Math.floor(SAMPLE_RATE * 0.9);
  const out = new Float32Array(n);
  const partials = [
    [1046.5, 0.5, 4], // C6
    [1318.5, 0.3, 5], // E6
    [2093.0, 0.15, 7], // C7
    [2637.0, 0.08, 9],
  ];
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const attack = Math.min(1, t / 0.003);
    let s = 0;
    for (const [f, a, d] of partials) s += Math.sin(2 * Math.PI * f * t) * a * Math.exp(-t * d);
    out[i] = s * attack * 0.6;
  }
  return out;
}

writeFileSync(join(outDir, 'pop.wav'), wav(pop()));
writeFileSync(join(outDir, 'chime.wav'), wav(chime()));
console.log('Wrote pop.wav and chime.wav to', outDir);
