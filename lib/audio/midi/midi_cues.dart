import '../game_audio_backend.dart';
import 'midi_note.dart';

/// Authored one-shot phrases. The browser synth implements these GM slots.
class MidiCues {
  static final _jump = List<MidiNote>.unmodifiable([
    MidiNote(note: 60, program: 80, velocity: 75),
    MidiNote(
        note: 72,
        program: 80,
        velocity: 65,
        delay: const Duration(milliseconds: 55),
        duration: const Duration(milliseconds: 120)),
  ]);
  static final _attack = List<MidiNote>.unmodifiable([
    MidiNote(
        note: 55,
        program: 81,
        velocity: 65,
        duration: const Duration(milliseconds: 55)),
    MidiNote(
        note: 43,
        program: 81,
        velocity: 50,
        delay: const Duration(milliseconds: 25),
        duration: const Duration(milliseconds: 55)),
  ]);
  static final _impact = List<MidiNote>.unmodifiable([
    MidiNote(note: 36, channel: 9, program: 0, velocity: 110),
    MidiNote(
        note: 38,
        channel: 9,
        program: 0,
        velocity: 80,
        duration: const Duration(milliseconds: 70)),
  ]);
  static final _hurt = List<MidiNote>.unmodifiable([
    MidiNote(note: 48, program: 81, velocity: 95),
    MidiNote(
        note: 36,
        program: 81,
        velocity: 85,
        delay: const Duration(milliseconds: 65),
        duration: const Duration(milliseconds: 160)),
  ]);
  static final footstep = MidiNote(
      note: 76,
      channel: 9,
      program: 0,
      velocity: 45,
      duration: const Duration(milliseconds: 45));

  static List<MidiNote> forCue(SoundCue cue) => switch (cue) {
        SoundCue.jump => _jump,
        SoundCue.attack => _attack,
        SoundCue.impact => _impact,
        SoundCue.hurt => _hurt,
      };
}
