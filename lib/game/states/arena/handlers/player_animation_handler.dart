import 'package:flame/components.dart';
import '../model/fighter_model.dart';
import 'fighter_animation_handler.dart';

class PlayerAnimationHandler extends FighterAnimationHandler<PlayerModel> {
  PlayerAnimationHandler(super.cache);

  @override
  Vector2 displaySize(PlayerModel model, Sprite sprite) =>
      sprite.srcSize.clone();

  // The 46x58 exports place the ground line 12 pixels above the cell bottom.
  @override
  double groundPadding(Sprite sprite) => sprite.srcSize.y == 58 ? 12 : 0;

  @override
  Sprite frame(PlayerModel model, double elapsed) {
    if (model.knockedDown) {
      final frames = cache.playerKo;
      final gettingUp = model.state == FighterState.gettingUp;
      final duration = gettingUp ? PlayerModel.getUpDuration : .84;
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
      final frames = switch (model.attack.kind) {
        AttackKind.midKick => cache.midKick,
        AttackKind.highKick => cache.highKick,
        _ => cache.punch,
      };
      final isKick = model.attack.isKick;
      final contactStart = isKick ? frames.length - 2 : 2;
      final windup = [for (var i = 0; i < contactStart; i++) i];
      final poses = switch (model.state) {
        FighterState.startup => windup,
        FighterState.active => [contactStart, contactStart + 1],
        _ => isKick ? windup.reversed.toList() : [frames.length - 1, 1, 0],
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
    if (model.airborne) {
      final progress = model.jumpTime / FighterModel.jumpDuration;
      return progress >= .2 && progress < .8
          ? cache.jump.last
          : cache.jump.first;
    }
    return (model.state == FighterState.walking
            ? cache.walkAnimation
            : cache.idleAnimation)
        .frameAt(elapsed);
  }
}
