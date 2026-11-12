import 'package:flutter/foundation.dart';

import 'audio_player_wrapper.dart';
import 'effects_backend.dart';
import 'game_audio_backend.dart';
import 'game_audio_player.dart';
import 'game_sounds.dart';
import 'selectable_effects.dart';
import 'platform_effects_native.dart'
    if (dart.library.js_interop) 'platform_effects_web.dart' as platform;

GameAudioBackend createGameAudio() {
  final recordings = GameAudioPlayer(useAudioPools: !kIsWeb);
  return PlatformGameAudio(recordings, platform.createEffects(recordings));
}

/// Music recordings and platform effects share a lifecycle, not a renderer.
class PlatformGameAudio implements GameAudioBackend {
  PlatformGameAudio(this._recordings, Map<EffectsMode, EffectsBackend> effects)
      : _effects = SelectableEffects(effects);
  final AudioPlayerWrapper _recordings;
  final SelectableEffects _effects;
  bool _disposed = false;

  @override
  EffectsMode get effectsMode => _effects.mode;
  @override
  Set<EffectsMode> get supportedEffectsModes => _effects.supportedModes;
  @override
  Future<void> setEffectsMode(EffectsMode mode) => _effects.select(mode);

  @override
  Future<void> preload() => _effects.preload();
  @override
  void playEffect(SoundCue cue) {
    if (!_disposed) _effects.play(cue);
  }

  @override
  Future<void> playMusic(MusicCue cue, {bool loop = false}) => _disposed
      ? Future.value()
      : _recordings.playMusic(
          switch (cue) {
            MusicCue.logo => GameSounds.logo,
            MusicCue.lore => GameSounds.lore,
          },
          loop: loop);
  @override
  Future<void> stopMusic() => _recordings.stopMusic();
  @override
  void startWalking() {
    if (!_disposed) _effects.startWalking();
  }

  @override
  void stopWalking() => _effects.stopWalking();
  @override
  Future<void> stopEffects() => _effects.stop();
  @override
  Future<void> setEffectsVolume(double volume) => _effects.setVolume(volume);
  @override
  Future<void> setMusicVolume(double volume) =>
      _recordings.setMusicVolume(volume);
  @override
  void notifyUserGesture() {
    if (_disposed) return;
    _recordings.notifyUserGesture();
    _effects.notifyUserGesture();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _effects.dispose();
    } finally {
      await _recordings.dispose();
    }
  }
}
