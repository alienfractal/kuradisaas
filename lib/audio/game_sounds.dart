class GameSounds {
  static const logo = 'resources/sound/alien_retro_logo_mfx.ogg';
  static const lore = 'resources/sound/alien_retro_intro.ogg';
  static const jump = 'resources/sound/sfx_jaan_jump_1.wav';
  static const walk = 'resources/sound/sfx_kurat_jaan_walk.ogg';
  // .467s recording -> ~.36s, two footfalls per .72s walking sprite cycle.
  static const walkPlaybackRate = 1.3;
  static const attack = 'resources/sound/blockHit1.mp3';
  static const impact = 'resources/sound/blockHit2.mp3';
  static const hurt = 'resources/sound/blockHit3.mp3';
  static const effects = [jump, attack, impact, hurt];
}
