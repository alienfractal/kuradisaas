import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/audio/audio_player_wrapper.dart';
import 'package:kuradi_saased/audio/game_audio_backend.dart';
import 'package:kuradi_saased/audio/game_sounds.dart';
import 'package:kuradi_saased/audio/midi/midi_effects.dart';
import 'package:kuradi_saased/audio/platform_game_audio.dart';
import 'midi_effects_test.dart' show RecordingSynth;

class RecordingTransport implements AudioPlayerWrapper {
  final music = <String>[];
  int disposals = 0, effectAccesses = 0;
  @override
  Future<void> playMusic(String path, {bool loop = false}) async =>
      music.add(path);
  @override
  Future<void> initSfxPool(List<String> paths) async => effectAccesses++;
  @override
  void playSoundFx(String path) => effectAccesses++;
  @override
  Future<void> playWalking(String path) async => effectAccesses++;
  @override
  Future<void> stopWalking() async => effectAccesses++;
  @override
  Future<void> stopSfx() async => effectAccesses++;
  @override
  Future<void> setSoundFxVolume(double volume) async => effectAccesses++;
  @override
  Future<void> stopMusic() async {}
  @override
  Future<void> setMusicVolume(double volume) async {}
  @override
  void notifyUserGesture() {}
  @override
  Future<void> dispose() async => disposals++;
}

void main() {
  test('MIDI composition never loads or plays recorded SFX, even on teardown',
      () async {
    final recordings = RecordingTransport();
    final synth = RecordingSynth();
    final audio =
        PlatformGameAudio(recordings, {EffectsMode.midi: MidiEffects(synth)});
    await audio.preload();
    await audio.setEffectsVolume(.5);
    audio.notifyUserGesture();
    for (final cue in SoundCue.values) {
      audio.playEffect(cue);
    }
    audio.startWalking();
    audio.stopWalking();
    await audio.stopEffects();
    await audio.playMusic(MusicCue.logo);
    await audio.playMusic(MusicCue.lore, loop: true);
    await audio.dispose();
    await audio.dispose();
    expect(recordings.effectAccesses, 0);
    expect(recordings.music, [GameSounds.logo, GameSounds.lore]);
    expect(synth.notes, isNotEmpty);
    expect(synth.disposals, 1);
    expect(recordings.disposals, 1);
  });
}
