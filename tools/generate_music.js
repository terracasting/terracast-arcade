// Generates an original instrumental WAV for the TerraCast prototype.
// v2: detuned saw/triangle pads instead of thin pure sines, a real
// four-on-the-floor drum groove with sidechain pumping, a swung hi-hat,
// crash accents on section changes, and a short feedback-delay reverb
// pass so the mix has some depth instead of sounding flat and dry.
const fs = require('fs');
const path = require('path');

const rate = 44100;
const seconds = 103;
const count = rate * seconds;
const bpm = 112;
const beat = 60 / bpm;
const bar = beat * 4;

// A minor -> F -> C -> G (i - VI - III - VII): warmer and more melodic
// than a single major loop, still simple enough to stay unobtrusive.
const chords = [
  { root: 220.00, ratios: [1, 1.2, 1.5] },   // Am
  { root: 174.61, ratios: [1, 1.25, 1.5] },  // F
  { root: 261.63, ratios: [1, 1.25, 1.5] },  // C
  { root: 196.00, ratios: [1, 1.25, 1.5] },  // G
];
const scale = [220.0, 246.94, 261.63, 293.66, 329.63, 349.23, 392.0, 440.0]; // A minor-ish
const motifA = [0, 2, 4, 3, 2, 0, 2, 4];
const motifB = [7, 6, 4, 5, 4, 2, 3, 0];

let seed = 90121;
function noise() { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 2147483648 - 1; }
function sine(freq, t) { return Math.sin(Math.PI * 2 * freq * t); }
function saw(freq, t) { const ph = (freq * t) % 1; return 2 * ph - 1; }
function tri(freq, t) { const ph = (freq * t) % 1; return 4 * Math.abs(ph - 0.5) - 1; }
function soft(x) { return Math.tanh(x * 1.2); }

const dry = new Float32Array(count);

for (let i = 0; i < count; i++) {
  const t = i / rate;
  const barNo = Math.floor(t / bar);
  const section = Math.floor(barNo / 8) % 6; // 0..5, 8 bars each, ~103s total
  const chord = chords[barNo % 4];
  const inBar = (t % bar) / beat;
  const beatNo = Math.floor(inBar);
  const beatPhase = inBar - beatNo;
  const eighth = Math.floor(inBar * 2);
  // Light swing: delay every other eighth note slightly.
  const swing = (eighth % 2 === 1) ? 0.045 : 0.0;
  const eighthPhase = Math.max(0, inBar * 2 - eighth - swing);
  let bed = 0, bass = 0, arp = 0, lead = 0, drums = 0;

  // Sidechain envelope: everything except the drums ducks in time with
  // the four-on-the-floor kick, giving the track a driving "pump".
  const duck = 1 - 0.32 * Math.exp(-16 * beatPhase);

  // Pad bed: two detuned voices per chord tone (triangle, warmer than a
  // bare sine) so chords sound full instead of thin.
  for (let n = 0; n < chord.ratios.length; n++) {
    const hz = chord.root * chord.ratios[n];
    bed += (tri(hz, t) + tri(hz * 1.006, t)) * 0.021;
  }
  bed *= duck;

  // Bass: sub sine plus a saw harmonic for grit, octave pickup on the
  // "and" of beat 4 to keep the groove moving forward.
  if (section >= 1) {
    const bassHz = chord.root * 0.5 * (beatNo === 3 && beatPhase > 0.5 ? 2 : 1);
    const env = Math.exp(-2.0 * beatPhase);
    bass = (sine(bassHz, t) * 0.8 + saw(bassHz, t) * 0.22) * 0.16 * env * duck;
  }

  // Rhythm arp: swung sixteenth-feel plucks outlining the chord.
  if (section === 2 || section === 3 || section === 5) {
    const tone = chord.root * chord.ratios[(eighth + barNo) % chord.ratios.length] * 2;
    const env = Math.exp(-8.5 * eighthPhase);
    arp = (saw(tone, t) * 0.6 + tri(tone * 2, t) * 0.25) * env * 0.09 * duck;
  }

  // Lead melody: motif A in the first "chorus", motif B in the climax,
  // both with light vibrato so it doesn't sound static.
  if (section === 3 || section === 4 || section === 5) {
    const motif = section === 5 ? motifB : motifA;
    const note = motif[(eighth + barNo * 2) % motif.length];
    let hz = scale[note] * (section >= 4 ? 2 : 1);
    hz *= 1 + 0.006 * Math.sin(Math.PI * 2 * 5.2 * t);
    const env = Math.min(1, eighthPhase * 16) * Math.exp(-3.0 * eighthPhase);
    const gain = section === 5 ? 0.115 : (section === 4 ? 0.07 : 0.09);
    lead = (saw(hz, t) * 0.55 + sine(hz * 2, t) * 0.25) * env * gain * duck;
  }

  // Drums: four-on-the-floor kick, backbeat snare/clap, swung hats, and
  // a soft crash on every section change for a clear sense of arrival.
  const drumGain = section === 4 ? 0.55 : (section >= 2 ? 1 : 0);
  if (drumGain > 0) {
    const kickHz = 74 - 40 * beatPhase;
    drums += sine(kickHz, t) * Math.exp(-15 * beatPhase) * 0.36 * drumGain;
    if (beatNo === 1 || beatNo === 3) {
      const snareEnv = Math.exp(-17 * beatPhase);
      drums += (noise() * 0.7 + sine(190, t) * 0.16) * snareEnv * 0.2 * drumGain;
    }
    const hatEnv = Math.exp(-30 * eighthPhase);
    drums += noise() * hatEnv * (eighth % 4 === 2 ? 0.06 : 0.036) * drumGain;
  }
  if (barNo % 8 === 0 && beatNo === 0 && beatPhase < 1.2) {
    drums += noise() * Math.exp(-1.4 * beatPhase) * 0.05;
  }

  const fade = Math.min(1, t / 2.5, (seconds - t) / 2.5);
  dry[i] = (bed + bass + arp + lead + drums) * fade;
}

