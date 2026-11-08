import 'package:flame/components.dart';
import '../model/fighter_model.dart';
import 'fighter_animation_handler.dart';

class MosquitoAnimationHandler extends FighterAnimationHandler<MosquitoModel> {
  MosquitoAnimationHandler(super.cache);

  @override
  Vector2 displaySize(MosquitoModel model, Sprite sprite) => Vector2.all(32);

  @override
  Sprite frame(MosquitoModel model, double elapsed) {
    if (model.state == FighterState.hurt || model.state == FighterState.dead) {
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
    return cache.mosquitoAnimation.frameAt(elapsed);
  }
}
