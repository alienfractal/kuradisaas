import 'game_audio_backend.dart';

/// One owner for effects, including the independent footstep voice.
abstract interface class EffectsBackend {
  Future<void> preload();
  void play(SoundCue cue);
  void startWalking();
  void stopWalking();
  Future<void> stop();
  Future<void> setVolume(double volume);
  void notifyUserGesture();
  Future<void> dispose();
}
