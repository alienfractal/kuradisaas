import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';
import 'package:kuradi_saased/game/states/arena/services/fighter_cache_service.dart';
import 'package:kuradi_saased/game/states/arena/services/combat_logic_service.dart';
import 'package:kuradi_saased/game/states/arena/services/input_service.dart';
import 'package:kuradi_saased/game/states/arena/handlers/fighter_animation_handler.dart';
import 'package:kuradi_saased/game/states/arena/services/scenario_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Jaan death uses all seven native frames and holds the corpse',
      () async {
    final sheet = ScenarioSheet.fromPath('jann_death_24x24-7.png');
    expect([sheet.width, sheet.height, sheet.frames], [24, 24, 7]);
    final cache = FighterCacheService();
    await cache.preload(FlameGame());
    final animation = FighterAnimationHandler(cache);
    for (final variant in PlayerDeathVariant.values) {
      final player = CombatLogicService().player
        ..health = 0
        ..enter(FighterState.dead)
        ..deathVariant = variant;
      final frames = variant == PlayerDeathVariant.wound
          ? cache.playerDeadWound
          : cache.playerDead;
      expect(frames, hasLength(7));
      for (var i = 0; i < 7; i++) {
        player.stateTime = (i + .5) * FighterModel.playerDeathDuration / 7;
        final frame = animation.frame(player, 99);
        expect(frame, same(frames[i]));
        expect(frame.srcSize, Vector2(24, 24));
        expect(animation.displaySize(player, frame), Vector2(24, 24));
        expect(player.deathReactionFinished, isFalse);
      }
      player.stateTime = 5;
      expect(animation.frame(player, 0), same(frames.last));
      expect(player.deathReactionFinished, isTrue);
      expect(player.state, FighterState.dead);
    }
  });

  test('death selection varies across deaths and stays fixed for the corpse',
      () {
    final seen = <PlayerDeathVariant>{};
    for (var seed = 0; seed < 20; seed++) {
      final player = FighterModel(
          id: 0,
          isPlayer: true,
          x: 80,
          y: 273,
          attack: AttackSpec.punch,
          random: Random(seed));
      player.enter(FighterState.dead);
      final selected = player.deathVariant;
      seen.add(selected);
      for (var i = 0; i < 10; i++) {
        player.enter(FighterState.dead);
        expect(player.deathVariant, selected);
      }
    }
    expect(seen, PlayerDeathVariant.values.toSet());
  });

  test('defeat settles animations without damage, AI or queued player actions',
      () {
    final combat = CombatLogicService(enemyCount: 2);
    final input = InputService();
    final player = combat.player..health = 1;
    final attacker = combat.enemies.first
      ..x = player.x + 10
      ..y = player.y
      ..facing = -1
      ..beginAttack()
      ..enter(FighterState.active);
    combat.update(1 / 120, input);
    expect(player.state, FighterState.dead);
    final x = player.x;
    final enemyX = combat.enemies.last.x;
    final serial = player.attackSerial;
    final health = attacker.health;
    input
      ..kick()
      ..jump()
      ..keyboard.add('right');
    for (var i = 0; i < 120; i++) {
      combat.update(1 / 120, input);
    }
    expect(player.x, x);
    expect(player.attackSerial, serial);
    expect(attacker.health, health);
    expect(combat.enemies.last.x, enemyX);
    expect(player.deathReactionFinished, isTrue);
    expect(combat.endingAnimationsFinished, isTrue);
    expect(input.consumeKick(), isFalse);
  });

  test('victory waits for the finishing attack and launched victim to settle',
      () {
    final combat = CombatLogicService(enemyCount: 1);
    final player = combat.player;
    combat.enemies.first
      ..health = 0
      ..enter(FighterState.dead)
      ..elevation = 20
      ..verticalVelocity = 200;
    player.beginAttack(AttackSpec.veryHighKick);
    final input = InputService()
      ..kick()
      ..jump();
    expect(combat.endingAnimationsFinished, isFalse);
    for (var i = 0; i < 75; i++) {
      combat.update(1 / 120, input);
    }
    expect(combat.enemies.first.deathReactionFinished, isTrue);
    expect(combat.endingAnimationsFinished, isFalse);
    for (var i = 0; i < 75; i++) {
      combat.update(1 / 120, input);
    }
    expect(combat.endingAnimationsFinished, isTrue);
    expect(player.attackSerial, 1);
    expect(player.airborne, isFalse);
  });
}