// Short feedback-delay reverb pass for a bit of depth, mixed low so the
// track stays clean rather than washy.
const wet = new Float32Array(count);
const delays = [0.031, 0.047, 0.059].map((s) => Math.round(s * rate));
const feedback = 0.32;
for (const d of delays) {
  for (let i = 0; i < count; i++) {
    const tapped = i >= d ? wet[i - d] * feedback + dry[i - d] * 0.5 : 0;
    wet[i] += tapped / delays.length;
  }
}

const pcm = Buffer.alloc(count * 2);
let peak = 0;
for (let i = 0; i < count; i++) peak = Math.max(peak, Math.abs(dry[i] + wet[i] * 0.35));
const norm = peak > 0.98 ? 0.98 / peak : 1;
for (let i = 0; i < count; i++) {
  const sample = soft((dry[i] + wet[i] * 0.35) * norm);
  pcm.writeInt16LE(Math.round(Math.max(-1, Math.min(1, sample)) * 32767), i * 2);
}

const header = Buffer.alloc(44);
header.write('RIFF', 0); header.writeUInt32LE(36 + pcm.length, 4); header.write('WAVE', 8);
header.write('fmt ', 12); header.writeUInt32LE(16, 16); header.writeUInt16LE(1, 20);
header.writeUInt16LE(1, 22); header.writeUInt32LE(rate, 24); header.writeUInt32LE(rate * 2, 28);
header.writeUInt16LE(2, 32); header.writeUInt16LE(16, 34);
header.write('data', 36); header.writeUInt32LE(pcm.length, 40);
const out = path.join(__dirname, '..', 'audio', 'terracast_garden_groove.wav');
fs.writeFileSync(out, Buffer.concat([header, pcm]));
console.log(`${out}: ${seconds}s, ${(pcm.length / 1048576).toFixed(1)} MiB`);
