// Generates a two-minute original instrumental WAV for the TerraCast prototype.
// Sections add and remove drums, bass, pads, rhythm plucks, and lead motifs.
const fs = require('fs');
const path = require('path');

const rate = 22050;
const seconds = 120;
const count = rate * seconds;
const pcm = Buffer.alloc(count * 2);
const bpm = 104;
const beat = 60 / bpm;
const bar = beat * 4;
const roots = [130.81, 110.0, 87.31, 98.0]; // C, A, F, G
const chordRatios = [[1,1.25,1.5],[1,1.2,1.5],[1,1.25,1.667],[1,1.25,1.5]];
const scale = [261.63,293.66,329.63,392.0,440.0,523.25,587.33,659.25];
const motifs = [
  [0,2,3,2,4,3,2,0], [0,3,4,6,4,3,2,0],
  [4,3,2,0,2,3,4,6], [7,6,4,3,4,3,2,0]
];
let seed = 17729;
function noise() { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 2147483648 - 1; }
function osc(freq,t) { return Math.sin(Math.PI * 2 * freq * t); }
function soft(x) { return Math.tanh(x * 1.25); }

for (let i=0;i<count;i++) {
  const t = i / rate;
  const barNo = Math.floor(t / bar);
  const section = Math.floor(barNo / 8) % 6;
  const chord = barNo % 4;
  const inBar = (t % bar) / beat;
  const beatNo = Math.floor(inBar);
  const beatPhase = inBar - beatNo;
  const eighth = Math.floor(inBar * 2);
  const eighthPhase = inBar * 2 - eighth;
  let s = 0;

  // Warm chord bed, with a subtle stereo-like chorus collapsed cleanly to mono.
  const ratios = chordRatios[chord];
  for (let n=0;n<3;n++) {
    const hz = roots[chord] * ratios[n];
    s += (osc(hz,t) + .32*osc(hz*2.003,t)) * .028;
  }

  // Rounded bass line with alternating octave pickup.
  const bassHz = roots[chord] * (beatNo === 3 ? 2 : 1);
  s += (osc(bassHz,t) + .18*osc(bassHz*2,t)) * .12 * Math.exp(-1.8*beatPhase);

  // Muted guitar/rhythm-pluck layer, absent briefly in the breakdown.
  if (section !== 3) {
    const arp = roots[chord] * ratios[(eighth + barNo) % 3] * 2;
    const env = Math.exp(-7.5*eighthPhase);
    s += (osc(arp,t) + .35*osc(arp*2,t) + .12*osc(arp*3,t)) * env * .095;
  }

  // Lead melody enters in alternating sections and changes motif every 8 bars.
  if (section === 1 || section === 2 || section === 4 || section === 5) {
    const motif = motifs[section % motifs.length];
    const note = motif[(eighth + barNo*2) % motif.length];
    const hz = scale[note];
    const env = Math.min(1,eighthPhase*18) * Math.exp(-3.2*eighthPhase);
    s += (osc(hz,t) + .16*osc(hz*2,t)) * env * (section === 5 ? .105 : .075);
  }

  // Full drum groove: kick, snare/clap, and shuffled hats. Breakdown is lighter.
  const drumGain = section === 3 ? .48 : 1;
  if (beatNo === 0 || beatNo === 2) {
    const kickHz = 76 - 38*beatPhase;
    s += osc(kickHz,t) * Math.exp(-13*beatPhase) * .34 * drumGain;
  }
  if (beatNo === 1 || beatNo === 3) {
    const snareEnv = Math.exp(-18*beatPhase);
    s += (noise()*.68 + osc(180,t)*.18) * snareEnv * .20 * drumGain;
  }
  const hatEnv = Math.exp(-28*eighthPhase);
  s += noise() * hatEnv * (eighth % 2 ? .055 : .038) * drumGain;

  // Gentle fade at both ends to make replay less abrupt.
  const fade = Math.min(1, t/2.2, (seconds-t)/2.2);
  const sample = Math.max(-1,Math.min(1,soft(s)*fade));
  pcm.writeInt16LE(Math.round(sample*32767),i*2);
}

const header = Buffer.alloc(44);
header.write('RIFF',0); header.writeUInt32LE(36+pcm.length,4); header.write('WAVE',8);
header.write('fmt ',12); header.writeUInt32LE(16,16); header.writeUInt16LE(1,20);
header.writeUInt16LE(1,22); header.writeUInt32LE(rate,24); header.writeUInt32LE(rate*2,28);
header.writeUInt16LE(2,32); header.writeUInt16LE(16,34);
header.write('data',36); header.writeUInt32LE(pcm.length,40);
const out = path.join(__dirname,'..','audio','terracast_garden_groove.wav');
fs.writeFileSync(out,Buffer.concat([header,pcm]));
console.log(`${out}: ${seconds}s, ${(pcm.length/1048576).toFixed(1)} MiB`);
