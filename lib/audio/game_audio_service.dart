import 'dart:async';
import '../game/states/arena/model/combat_event.dart';
import '../game/states/arena/model/fighter_model.dart';
import '../game/states/arena/services/combat_logic_service.dart';
import '../gamefsm/game_menu_fsm.dart';
import 'audio_player_wrapper.dart';
import 'game_sounds.dart';

/// Routes model facts to sound. Playback never changes combat or menu state.
class GameAudioService {
  GameAudioService(this.player);
  final AudioPlayerWrapper player;
  bool _walking = false;
  bool _inLore = false;
  bool _suspended = false;
  bool _disposed = false;
  double _x = 0, _y = 0;

  Future<void> setVolumes({required double effects, required double music}) =>
      Future.wait(
          [player.setSoundFxVolume(effects), player.setMusicVolume(music)]);

  Future<void> preload() => player.initSfxPool(GameSounds.effects);
  void notifyUserGesture() {
    if (!_disposed) player.notifyUserGesture();
  }

  void enterMenu(MenuState state) {
    if (_disposed) return;
    _suspended = false;
    stopWalking();
    if (state == MenuState.intro) {
      unawaited(player.playMusic(GameSounds.logo));
    } else if (state == MenuState.lore) {
      _inLore = true;
      unawaited(player.playMusic(GameSounds.lore, loop: true));
    } else if (_inLore) {
      _inLore = false;
      unawaited(player.stopMusic());
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
    unawaited(player.stopMusic());
    unawaited(player.stopSfx());
  }

  void suspend() {
    _suspended = true;
    stopWalking();
    unawaited(player.stopMusic());
    unawaited(player.stopSfx());
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
          player.playSoundFx(GameSounds.jump);
        case CombatEventType.attackStarted:
          player.playSoundFx(GameSounds.attack);
        case CombatEventType.hitLanded:
          player.playSoundFx(event.targetId == combat.player.id
              ? GameSounds.hurt
              : GameSounds.impact);
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
      unawaited(player.playWalking(GameSounds.walk));
    } else if (!walking) {
      stopWalking();
    }
  }

  void stopWalking() {
    if (!_walking) return;
    _walking = false;
    unawaited(player.stopWalking());
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await player.dispose();
  }
}
