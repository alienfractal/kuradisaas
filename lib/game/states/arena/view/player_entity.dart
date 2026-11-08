import '../model/fighter_model.dart';
import '../services/fighter_cache_service.dart';
import '../handlers/player_animation_handler.dart';
import 'fighter_entity.dart';

class PlayerEntity extends FighterEntity<PlayerModel> {
  PlayerEntity(
      PlayerModel model, FighterCacheService cache, bool Function() showDebug)
      : super(model, PlayerAnimationHandler(cache), showDebug);

  @override
  bool get blink =>
      model.alive &&
      !model.knockedDown &&
      model.invulnerability > 0 &&
      (elapsed * 24).floor().isEven;
}
