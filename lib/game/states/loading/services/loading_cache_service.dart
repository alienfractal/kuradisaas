import 'package:flame/game.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../utils/animator_cache_service.dart';

class LoadingCacheService extends SpriteAnimatorCache {
  late SpriteAnimationSpec mosquito;

  @override
  Future<void> preload(FlameGame game) async {
    mosquito = SpriteAnimationSpec(
        await loadSheet(game, Assets.resources.images.sprMosquito96x964.path),
        stepTime: .09);
  }
}
