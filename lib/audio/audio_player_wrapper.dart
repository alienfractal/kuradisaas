abstract class AudioPlayerWrapper {
  Future<void> initSfxPool(List<String> paths);
  void playSoundFx(String path);
  Future<void> playMusic(String path, {bool loop = false});
  Future<void> stopMusic();
  Future<void> playWalking(String path);
  Future<void> stopWalking();
  Future<void> stopSfx();
  Future<void> setSoundFxVolume(double volume);
  Future<void> setMusicVolume(double volume);
  void notifyUserGesture();
  Future<void> dispose();
}

/// Explicitly injected by headless game tests; production uses GameAudioPlayer.
class SilentAudioPlayer implements AudioPlayerWrapper {
  @override
  Future<void> initSfxPool(List<String> paths) async {}
  @override
  void playSoundFx(String path) {}
  @override
  Future<void> playMusic(String path, {bool loop = false}) async {}
  @override
  Future<void> stopMusic() async {}
  @override
  Future<void> playWalking(String path) async {}
  @override
  Future<void> stopWalking() async {}
  @override
  Future<void> stopSfx() async {}
  @override
  void notifyUserGesture() {}
  @override
  Future<void> setSoundFxVolume(double volume) async {}
  @override
  Future<void> setMusicVolume(double volume) async {}
  @override
  Future<void> dispose() async {}
}
