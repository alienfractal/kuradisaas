import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/audio/effects_backend.dart';
import 'package:kuradi_saased/audio/game_audio_backend.dart';
import 'package:kuradi_saased/audio/selectable_effects.dart';

class TestEffects implements EffectsBackend {
  final cues = <SoundCue>[];
  final volumes = <double>[];
  int walkStarts = 0, stops = 0, disposals = 0;
  Completer<void>? preparing;
  bool fail = false;
  @override
  Future<void> preload() async {
    if (fail) throw StateError('unavailable');
    await preparing?.future;
  }

  @override
  void play(SoundCue cue) => cues.add(cue);
  @override
  void startWalking() => walkStarts++;
  @override
  void stopWalking() {}
  @override
  Future<void> stop() async => stops++;
  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);
  @override
  void notifyUserGesture() {}
  @override
  Future<void> dispose() async => disposals++;
}

void main() {
  late TestEffects midi, mp3;
  late SelectableEffects effects;
  setUp(() {
    midi = TestEffects();
    mp3 = TestEffects();
    effects = SelectableEffects({EffectsMode.midi: midi, EffectsMode.mp3: mp3});
  });

  test(
      'switch releases old voices, transfers volume and walking, drops old hits',
      () async {
    await effects.setVolume(.3);
    effects.startWalking();
    effects.play(SoundCue.jump);
    final change = effects.select(EffectsMode.mp3);
    effects.play(SoundCue.impact);
    await change;
    effects.play(SoundCue.attack);
    expect(midi.stops, 1);
    expect(midi.cues, [SoundCue.jump]);
    expect(mp3.cues, [SoundCue.attack]);
    expect(mp3.volumes.last, .3);
    expect(mp3.walkStarts, 1);
    expect(effects.mode, EffectsMode.mp3);
    await effects.dispose();
  });

  test('pause and volume changes during selection cannot restart walking',
      () async {
    effects.startWalking();
    mp3.preparing = Completer();
    final change = effects.select(EffectsMode.mp3);
    await Future<void>.delayed(Duration.zero);
    await effects.stop();
    await effects.setVolume(0);
    mp3.preparing!.complete();
    await change;
    expect(mp3.walkStarts, 0);
    expect(mp3.volumes.last, 0);
    await effects.dispose();
  });

  test('rapid selection activates only the final requested renderer', () async {
    effects.startWalking();
    mp3.preparing = Completer();
    final first = effects.select(EffectsMode.mp3);
    await Future<void>.delayed(Duration.zero);
    final second = effects.select(EffectsMode.midi);
    mp3.preparing!.complete();
    await Future.wait([first, second]);
    expect(mp3.walkStarts, 0);
    effects.play(SoundCue.hurt);
    expect(midi.cues, [SoundCue.hurt]);
    expect(effects.mode, EffectsMode.midi);
    await effects.dispose();
  });

  test('late preparation cannot reactivate a disposed backend', () async {
    effects.startWalking();
    mp3.preparing = Completer();
    final change = effects.select(EffectsMode.mp3);
    await Future<void>.delayed(Duration.zero);
    await effects.dispose();
    mp3.preparing!.complete();
    await change;
    await effects.dispose();
    effects.startWalking();
    effects.play(SoundCue.jump);
    expect(mp3.walkStarts, 0);
    expect(mp3.cues, isEmpty);
    expect(midi.disposals, 1);
    expect(mp3.disposals, 1);
  });

  test('failed selection preserves working mode and permits a later retry',
      () async {
    mp3.fail = true;
    await expectLater(effects.select(EffectsMode.mp3), throwsStateError);
    expect(effects.mode, EffectsMode.midi);
    effects.play(SoundCue.jump);
    expect(midi.cues, [SoundCue.jump]);
    mp3.fail = false;
    await effects.select(EffectsMode.mp3);
    effects.play(SoundCue.hurt);
    expect(mp3.cues, [SoundCue.hurt]);
    await effects.dispose();
  });
}
