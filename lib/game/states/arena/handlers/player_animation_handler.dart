import 'package:flame/components.dart';
import '../model/fighter_model.dart';
import 'fighter_animation_handler.dart';

class PlayerAnimationHandler extends FighterAnimationHandler<PlayerModel> {
  PlayerAnimationHandler(super.cache);

  @override
  Vector2 displaySize(PlayerModel model, Sprite sprite) {
    if ((model.attacking && model.attack.isKick) ||
        model.state == FighterState.dead ||
        model.knockedDown) {
      return sprite.srcSize.clone();
    }
    // Older player exports use 4x4 blocks; kick/death frames are native pixels.
    return Vector2((sprite.srcSize.x / 4).roundToDouble(),
        (sprite.srcSize.y / 4).roundToDouble());
  }

  @override
  Sprite frame(PlayerModel model, double elapsed) {
    if (model.knockedDown) {
      final frames = cache.playerDead;
      final gettingUp = model.state == FighterState.gettingUp;
      final duration = gettingUp
          ? PlayerModel.getUpDuration
          : PlayerModel.playerDeathDuration;
      final index = (model.stateTime / duration * frames.length)
          .floor()
          .clamp(0, frames.length - 1);
      return frames[gettingUp ? frames.length - 1 - index : index];
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
        // Current kick sheets end with two contact poses. Derive the windup
        // and retraction from the loaded count rather than an old frame index.
        final contactStart = frames.length - 2;
        final windup = [for (var i = 0; i < contactStart; i++) i];
        final poses = switch (model.state) {
          FighterState.startup => windup,
          FighterState.active => [contactStart, frames.length - 1],
          _ => windup.reversed.toList(),
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
    return (model.state == FighterState.walking
            ? cache.walkAnimation
            : cache.idleAnimation)
        .frameAt(elapsed);
  }
}
