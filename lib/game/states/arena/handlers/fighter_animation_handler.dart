import 'package:flame/components.dart';
import '../model/fighter_model.dart';
import '../services/fighter_cache_service.dart';

export 'player_animation_handler.dart';
export 'mosquito_animation_handler.dart';
export 'grunt_animation_handler.dart';

/// Presentation reads simulation state; animation completion never changes it.
abstract class FighterAnimationHandler<M extends FighterModel> {
  final FighterCacheService cache;
  FighterAnimationHandler(this.cache);

  Vector2 displaySize(M model, Sprite sprite);
  double groundPadding(Sprite sprite) => 0;
  Sprite frame(M model, double elapsed);
}
