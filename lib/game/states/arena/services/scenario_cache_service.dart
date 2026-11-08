import 'package:kuradi_saased/gen/assets.gen.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../../../utils/animator_cache_service.dart';

// Compatibility name for existing scenario consumers.
typedef ScenarioSheet = SpriteSheetSpec;

class ScenarioCacheService extends SpriteAnimatorCache {
  static final streetPath =
      Assets.resources.images.scenariotWideFrontStreetHouse640x3201.path;
  static final starsPath =
      Assets.resources.images.scenariotWideStars640x3203.path;
  late SpriteSpec streetSpec;
  late SpriteAnimationSpec starsAnimation;
  Sprite get street => streetSpec.sprite;
  List<Sprite> get stars => starsAnimation.frames;

  @override
  Future<void> preload(FlameGame game) async {
    streetSpec = SpriteSpec(
        (await loadSheet(game, streetPath)).single, Vector2(640, 320));
    // This export has an empty leading 640x320 cell before its three star frames.
    starsAnimation = SpriteAnimationSpec(
        await loadSheet(game, starsPath, firstFrame: 1),
        stepTime: .3);
  }
}
