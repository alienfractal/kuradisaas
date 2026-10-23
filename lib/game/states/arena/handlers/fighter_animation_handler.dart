import 'package:flame/components.dart';
import '../model/fighter_model.dart';
import '../services/fighter_cache_service.dart';

/// Presentation reads combat state; finishing an animation cannot change combat.
class FighterAnimationHandler {
  final FighterCacheService cache;
  FighterAnimationHandler(this.cache);

  /// Imported Jaan art uses mostly 4x4 blocks; mosquitoes use 3x3 blocks.
  /// Return whole game pixels so they share the street's native 1px grid.
  Vector2 displaySize(FighterModel model, Sprite sprite) {
    if (model.isPlayer &&
        ((model.attacking && model.attack.isKick) ||
            model.state == FighterState.dead)) {
      // Kick/death sheets are native game pixels, not enlarged exports.
      return sprite.srcSize.clone();
    }
    // Old flight frames are 96px exports; new reactions are native 32px art.
    if (!model.isPlayer) return Vector2.all(32);
    const sourceScale = 4;
    return Vector2((sprite.srcSize.x / sourceScale).roundToDouble(),
        (sprite.srcSize.y / sourceScale).roundToDouble());
  }

  Sprite frame(FighterModel model, double elapsed) {
    if (!model.isPlayer) {
      if (model.state == FighterState.hurt ||
          model.state == FighterState.dead) {
        final dead = model.state == FighterState.dead;
        final frames = dead ? cache.mosquitoDead : cache.mosquitoHit;
        final duration = dead
            ? FighterModel.deathReactionDuration
            : FighterModel.hitReactionDuration;
        // Recoil plays once, then holds while launched/stunned. Every new hit
        // re-enters hurt, resetting stateTime and therefore the reaction.
        final index = (model.stateTime / duration * frames.length)
            .floor()
            .clamp(0, frames.length - 1);
        return frames[index];
      }
      return cache.mosquito[(elapsed / .09).floor() % 4];
    }
    if (model.state == FighterState.dead) {
      final frames = model.deathVariant == PlayerDeathVariant.wound
          ? cache.playerDeadWound
          : cache.playerDead;
      final index =
          (model.stateTime / model.deathAnimationDuration * frames.length)
              .floor()
              .clamp(0, frames.length - 1);
      return frames[index];
    }
    if (model.attacking) {
      if (model.attack.isKick) {
        final frames = switch (model.attack.kind) {
          AttackKind.frontKick => cache.frontKick,
          AttackKind.highKick => cache.highKick,
          _ => cache.veryHighKick,
        };
        // Stage 1 is low (5 frames), then frontal/high (7 frames each).
        // Extended contact poses belong to Active; Recovery retracts the leg.
        final poses = switch ((model.attack.kind, model.state)) {
          (AttackKind.frontKick, FighterState.startup) => [0, 1, 2, 3],
          (AttackKind.frontKick, FighterState.active) => [4],
          (AttackKind.frontKick, _) => [3, 2, 1, 0],
          (_, FighterState.startup) => [0, 1, 2, 3, 4],
          (_, FighterState.active) => [5, 6],
          _ => [4, 3, 2, 1, 0],
        };
        final duration = switch (model.state) {
          FighterState.startup => model.attack.startup,
          FighterState.active => model.attack.active,
          _ => model.attack.recovery,
        };
        final index = (model.stateTime / duration * poses.length)
            .floor()
            .clamp(0, poses.length - 1);
        return frames[poses[index]];
      }
      return cache.punch[switch (model.state) {
        FighterState.startup =>
          model.stateTime < model.attack.startup / 2 ? 0 : 1,
        FighterState.active => 2,
        _ => 3,
      }];
    }
    if (model.airborne) {
      final frame =
          (model.jumpTime / FighterModel.jumpDuration * cache.jump.length)
              .floor()
              .clamp(0, cache.jump.length - 1);
      return cache.jump[frame];
    }
    final frames =
        model.state == FighterState.walking ? cache.walk : cache.idle;
    return frames[(elapsed /
                (model.canMove && model.state == FighterState.walking
                    ? .09
                    : .20))
            .floor() %
        frames.length];
  }
}
