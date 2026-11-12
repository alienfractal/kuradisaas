import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/audio/game_audio_backend.dart';
import 'package:kuradi_saased/audio/game_audio_service.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';
import 'package:kuradi_saased/game/states/arena/services/combat_logic_service.dart';
import 'package:kuradi_saased/game/states/arena/services/input_service.dart';
import 'package:kuradi_saased/gamefsm/game_menu_fsm.dart';
import 'package:kuradi_saased/kuradi_saased.dart';

class RecordingAudio extends SilentAudioBackend {
  final effects = <SoundCue>[];
  final music = <(MusicCue, bool)>[];
  int walking = 0;
  bool preloaded = false;
  int musicStops = 0, walkStops = 0, sfxStops = 0, disposals = 0;
  @override
  Future<void> preload() async {
    preloaded = true;
  }

  @override
  void playEffect(SoundCue cue) => effects.add(cue);
  @override
  Future<void> playMusic(MusicCue cue, {bool loop = false}) async {
    music.add((cue, loop));
  }

  @override
  void startWalking() {
    walking++;
  }

  @override
  Future<void> stopMusic() async {
    musicStops++;
  }

  @override
  void stopWalking() {
    walkStops++;
  }

  @override
  Future<void> stopEffects() async {
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
    expect(backend.effects, [SoundCue.jump]);
    input.jump();
    advance(.1);
    expect(backend.effects, [SoundCue.jump]);
    advance(.5);
    input.jump();
    advance(.01);
    expect(backend.effects, [SoundCue.jump, SoundCue.jump]);
  });

  test('walking has one loop and stops on idle, boundary, attack or takeoff',
      () {
    input.keyboard.add('right');
    advance(.3);
    expect(backend.walking, 1);
    input.keyboard.clear();
    advance(.01);
    expect(backend.walkStops, 1);
    input.keyboard.add('right');
    advance(.02);
    input.jump();
    advance(.01);
    expect(backend.walkStops, 2);
    expect(backend.walking, 2);
    advance(.7);
    expect(backend.walking, 3);
    input.punch();
    advance(.01);
    expect(backend.walkStops, 3);
    advance(.5);
    combat.player.x = combat.config.maxX;
    advance(.02);
    final count = backend.walking;
    advance(.3);
    expect(backend.walking, count);
  });

  test('attack, contact and incoming hurt use separate once-per-event sounds',
      () {
    final target = combat.enemies.first
      ..x = 103
      ..y = combat.player.y;
    input.punch();
    advance(.05);
    expect(backend.effects, [SoundCue.attack]);
    advance(.12);
    expect(backend.effects, [SoundCue.attack, SoundCue.impact]);
    advance(.15);
    expect(backend.effects.where((e) => e == SoundCue.impact), hasLength(1));
    target
      ..x = combat.player.x + 10
      ..facing = -1
      ..beginAttack()
      ..enter(FighterState.active);
    advance(.01);
    expect(backend.effects.last, SoundCue.hurt);
    input.punch();
    advance(.01);
    expect(backend.effects.where((e) => e == SoundCue.attack), hasLength(1));
  });

  test(
      'missed attacks play swing only and expired buffered attacks stay silent',
      () {
    input.kick();
    advance(.1);
    input.punch();
    advance(.5);
    expect(backend.effects, [SoundCue.attack]);
    advance(.2);
    expect(backend.effects, [SoundCue.attack]);
  });

  test('leaving Lore cancels its loop and suspension silences current activity',
      () {
    audio.enterMenu(MenuState.intro);
    audio.enterMenu(MenuState.logo);
    audio.enterMenu(MenuState.main);
    expect(backend.music, [(MusicCue.logo, false)]);
    audio.enterMenu(MenuState.lore);
    expect(backend.music.last, (MusicCue.lore, true));
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
    expect(backend.preloaded, isTrue);
    expect(backend.music, [(MusicCue.logo, false)]);
    game.handleIntroInput();
    game.update(GameMenuFsm.logoDuration);
    await game.ready();
    game.showLore();
    await game.ready();
    expect(backend.music.last, (MusicCue.lore, true));
    game.closeLore();
    await game.ready();
    await game.startGame();
    await game.ready();
    game.input.jump();
    game.update(.05);
    expect(backend.effects, contains(SoundCue.jump));
    game.togglePause();
    expect(backend.sfxStops, greaterThan(0));
    game.removeAll(game.children.toList());
    await game.ready();
    game.onDispose();
    expect(backend.disposals, 1);
  });
}
