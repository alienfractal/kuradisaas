// Local MIDI event renderer. Original project code; no sound bank, samples,
// Web MIDI device permission, third-party library, or network request required.
// Implements GM programs 80/81 and channel-10 drums 36/38/76 used by MidiCues.
(() => {
  'use strict';
  class MidiSynth {
    constructor() {
      this.context = null;
      this.master = null;
      this.volume = 1;
      this.disposed = false;
      this.voices = new Set();
    }

    unlock() {
      if (this.disposed) return;
      try {
        if (!this.context) {
          const AudioContext = globalThis.AudioContext || globalThis.webkitAudioContext;
          if (!AudioContext) return;
          this.context = new AudioContext();
          this.master = this.context.createGain();
          this.master.gain.value = this.volume * 0.22;
          this.master.connect(this.context.destination);
        }
        // Call synchronously from the gesture. Never replay dropped one-shots.
        if (this.context.state === 'suspended') {
          this.context.resume().catch(() => {});
        }
      } catch (error) {
        console.warn('MIDI audio unavailable:', error);
      }
    }

    play(channel, program, note, velocity, duration, delay, walking) {
      const inRange = (n, low, high) => Number.isInteger(n) && n >= low && n <= high;
      if (!inRange(channel, 0, 15) || !inRange(program, 0, 127) ||
          !inRange(note, 0, 127) || !inRange(velocity, 1, 127) ||
          !Number.isFinite(duration) || duration <= 0 || duration > 2 ||
          !Number.isFinite(delay) || delay < 0 || delay > 1) {
        throw new RangeError('Invalid MIDI note');
      }
      if (this.disposed || !this.context || this.context.state !== 'running' ||
          this.volume === 0) return;
      // Unsupported patches stay silent instead of pretending to be a full GM bank.
      if (channel === 9 ? ![36, 38, 76].includes(note) : ![80, 81].includes(program)) return;
      if (this.voices.size >= 24) this.release(this.voices.values().next().value);
      const ctx = this.context;
      const start = ctx.currentTime + delay;
      const end = start + duration;
      const source = ctx.createOscillator();
      const gain = ctx.createGain();
      const percussion = channel === 9;
      source.type = percussion ? 'triangle' : (program === 80 ? 'square' : 'sawtooth');
      const frequency = percussion ? ({36: 140, 38: 310, 76: 850})[note]
        : 440 * Math.pow(2, (note - 69) / 12);
      source.frequency.setValueAtTime(frequency, start);
      if (percussion) source.frequency.exponentialRampToValueAtTime(frequency * 0.25, end);
      const peak = velocity / 127 * (walking ? 0.5 : 1);
      gain.gain.setValueAtTime(0, start);
      gain.gain.linearRampToValueAtTime(peak, start + Math.min(0.004, duration / 4));
      gain.gain.exponentialRampToValueAtTime(0.001, end);
      // Explicit note-off with a short release to avoid clicks.
      gain.gain.linearRampToValueAtTime(0, end + 0.012);
      source.connect(gain);
      gain.connect(this.master);
      const voice = {source, gain, walking};
      this.voices.add(voice);
      source.onended = () => this.release(voice, false);
      source.start(start);
      source.stop(end + 0.015);
    }

    release(voice, stop = true) {
      if (!this.voices.delete(voice)) return;
      voice.source.onended = null;
      if (stop) {
        // Silence immediately, including notes whose start is still in the future.
        voice.gain.gain.cancelScheduledValues(this.context.currentTime);
        voice.gain.gain.setValueAtTime(0, this.context.currentTime);
        voice.source.stop();
      }
      voice.source.disconnect();
      voice.gain.disconnect();
    }

    stopWalking() {
      for (const voice of this.voices) if (voice.walking) this.release(voice);
    }

    stopEffects() {
      for (const voice of this.voices) if (!voice.walking) this.release(voice);
    }

    setVolume(volume) {
      if (!Number.isFinite(volume)) throw new RangeError('Invalid MIDI volume');
      if (this.disposed) return;
      this.volume = Math.max(0, Math.min(1, volume));
      if (this.master) this.master.gain.setValueAtTime(this.volume * 0.22, this.context.currentTime);
      if (this.volume === 0) {
        this.stopWalking();
        this.stopEffects();
      }
    }

    dispose() {
      if (this.disposed) return;
      this.disposed = true;
      this.stopWalking();
      this.stopEffects();
      if (this.master) this.master.disconnect();
      if (this.context) this.context.close().catch(() => {});
    }
  }
  globalThis.KuradiMidi = Object.freeze({createSynth: () => new MidiSynth()});
})();
