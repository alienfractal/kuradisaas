/// Game-instance settings survive level and view replacement.
class GameSettings {
  static const volumeLevels = [1.0, 2 / 3, 1 / 3, 0.0];
  int effectsIndex = 0;
  int musicIndex = 2;
  bool crtEnabled = false;
  double get effectsVolume => volumeLevels[effectsIndex];
  double get musicVolume => volumeLevels[musicIndex];
  void cycleEffects() =>
      effectsIndex = (effectsIndex + 1) % volumeLevels.length;
  void cycleMusic() => musicIndex = (musicIndex + 1) % volumeLevels.length;
}
