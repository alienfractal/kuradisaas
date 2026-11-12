import 'dart:async';
import 'audio_player_wrapper.dart';
import 'effects_backend.dart';
import 'game_audio_backend.dart';
import 'game_sounds.dart';

/// Original MP3/WAV/OGG effects, selectable on web and retained on native.
class RecordedEffects implements EffectsBackend {
  RecordedEffects(this._player);
  final AudioPlayerWrapper _player;
  @override
  Future<void> preload() => _player.initSfxPool(GameSounds.effects);
  @override
  void play(SoundCue cue) => _player.playSoundFx(switch (cue) {
        SoundCue.jump => GameSounds.jump,
        SoundCue.attack => GameSounds.attack,
        SoundCue.impact => GameSounds.impact,
        SoundCue.hurt => GameSounds.hurt,
      });
  @override
  void startWalking() => unawaited(_player.playWalking(GameSounds.walk));
  @override
  void stopWalking() => unawaited(_player.stopWalking());
  @override
  Future<void> stop() async {
    await Future.wait([_player.stopWalking(), _player.stopSfx()]);
  }

  @override
  Future<void> setVolume(double volume) => _player.setSoundFxVolume(volume);
  @override
  void notifyUserGesture() {}
  @override
  Future<void> dispose() => stop();
}
