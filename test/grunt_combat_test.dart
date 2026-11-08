import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/gen/assets.gen.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';
import 'package:kuradi_saased/game/states/arena/services/combat_logic_service.dart';
import 'package:kuradi_saased/game/states/arena/services/input_service.dart';
import 'package:kuradi_saased/game/states/arena/services/fighter_cache_service.dart';
import 'package:kuradi_saased/game/states/arena/handlers/fighter_animation_handler.dart';

void tick(CombatLogicService combat, InputService input, double seconds) {
  for (var i = 0; i < (seconds * 120).ceil(); i++) {
    combat.update(1 / 120, input);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lethal kick waits for the complete grunt death before settlement', () {
    final combat = CombatLogicService(enemyCount: 1, gruntCount: 1);
    final input = InputService();
    final grunt = combat.enemies.single
      ..health = 1
      ..x = combat.player.x + 20
      ..y = combat.player.y;
    input.kick();
    tick(combat, input, .20);
    expect(grunt.state, FighterState.dead);
    expect(combat.won, isTrue);
    tick(combat, input, .65);
    expect(combat.endingAnimationsFinished, isFalse);
    tick(combat, input, .4);
    expect(combat.endingAnimationsFinished, isTrue);
  });

  for (final facing in [-1, 1]) {
    test('grunt stays in range for a full kick combo facing $facing', () {
      final combat = CombatLogicService(enemyCount: 1, gruntCount: 1);
      final input = InputService();
      final player = combat.player..facing = facing;
      final grunt = combat.enemies.single
        ..x = player.x + facing * AttackSpec.frontKick.reach
        ..y = player.y
        ..hitStunDuration = 5
        ..enter(FighterState.hurt);
      final startX = grunt.x;
      input.kick();
      tick(combat, input, .2);
      expect(grunt.health, 11);
      expect((grunt.x - startX).abs(), closeTo(3, .001));
      input.kick();
      tick(combat, input, .3);
      expect(grunt.health, 9);
      input.kick();
      tick(combat, input, .35);
      expect(grunt.health, 6);
      expect(combat.hits, 3);
      expect(player.x, 80, reason: 'Follow-ups should not require chasing');
    });
  }

  test('mixed swarm alternates light and heavy attacks', () {
    final combat = CombatLogicService(enemyCount: 3, gruntCount: 2);
    expect(
        combat.enemies.where((e) => e.kind == FighterKind.grunt), hasLength(2));
    final grunt = combat.enemies.last;
    expect(grunt.maxHealth, 12);
    final input = InputService();
    grunt
      ..x = combat.player.x + 30
      ..y = combat.player.y;
    combat.update(1 / 120, input);
    expect(grunt.attack, AttackSpec.gruntLight);
    expect(grunt.state, FighterState.startup);
    tick(combat, input, 1.3);
    expect(combat.player.health, 7);
    expect(combat.player.knockedDown, isFalse);
    expect(grunt.attack, AttackSpec.gruntHeavy);
    expect(grunt.state, FighterState.startup);
  });

  test('interrupted light windups are retried before another heavy swing', () {
    final combat = CombatLogicService(enemyCount: 1, gruntCount: 1);
    final input = InputService();
    final grunt = combat.enemies.single
      ..x = combat.player.x + 24
      ..y = combat.player.y;
    // Keep the player safe while observing several complete attack cycles.
    combat.player.invulnerability = 30;
    for (var cycle = 0; cycle < 3; cycle++) {
      combat.update(1 / 120, input);
      expect(grunt.attack, AttackSpec.gruntLight);
      expect(grunt.state, FighterState.startup);
      // Simulate a hit interrupting the windup before the strike.
      grunt.enter(FighterState.hurt);
      tick(combat, input, .26);
      expect(grunt.attack, AttackSpec.gruntLight);
      expect(grunt.state, FighterState.startup);
      tick(combat, input, .33);
      expect(grunt.state, FighterState.active);
      expect(grunt.attack, AttackSpec.gruntLight);
      tick(combat, input, .63);
      expect(grunt.attack, AttackSpec.gruntHeavy);
      expect(grunt.state, FighterState.startup);
      tick(combat, input, .66);
      expect(grunt.state, FighterState.active);
      expect(grunt.nextAttack, AttackSpec.gruntLight);
      tick(combat, input, 1.0);
      expect(grunt.attack, AttackSpec.gruntLight);
      expect(grunt.state, FighterState.startup);
    }
  });

  test('heavy hit drops player, ignores input, recovers without losing level',
      () {
    final combat = CombatLogicService(enemyCount: 1, gruntCount: 1);
    final input = InputService();
    final player = combat.player;
    combat.enemies.single
      ..x = player.x + 20
      ..y = player.y
      ..facing = -1
      ..beginAttack(AttackSpec.gruntHeavy)
      ..enter(FighterState.active);
    player
      ..queueAttack(AttackSpec.frontKick)
      ..beginJump();
    combat.update(1 / 120, input);
    expect(player.health, 6);
    expect(player.state, FighterState.knockedDown);
    expect(player.airborne, isFalse);
    expect(player.bufferedAttack, isNull);
    final x = player.x;
    final serial = player.attackSerial;
    input
      ..kick()
      ..jump()
      ..keyboard.add('right');
    tick(combat, input, 1.1);
    expect(player.state, FighterState.gettingUp);
    expect(player.x, x);
    expect(player.attackSerial, serial);
    expect(combat.endingAnimationsFinished, isFalse);
    input.clear();
    tick(combat, input, .5);
    expect(player.knockedDown, isFalse);
    expect(player.canMove, isTrue);
    expect(player.health, 6);
    expect(player.invulnerability, greaterThan(0));
  });

  test('lethal heavy hit remains a real death', () {
    final combat = CombatLogicService(enemyCount: 1, gruntCount: 1);
    combat.player.health = 2;
    combat.enemies.single
      ..x = combat.player.x + 20
      ..y = combat.player.y
      ..facing = -1
      ..beginAttack(AttackSpec.gruntHeavy)
      ..enter(FighterState.active);
    final input = InputService();
    combat.update(1 / 120, input);
    tick(combat, input, 2);
    expect(combat.player.health, 0);
    expect(combat.player.state, FighterState.dead);
    expect(combat.endingAnimationsFinished, isTrue);
  });

  test('grunt sheets, background key and knockdown animation sample correctly',
      () async {
    final cache = FighterCacheService();
    addTearDown(cache.dispose);
    final game = FlameGame();
    addTearDown(game.images.clearCache);
    await cache.preload(game);
    for (final asset in [
      Assets.resources.images.mosquitoGruntAnimationIdleSmall47x587,
      Assets.resources.images.mosquitoGruntAnimationLightAttackSmall47x584,
      Assets.resources.images.mosquitoGruntAnimationHeavyAttackSmall47x584,
    ]) {
      expect(game.images.containsKey(asset.path), isTrue);
    }
    expect(cache.gruntIdle, hasLength(7));
    expect(cache.gruntLight, hasLength(4));
    expect(cache.gruntHeavy, hasLength(4));
    expect(cache.gruntKo, hasLength(7));
    expect(cache.gruntDead, hasLength(12));
    for (final frames in [
      cache.gruntIdle,
      cache.gruntLight,
      cache.gruntHeavy
    ]) {
      final pixels = (await frames.first.image
          .toByteData(format: ui.ImageByteFormat.rawRgba))!;
      expect(pixels.buffer.asUint8List(pixels.offsetInBytes, 4), [0, 0, 0, 0]);
    }
    for (final frames in [
      cache.gruntIdle,
      cache.gruntLight,
      cache.gruntHeavy
    ]) {
      for (final frame in frames) {
        expect(frame.srcSize, Vector2(47, 58));
        expect(frame.image.width, frames.length * 47);
        expect(frame.image.height, 58);
      }
    }
    for (final frames in [cache.gruntKo, cache.gruntDead]) {
      for (final frame in frames) {
        expect(frame.srcSize, Vector2(32, 40));
        expect(frame.image.width, frames.length * 32);
        expect(frame.image.height, 40);
      }
    }
    final handler = GruntAnimationHandler(cache);
    final combat = CombatLogicService(enemyCount: 1, gruntCount: 1);
    final grunt = combat.enemies.whereType<GruntModel>().single;
    expect(handler.displaySize(grunt, cache.gruntIdle.first), Vector2(47, 58));
    for (final spec in [AttackSpec.gruntLight, AttackSpec.gruntHeavy]) {
      grunt.beginAttack(spec);
      final frames =
          spec == AttackSpec.gruntLight ? cache.gruntLight : cache.gruntHeavy;
      expect(handler.frame(grunt, 99), same(frames[0]));
      grunt.stateTime = spec.startup * .75;
      expect(handler.frame(grunt, 99), same(frames[1]));
      grunt.enter(FighterState.active);
      expect(handler.frame(grunt, 99), same(frames[2]));
      grunt.enter(FighterState.recovery);
      expect(handler.frame(grunt, 99), same(frames[3]));
    }
    final playerHandler = PlayerAnimationHandler(cache);
    final player = combat.player..enter(FighterState.knockedDown);
    expect(playerHandler.frame(player, 99), same(cache.playerDead.first));
    player.stateTime = .95;
    expect(playerHandler.frame(player, 99), same(cache.playerDead.last));
    player.enter(FighterState.gettingUp);
    expect(playerHandler.frame(player, 99), same(cache.playerDead.last));
    player.stateTime = PlayerModel.getUpDuration - .001;
    expect(playerHandler.frame(player, 99), same(cache.playerDead.first));
  });

  test('grunt critical KO falls, gets up, and lethal hits use death frames',
      () async {
    final cache = FighterCacheService();
    addTearDown(cache.dispose);
    await cache.preload(FlameGame());
    final handler = GruntAnimationHandler(cache);
    final combat = CombatLogicService(enemyCount: 1, gruntCount: 1);
    final input = InputService();
    final grunt = combat.enemies.whereType<GruntModel>().single
      ..x = combat.player.x + 23
      ..y = combat.player.y;
    input.kick();
    tick(combat, input, .2);
    expect(cache.gruntKo.take(3), contains(handler.frame(grunt, 99)));
    input.kick();
    tick(combat, input, .3);
    input.kick();
    tick(combat, input, .35);
    expect(grunt.health, 6);
    expect(grunt.lastHitCritical, isTrue);
    expect(cache.gruntKo, contains(handler.frame(grunt, 99)));
    tick(combat, input, .55);
    expect(grunt.airborne, isFalse);
    expect(handler.frame(grunt, 99), same(cache.gruntKo.last));
    while (grunt.stateTime < grunt.hitStunDuration - .02) {
      combat.update(1 / 120, input);
    }
    expect(handler.frame(grunt, 99), same(cache.gruntKo.first));
    tick(combat, input, .1);
    expect(grunt.state, isNot(FighterState.hurt));

    // A new real hit restarts recoil, then a lethal hit selects death instead.
    grunt.x = combat.player.x + 20;
    combat.player.beginAttack(AttackSpec.punch);
    tick(combat, input, .1);
    expect(grunt.lastHitCritical, isFalse);
    expect(handler.frame(grunt, 99), same(cache.gruntKo.first));
    tick(combat, input, .3);
    grunt.health = 1;
    combat.player.beginAttack(AttackSpec.punch);
    tick(combat, input, .1);
    expect(grunt.state, FighterState.dead);
    expect(handler.frame(grunt, 99), same(cache.gruntDead.first));
    tick(combat, input, .88);
    expect(handler.frame(grunt, 99), same(cache.gruntDead.last));
    expect(combat.endingAnimationsFinished, isFalse);
    tick(combat, input, .1);
    expect(combat.endingAnimationsFinished, isTrue);
    expect(handler.frame(grunt, 99), same(cache.gruntDead.last));
  });
}
