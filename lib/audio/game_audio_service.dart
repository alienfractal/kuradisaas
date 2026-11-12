import 'dart:async';
import '../game/states/arena/model/combat_event.dart';
import '../game/states/arena/model/fighter_model.dart';
import '../game/states/arena/services/combat_logic_service.dart';
import '../gamefsm/game_menu_fsm.dart';
import 'game_audio_backend.dart';

/// Routes model facts to sound. Playback never changes combat or menu state.
class GameAudioService {
  GameAudioService(this._player);
  final GameAudioBackend _player;
  EffectsMode get effectsMode => _player.effectsMode;
  Set<EffectsMode> get supportedEffectsModes => _player.supportedEffectsModes;
  Future<void> setEffectsMode(EffectsMode mode) => _player.setEffectsMode(mode);
  bool _walking = false;
  bool _inLore = false;
  bool _suspended = false;
  bool _disposed = false;
  double _x = 0, _y = 0;

  Future<void> setVolumes({required double effects, required double music}) =>
      Future.wait(
          [_player.setEffectsVolume(effects), _player.setMusicVolume(music)]);

  Future<void> setEffectsVolume(double volume) =>
      _player.setEffectsVolume(volume);
  Future<void> setMusicVolume(double volume) => _player.setMusicVolume(volume);

  Future<void> preload() => _player.preload();
  void notifyUserGesture() {
    if (!_disposed) _player.notifyUserGesture();
  }

  void enterMenu(MenuState state) {
    if (_disposed) return;
    _suspended = false;
    stopWalking();
    if (state == MenuState.intro) {
      unawaited(_player.playMusic(MusicCue.logo));
    } else if (state == MenuState.lore) {
      _inLore = true;
      unawaited(_player.playMusic(MusicCue.lore, loop: true));
    } else if (_inLore) {
      _inLore = false;
      unawaited(_player.stopMusic());
    }
    // The startup sting may finish naturally on the main menu.
  }

  void beginLevel(CombatLogicService combat) {
    _x = combat.player.x;
    _y = combat.player.y;
    _suspended = false;
  }

  void leaveScreen() {
    _inLore = false;
    stopWalking();
    unawaited(_player.stopMusic());
    unawaited(_player.stopEffects());
  }

  void suspend() {
    _suspended = true;
    stopWalking();
    unawaited(_player.stopMusic());
    unawaited(_player.stopEffects());
  }

  void resumeMenu(MenuState state) {
    _suspended = false;
    if (state == MenuState.lore) enterMenu(state);
  }

  void handleStep(CombatLogicService combat) {
    if (_disposed || _suspended) return;
    for (final event in combat.events) {
      switch (event.type) {
        case CombatEventType.jumpStarted:
          _player.playEffect(SoundCue.jump);
        case CombatEventType.attackStarted:
          _player.playEffect(SoundCue.attack);
        case CombatEventType.hitLanded:
          _player.playEffect(event.targetId == combat.player.id
              ? SoundCue.hurt
              : SoundCue.impact);
      }
    }
    final jaan = combat.player;
    final moved = jaan.x != _x || jaan.y != _y;
    final walking = jaan.alive &&
        !combat.won &&
        !jaan.airborne &&
        jaan.state == FighterState.walking &&
        moved;
    _x = jaan.x;
    _y = jaan.y;
    if (walking && !_walking) {
      _walking = true;
      _player.startWalking();
    } else if (!walking) {
      stopWalking();
    }
  }

  void stopWalking() {
    if (!_walking) return;
    _walking = false;
    _player.stopWalking();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _player.dispose();
  }
}
