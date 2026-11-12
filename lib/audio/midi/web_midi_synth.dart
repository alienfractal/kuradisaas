import 'dart:js_interop';
import 'midi_note.dart';
import 'midi_synth.dart';

@JS('KuradiMidi.createSynth')
external _BrowserSynth _createSynth();

extension type _BrowserSynth(JSObject _) implements JSObject {
  external void unlock();
  external void play(int channel, int program, int note, int velocity,
      double duration, double delay, bool walking);
  external void stopWalking();
  external void stopEffects();
  external void setVolume(double volume);
  external void dispose();
}

/// A tiny interop boundary. The JS object owns one browser AudioContext.
class WebMidiSynth implements MidiSynth {
  final _BrowserSynth _synth = _createSynth();
  @override
  void unlock() => _synth.unlock();
  @override
  void play(MidiNote note, {bool walking = false}) => _synth.play(
      note.channel,
      note.program,
      note.note,
      note.velocity,
      note.duration.inMicroseconds / 1000000,
      note.delay.inMicroseconds / 1000000,
      walking);
  @override
  void stopWalking() => _synth.stopWalking();
  @override
  void stopEffects() => _synth.stopEffects();
  @override
  void setVolume(double volume) => _synth.setVolume(volume);
  @override
  void dispose() => _synth.dispose();
}
