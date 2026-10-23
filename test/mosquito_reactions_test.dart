import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';
import 'package:kuradi_saased/game/states/arena/handlers/fighter_animation_handler.dart';
import 'package:kuradi_saased/game/states/arena/services/fighter_cache_service.dart';
import 'package:kuradi_saased/game/states/arena/services/combat_logic_service.dart';
import 'package:kuradi_saased/game/states/arena/services/input_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FighterCacheService cache;
  late FighterAnimationHandler animations;
  setUpAll(() async {
    cache = FighterCacheService();
    await cache.preload(FlameGame());
    animations = FighterAnimationHandler(cache);
  });

  test('native reaction sheets keep flight size and use the state clock', () {
    final fighter = CombatLogicService(enemyCount: 1).enemies.first;
    expect(cache.mosquitoHit.length, 5);
    expect(cache.mosquitoDead.length, 7);
    for (final sprite in [
      ...cache.mosquito,
      ...cache.mosquitoHit,
      ...cache.mosquitoDead
    ]) {
      expect(animations.displaySize(fighter, sprite), Vector2.all(32));
    }
    fighter.enter(FighterState.hurt);
    expect(animations.frame(fighter, 99), same(cache.mosquitoHit.first));
    fighter.stateTime = .11;
    expect(animations.frame(fighter, 0), same(cache.mosquitoHit[2]));
    expect(animations.frame(fighter, 99), same(cache.mosquitoHit[2]));
    fighter
      ..stateTime = .65
      ..elevation = 20
      ..lastHitCritical = true;
    expect(animations.frame(fighter, 0), same(cache.mosquitoHit.last));
    fighter.enter(FighterState.dead);
    expect(animations.frame(fighter, 99), same(cache.mosquitoDead.first));
    for (var i = 0; i < 7; i++) {
      fighter.stateTime = (i + .5) * FighterModel.deathReactionDuration / 7;
      expect(animations.frame(fighter, 99), same(cache.mosquitoDead[i]));
    }
    fighter.stateTime = 2;
    expect(animations.frame(fighter, 99), same(cache.mosquitoDead.last));
  });

  test('a real follow-up hit restarts recoil without unlocking the victim', () {
    final combat = CombatLogicService(enemyCount: 1);
    final input = InputService();
    final target = combat.enemies.first
      ..x = 103
      ..y = combat.player.y;
    void advance(double seconds) {
      for (var i = 0; i < (seconds * 120).ceil(); i++) {
        combat.update(1 / 120, input);
      }
    }

    input.kick();
    advance(.2);
    expect(target.state, FighterState.hurt);
    expect(target.stateTime, greaterThan(.04));
    input.kick();
    final health = target.health;
    for (var i = 0; i < 40 && target.health == health; i++) {
      combat.update(1 / 120, input);
    }
    expect(target.health, 3);
    expect(target.stateTime, 0);
    expect(animations.frame(target, 99), same(cache.mosquitoHit.first));
    advance(.3);
    expect(target.airborne, isTrue);
    expect(target.canMove, isFalse);
    expect(target.state, FighterState.hurt);
    expect(animations.frame(target, 99), same(cache.mosquitoHit.last));
  });

  test('a lethal hit waits for all death frames before score becomes ready',
      () {
    final combat = CombatLogicService(enemyCount: 1);
    final input = InputService()..punch();
    final target = combat.enemies.first
      ..x = 103
      ..y = combat.player.y
      ..health = 1;
    for (var i = 0; i < 30 && target.alive; i++) {
      combat.update(1 / 120, input);
    }
    expect(combat.won, isTrue);
    expect(combat.endingAnimationsFinished, isFalse);
    expect(target.stateTime, 0);
    expect(animations.frame(target, 0), same(cache.mosquitoDead.first));
    for (var i = 0; i < 66; i++) {
      combat.update(1 / 120, input);
    }
    expect(combat.endingAnimationsFinished, isFalse);
    combat.update(1 / 120, input);
    combat.update(1 / 120, input);
    expect(combat.endingAnimationsFinished, isTrue);
    expect(target.state, FighterState.dead);
  });
}
