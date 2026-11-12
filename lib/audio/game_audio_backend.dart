/// Semantic game requests. Asset paths and MIDI details stay in the renderers.
enum SoundCue { jump, attack, impact, hurt }

enum MusicCue { logo, lore }

enum EffectsMode { mp3, midi }

abstract interface class GameAudioBackend {
  EffectsMode get effectsMode;
  Set<EffectsMode> get supportedEffectsModes;
  Future<void> setEffectsMode(EffectsMode mode);
  Future<void> preload();
  void playEffect(SoundCue cue);
  Future<void> playMusic(MusicCue cue, {bool loop = false});
  Future<void> stopMusic();
  void startWalking();
  void stopWalking();
  Future<void> stopEffects();
  Future<void> setEffectsVolume(double volume);
  Future<void> setMusicVolume(double volume);
  void notifyUserGesture();
  Future<void> dispose();
}

/// Explicit headless dependency; production selects its platform renderer.
class SilentAudioBackend implements GameAudioBackend {
  @override
  EffectsMode effectsMode = EffectsMode.midi;
  @override
  Set<EffectsMode> get supportedEffectsModes => EffectsMode.values.toSet();
  @override
  Future<void> setEffectsMode(EffectsMode mode) async => effectsMode = mode;
  @override
  Future<void> preload() async {}
  @override
  void playEffect(SoundCue cue) {}
  @override
  Future<void> playMusic(MusicCue cue, {bool loop = false}) async {}
  @override
  Future<void> stopMusic() async {}
  @override
  void startWalking() {}
  @override
  void stopWalking() {}
  @override
  Future<void> stopEffects() async {}
  @override
  Future<void> setEffectsVolume(double volume) async {}
  @override
  Future<void> setMusicVolume(double volume) async {}
  @override
  void notifyUserGesture() {}
  @override
  Future<void> dispose() async {}
}
