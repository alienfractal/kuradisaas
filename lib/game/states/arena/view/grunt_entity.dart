import '../model/fighter_model.dart';
import '../services/fighter_cache_service.dart';
import '../handlers/grunt_animation_handler.dart';
import 'enemy_entity.dart';

class GruntEntity extends EnemyEntity<GruntModel> {
  GruntEntity(
      GruntModel model, FighterCacheService cache, bool Function() showDebug)
      : super(model, GruntAnimationHandler(cache), showDebug);

  // Grunt artwork faces left; player/mosquito artwork faces right.
  @override
  int get sourceFacing => -1;
}
