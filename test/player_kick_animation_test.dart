import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/game/states/arena/handlers/player_animation_handler.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';
import 'package:kuradi_saased/game/states/arena/services/combat_logic_service.dart';
import 'package:kuradi_saased/game/states/arena/services/fighter_cache_service.dart';
import 'package:kuradi_saased/game/states/arena/services/input_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Jaan uses native frames and shows contact poses during each attack',
      () async {
    final cache = FighterCacheService();
    addTearDown(cache.dispose);
    await cache.preload(FlameGame());
    final animation = PlayerAnimationHandler(cache);
    final walkingPlayer = CombatLogicService().player;
    expect(animation.frame(walkingPlayer, 0), same(cache.punch.first));
    walkingPlayer.enter(FighterState.walking);
    expect(cache.walk, hasLength(7));
    for (var i = 0; i < cache.walk.length; i++) {
      final frame = animation.frame(walkingPlayer, (i + .5) * .09);
      expect(frame, same(cache.walk[i]));
      expect(animation.displaySize(walkingPlayer, frame), Vector2(46, 58));
      expect(animation.groundPadding(frame), 12);
    }

    final size = Vector2(46, 58);
    for (final (attack, startup, active, recovery) in [
      (AttackSpec.punch, {0, 1}, {2, 3}, {4, 1, 0}),
      (AttackSpec.midKick, {0}, {1, 2}, {0}),
      (AttackSpec.highKick, {0, 1, 2}, {3, 4}, {0, 1, 2}),
    ]) {
      final combat = CombatLogicService(enemyCount: 1);
      combat.enemies.single
        ..x = 550
        ..y = 310
        ..hitStunDuration = 100
        ..enter(FighterState.hurt);
      final player = combat.player..beginAttack(attack);
      final input = InputService();
      final seen = <FighterState, Set<int>>{};
      var elapsed = 0.0;
      while (player.attacking) {
        final frame = animation.frame(player, elapsed);
        expect(frame.srcSize, size);
        expect(animation.displaySize(player, frame), size);
        seen
            .putIfAbsent(player.state, () => {})
            .add(frame.srcPosition.x ~/ size.x);
        elapsed += 1 / 120;
        combat.update(1 / 120, input);
        expect(elapsed, lessThan(2),
            reason: 'Attack must finish in simulation');
      }
      expect(seen[FighterState.startup], startup);
      expect(seen[FighterState.active], active);
      expect(seen[FighterState.recovery], recovery);
      expect(player.state, FighterState.idle);
    }

    final jump = CombatLogicService(enemyCount: 1);
    final jumper = jump.player;
    final input = InputService()..jump();
    expect(cache.jump, hasLength(2));
    for (final (steps, pose) in [(6, 0), (30, 1), (30, 0)]) {
      for (var i = 0; i < steps; i++) {
        jump.update(1 / 120, input);
      }
      expect(jumper.airborne, isTrue);
      final frame = animation.frame(jumper, 0);
      expect(frame, same(cache.jump[pose]));
      expect(animation.displaySize(jumper, frame), Vector2(46, 58));
    }
  });
}
