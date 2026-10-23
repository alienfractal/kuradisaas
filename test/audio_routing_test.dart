import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/audio/audio_player_wrapper.dart';
import 'package:kuradi_saased/audio/game_audio_service.dart';
import 'package:kuradi_saased/audio/game_sounds.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';
import 'package:kuradi_saased/game/states/arena/services/combat_logic_service.dart';
import 'package:kuradi_saased/game/states/arena/services/input_service.dart';
import 'package:kuradi_saased/gamefsm/game_menu_fsm.dart';
import 'package:kuradi_saased/kuradi_saased.dart';

class RecordingAudio extends SilentAudioPlayer {
  final effects = <String>[];
  final music = <(String, bool)>[];
  final walking = <String>[];
  List<String> preloaded = [];
  int musicStops = 0, walkStops = 0, sfxStops = 0, disposals = 0;
  @override
  Future<void> initSfxPool(List<String> paths) async {
    preloaded = paths;
  }

  @override
  void playSoundFx(String path) => effects.add(path);
  @override
  Future<void> playMusic(String path, {bool loop = false}) async {
    music.add((path, loop));
  }

  @override
  Future<void> playWalking(String path) async {
    walking.add(path);
  }

  @override
  Future<void> stopMusic() async {
    musicStops++;
  }

  @override
  Future<void> stopWalking() async {
    walkStops++;
  }

  @override
  Future<void> stopSfx() async {
    sfxStops++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RecordingAudio backend;
  late GameAudioService audio;
  late CombatLogicService combat;
  late InputService input;
  void advance(double seconds) {
    for (var i = 0; i < (seconds * 120).ceil(); i++) {
      combat.update(1 / 120, input);
      audio.handleStep(combat);
    }
  }

  setUp(() {
    backend = RecordingAudio();
    audio = GameAudioService(backend);
    combat = CombatLogicService(enemyCount: 1);
    input = InputService();
    combat.enemies.first
      ..x = 600
      ..y = combat.config.minY;
    audio.beginLevel(combat);
  });

  test(
      'jump sound follows accepted takeoff, not rejected input or air steering',
      () {
    input.jump();
    advance(.1);
    expect(backend.effects, [GameSounds.jump]);
    input.jump();
    advance(.1);
    expect(backend.effects, [GameSounds.jump]);
    advance(.5);
    input.jump();
    advance(.01);
    expect(backend.effects, [GameSounds.jump, GameSounds.jump]);
  });

  test('walking has one loop and stops on idle, boundary, attack or takeoff',
      () {
    input.keyboard.add('right');
    advance(.3);
    expect(backend.walking, [GameSounds.walk]);
    input.keyboard.clear();
    advance(.01);
    expect(backend.walkStops, 1);
    input.keyboard.add('right');
    advance(.02);
    input.jump();
    advance(.01);
    expect(backend.walkStops, 2);
    expect(backend.walking, hasLength(2));
    advance(.7);
    expect(backend.walking, hasLength(3));
    input.punch();
    advance(.01);
    expect(backend.walkStops, 3);
    advance(.5);
    combat.player.x = combat.config.maxX;
    advance(.02);
    final count = backend.walking.length;
    advance(.3);
    expect(backend.walking.length, count);
  });

  test('attack, contact and incoming hurt use separate once-per-event sounds',
      () {
    final target = combat.enemies.first
      ..x = 103
      ..y = combat.player.y;
    input.punch();
    advance(.05);
    expect(backend.effects, [GameSounds.attack]);
    advance(.12);
    expect(backend.effects, [GameSounds.attack, GameSounds.impact]);
    advance(.15);
    expect(backend.effects.where((e) => e == GameSounds.impact), hasLength(1));
    target
      ..x = combat.player.x + 10
      ..facing = -1
      ..beginAttack()
      ..enter(FighterState.active);
    advance(.01);
    expect(backend.effects.last, GameSounds.hurt);
    input.punch();
    advance(.01);
    expect(backend.effects.where((e) => e == GameSounds.attack), hasLength(1));
  });

  test(
      'missed attacks play swing only and expired buffered attacks stay silent',
      () {
    input.kick();
    advance(.1);
    input.punch();
    advance(.5);
    expect(backend.effects, [GameSounds.attack]);
    advance(.2);
    expect(backend.effects, [GameSounds.attack]);
  });

  test('leaving Lore cancels its loop and suspension silences current activity',
      () {
    audio.enterMenu(MenuState.intro);
    audio.enterMenu(MenuState.logo);
    audio.enterMenu(MenuState.main);
    expect(backend.music, [(GameSounds.logo, false)]);
    audio.enterMenu(MenuState.lore);
    expect(backend.music.last, (GameSounds.lore, true));
    audio.enterMenu(MenuState.main);
    expect(backend.musicStops, 1);
    input.keyboard.add('right');
    advance(.02);
    audio.suspend();
    expect(backend.walkStops, 1);
    input.jump();
    advance(.1);
    expect(backend.effects, isEmpty);
    expect(backend.sfxStops, 1);
  });

  test('game root routes menu music, takeoff and teardown through the adapter',
      () async {
    final game = KuradiSaased(audioPlayer: backend);
    game.onGameResize(Vector2(1024, 512));
    // ignore: invalid_use_of_internal_member
    await game.load();
    // ignore: invalid_use_of_internal_member
    game.mount();
    await game.ready();
    expect(backend.preloaded, GameSounds.effects);
    expect(backend.music, [(GameSounds.logo, false)]);
    game.handleIntroInput();
    game.update(GameMenuFsm.logoDuration);
    await game.ready();
    game.showLore();
    await game.ready();
    expect(backend.music.last, (GameSounds.lore, true));
    game.closeLore();
    await game.ready();
    await game.startGame();
    await game.ready();
    game.input.jump();
    game.update(.05);
    expect(backend.effects, contains(GameSounds.jump));
    game.togglePause();
    expect(backend.sfxStops, greaterThan(0));
    game.removeAll(game.children.toList());
    await game.ready();
    game.onDispose();
    expect(backend.disposals, 1);
  });
}
