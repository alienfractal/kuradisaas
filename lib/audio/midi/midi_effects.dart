import 'dart:async';
import '../effects_backend.dart';
import '../game_audio_backend.dart';
import 'midi_cues.dart';
import 'midi_synth.dart';

/// Game-lifetime MIDI effects. No asynchronous cue loads or stale effect queue.
class MidiEffects implements EffectsBackend {
  MidiEffects(this._synth);
  final MidiSynth _synth;
  Timer? _steps;
  bool _disposed = false;
  double _volume = 1;

  @override
  Future<void> preload() async {} // Patches are code, not decoded assets.

  @override
  void play(SoundCue cue) {
    if (_disposed || _volume == 0) return;
    for (final note in MidiCues.forCue(cue)) {
      _synth.play(note);
    }
  }

  @override
  void startWalking() {
    if (_disposed || _steps != null) return;
    _step();
    // Two footfalls per .72s walk cycle, matching the recorded 1.3x loop.
    _steps = Timer.periodic(const Duration(milliseconds: 360), (_) => _step());
  }

  void _step() {
    if (!_disposed && _volume > 0) {
      _synth.play(MidiCues.footstep, walking: true);
    }
  }

  @override
  void stopWalking() {
    _steps?.cancel();
    _steps = null;
    _synth.stopWalking();
  }

  @override
  Future<void> stop() async {
    stopWalking();
    _synth.stopEffects();
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    if (!volume.isFinite) throw ArgumentError.value(volume, 'volume');
    _volume = volume.clamp(0.0, 1.0);
    _synth.stopEffects();
    _synth.setVolume(_volume);
  }

  @override
  void notifyUserGesture() {
    if (!_disposed) _synth.unlock();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    _synth.dispose();
  }
}
