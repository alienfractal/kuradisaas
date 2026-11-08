import 'package:flame/components.dart';
import '../model/fighter_model.dart';
import 'fighter_animation_handler.dart';

class GruntAnimationHandler extends FighterAnimationHandler<GruntModel> {
  GruntAnimationHandler(super.cache);

  @override
  Vector2 displaySize(GruntModel model, Sprite sprite) =>
      sprite.srcSize.clone();

  @override
  Sprite frame(GruntModel model, double elapsed) {
    if (model.state == FighterState.dead) {
      final index = (model.stateTime /
              model.deathAnimationDuration *
              cache.gruntDead.length)
          .floor()
          .clamp(0, cache.gruntDead.length - 1);
      return cache.gruntDead[index];
    }
    if (model.state == FighterState.hurt) {
      if (!model.lastHitCritical) {
        final index = (model.stateTime / FighterModel.hitReactionDuration * 3)
            .floor()
            .clamp(0, 2);
        return cache.gruntKo[index];
      }
      final riseStart = model.hitStunDuration - GruntModel.koRiseDuration;
      final rising = !model.airborne && model.stateTime >= riseStart;
      final progress = rising
          ? (model.stateTime - riseStart) / GruntModel.koRiseDuration
          : model.stateTime / GruntModel.koFallDuration;
      final index = (progress * cache.gruntKo.length)
          .floor()
          .clamp(0, cache.gruntKo.length - 1);
      return cache.gruntKo[rising ? cache.gruntKo.length - 1 - index : index];
    }
    if (model.attacking) {
      final frames = model.attack.kind == AttackKind.gruntHeavy
          ? cache.gruntHeavy
          : cache.gruntLight;
      return frames[switch (model.state) {
        FighterState.startup =>
          model.stateTime < model.attack.startup / 2 ? 0 : 1,
        FighterState.active => 2,
        _ => 3,
      }];
    }
    return cache.gruntIdleAnimation.frameAt(elapsed);
  }
}
