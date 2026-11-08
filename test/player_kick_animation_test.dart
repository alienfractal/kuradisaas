import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/game/states/arena/handlers/player_animation_handler.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';
import 'package:kuradi_saased/game/states/arena/services/combat_logic_service.dart';
import 'package:kuradi_saased/game/states/arena/services/fighter_cache_service.dart';
import 'package:kuradi_saased/game/states/arena/services/input_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('current kick exports load and play through every combat phase',
      () async {
    final cache = FighterCacheService();
    addTearDown(cache.dispose);
    await cache.preload(FlameGame());
    final animation = PlayerAnimationHandler(cache);

    for (final attack in [
      AttackSpec.frontKick,
      AttackSpec.highKick,
      AttackSpec.veryHighKick,
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
        expect(frame.srcSize, Vector2(24, 24));
        seen.putIfAbsent(player.state, () => {}).add(frame.srcPosition.x ~/ 24);
        elapsed += 1 / 120;
        combat.update(1 / 120, input);
        expect(elapsed, lessThan(2),
            reason: 'Attack must finish in simulation');
      }
      final low = attack == AttackSpec.frontKick;
      expect(seen[FighterState.startup], low ? {0, 1, 2, 3} : {0, 1, 2, 3, 4});
      expect(seen[FighterState.active], low ? {4, 5} : {5, 6});
      expect(seen[FighterState.recovery], low ? {0, 1, 2, 3} : {0, 1, 2, 3, 4});
      expect(player.state, FighterState.idle);
    }
  });
}
