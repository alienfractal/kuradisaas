import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/audio/game_audio_backend.dart';
import 'package:kuradi_saased/audio/midi/midi_cues.dart';
import 'package:kuradi_saased/audio/midi/midi_effects.dart';
import 'package:kuradi_saased/audio/midi/midi_note.dart';
import 'package:kuradi_saased/audio/midi/midi_synth.dart';

class RecordingSynth implements MidiSynth {
  final notes = <(MidiNote, bool)>[];
  int walkingStops = 0, effectStops = 0, disposals = 0, unlocks = 0;
  double volume = 1;
  @override
  void play(MidiNote note, {bool walking = false}) =>
      notes.add((note, walking));
  @override
  void unlock() => unlocks++;
  @override
  void stopWalking() => walkingStops++;
  @override
  void stopEffects() => effectStops++;
  @override
  void setVolume(double value) => volume = value;
  @override
  void dispose() => disposals++;
}

void main() {
  test('every effect has a bounded phrase on implemented MIDI patches', () {
    for (final cue in SoundCue.values) {
      final notes = MidiCues.forCue(cue);
      expect(notes, isNotEmpty);
      for (final note in notes) {
        if (note.channel == 9) {
          expect([36, 38, 76], contains(note.note));
        } else {
          expect([80, 81], contains(note.program));
        }
        expect(note.duration.inMilliseconds, inInclusiveRange(1, 2000));
      }
    }
  });

  test('MIDI data is validated in release builds too', () {
    expect(() => MidiNote(note: 128, program: 80), throwsRangeError);
    expect(() => MidiNote(note: 60, program: -1), throwsRangeError);
    expect(
        () => MidiNote(note: 60, program: 80, channel: 16), throwsRangeError);
    expect(
        () => MidiNote(note: 60, program: 80, velocity: 0), throwsRangeError);
    expect(() => MidiNote(note: 60, program: 80, duration: Duration.zero),
        throwsRangeError);
    expect(
        () =>
            MidiNote(note: 60, program: 80, delay: const Duration(seconds: 2)),
        throwsRangeError);
  });

  testWidgets('walking has one timer, independent stops, and no late footsteps',
      (tester) async {
    final synth = RecordingSynth();
    final effects = MidiEffects(synth);
    effects.startWalking();
    effects.startWalking();
    expect(synth.notes, hasLength(1));
    await tester.pump(const Duration(milliseconds: 720));
    expect(synth.notes, hasLength(3));
    effects.play(SoundCue.impact);
    effects.stopWalking();
    expect(synth.walkingStops, 1);
    expect(synth.effectStops, 0);
    final count = synth.notes.length;
    await tester.pump(const Duration(seconds: 2));
    expect(synth.notes, hasLength(count));
    await effects.dispose();
  });

  testWidgets('mute drops cues; unmute continues current walking only',
      (tester) async {
    final synth = RecordingSynth();
    final effects = MidiEffects(synth);
    effects.startWalking();
    await effects.setVolume(0);
    effects.play(SoundCue.jump);
    await tester.pump(const Duration(seconds: 1));
    expect(synth.notes, hasLength(1));
    expect(synth.effectStops, 1);
    await effects.setVolume(.4);
    await tester.pump(const Duration(milliseconds: 360));
    expect(synth.notes.last.$2, isTrue);
    expect(synth.volume, .4);
    expect(synth.notes, hasLength(2));
    await effects.dispose();
  });

  testWidgets('suspension and disposal cancel timers and release voices',
      (tester) async {
    final synth = RecordingSynth();
    final effects = MidiEffects(synth);
    effects.notifyUserGesture();
    effects.startWalking();
    await effects.stop();
    final count = synth.notes.length;
    await tester.pump(const Duration(seconds: 1));
    expect(synth.notes, hasLength(count));
    expect(synth.effectStops, 1);
    effects.startWalking();
    await effects.dispose();
    await effects.dispose();
    effects.play(SoundCue.hurt);
    effects.startWalking();
    effects.notifyUserGesture();
    await tester.pump(const Duration(seconds: 2));
    expect(synth.notes, hasLength(count + 1));
    expect(synth.disposals, 1);
    expect(synth.unlocks, 1);
  });
}
