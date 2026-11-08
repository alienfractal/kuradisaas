import 'package:kuradi_saased/gen/assets.gen.dart';

class GameSounds {
  static final logo = Assets.resources.sound.alienRetroLogoMfx;
  static final lore = Assets.resources.sound.alienRetroIntro;
  static final jump = Assets.resources.sound.sfxJaanJump1;
  static final walk = Assets.resources.sound.sfxKuratJaanWalk;
  // .467s recording -> ~.36s, two footfalls per .72s walking sprite cycle.
  static const walkPlaybackRate = 1.3;
  static final attack = Assets.resources.sound.blockHit1;
  static final impact = Assets.resources.sound.blockHit2;
  static final hurt = Assets.resources.sound.blockHit3;
  static final effects = [jump, attack, impact, hurt];
}
