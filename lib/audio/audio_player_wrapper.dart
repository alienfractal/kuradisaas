/// Internal recording transport. Game code uses the typed GameAudioBackend.
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
