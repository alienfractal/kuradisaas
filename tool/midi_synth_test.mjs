import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';

function test(name, run) {
  run();
  console.log(`PASS: ${name}`);
}

const script = readFileSync(new URL('../web/midi_synth.js', import.meta.url), 'utf8');
class Param {
  setValueAtTime() {}
  linearRampToValueAtTime() {}
  exponentialRampToValueAtTime() {}
  cancelScheduledValues() {}
}
class Node {
  gain = new Param();
  frequency = new Param();
  stops = 0;
  disconnected = false;
  connect() {}
  disconnect() { this.disconnected = true; }
  start() {}
  stop() { this.stops++; }
}
function setup() {
  const contexts = [];
  class Context {
    state = 'suspended';
    currentTime = 0;
    destination = {};
    sources = [];
    closed = 0;
    constructor() { contexts.push(this); }
    createGain() { return new Node(); }
    createOscillator() {
      const source = new Node();
      this.sources.push(source);
      return source;
    }
    async resume() { this.state = 'running'; }
    async close() { this.closed++; this.state = 'closed'; }
  }
  const sandbox = {AudioContext: Context, console};
  vm.runInNewContext(script, sandbox);
  return {synth: sandbox.KuradiMidi.createSynth(), contexts};
}
const note = (synth, walking = false, delay = 0) =>
  synth.play(0, 80, 60, 90, .1, delay, walking);

test('no context before gesture; pre-unlock and suspended notes are dropped', () => {
  const {synth, contexts} = setup();
  note(synth);
  assert.equal(contexts.length, 0);
  synth.unlock();
  assert.equal(contexts.length, 1);
  assert.equal(synth.voices.size, 0);
  note(synth);
  assert.equal(synth.voices.size, 1);
  contexts[0].state = 'suspended';
  note(synth);
  assert.equal(synth.voices.size, 1);
  synth.unlock();
  assert.equal(contexts.length, 1);
  synth.dispose();
});

test('stopping walking preserves impacts; stop cancels future notes too', () => {
  const {synth, contexts} = setup();
  synth.unlock();
  note(synth, true);
  note(synth, false, .5);
  synth.stopWalking();
  assert.equal(synth.voices.size, 1);
  assert.equal(contexts[0].sources[0].disconnected, true);
  assert.equal(contexts[0].sources[1].disconnected, false);
  synth.stopEffects();
  assert.equal(synth.voices.size, 0);
  assert.equal(contexts[0].sources[1].disconnected, true);
  synth.dispose();
});

test('mute releases all voices; unmute never replays old cues', () => {
  const {synth, contexts} = setup();
  synth.unlock();
  note(synth, true);
  note(synth, false, .5);
  synth.setVolume(0);
  assert.equal(synth.voices.size, 0);
  note(synth);
  synth.setVolume(.5);
  assert.equal(contexts[0].sources.length, 2);
  assert.equal(synth.voices.size, 0);
  synth.dispose();
});

test('rapid cues bound polyphony; natural note-off and teardown release nodes', () => {
  const {synth, contexts} = setup();
  synth.unlock();
  for (let i = 0; i < 100; i++) note(synth);
  assert.equal(synth.voices.size, 24);
  assert.equal(contexts[0].sources.filter(n => n.disconnected).length, 76);
  contexts[0].sources.at(-1).onended();
  assert.equal(synth.voices.size, 23);
  synth.dispose();
  synth.dispose();
  synth.unlock();
  note(synth);
  assert.equal(synth.voices.size, 0);
  assert.equal(contexts[0].closed, 1);
  assert.equal(contexts.length, 1);
  assert.ok(contexts[0].sources.every(n => n.disconnected));
});

test('game instances own separate contexts; invalid MIDI is rejected', () => {
  const {synth: first} = setup();
  const {synth: second} = setup();
  first.unlock(); second.unlock();
  note(first); note(second);
  first.dispose();
  assert.equal(second.voices.size, 1);
  assert.throws(() => second.play(16, 80, 60, 90, .1, 0, false), /Invalid MIDI/);
  assert.throws(() => second.play(0, 80, 60, 0, .1, 0, false), /Invalid MIDI/);
  assert.throws(() => second.play(0, 80, 60, 90, 0, 0, false), /Invalid MIDI/);
  assert.throws(() => second.setVolume(NaN), /Invalid MIDI/);
  second.dispose();
});
