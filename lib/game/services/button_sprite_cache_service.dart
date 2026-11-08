import 'package:flame/game.dart';
import '../../gen/assets.gen.dart';
import '../../utils/animator_cache_service.dart';

/// Shared reference-project artwork. States declare their own button roles.
class ButtonSpriteCacheService extends SpriteAnimatorCache {
  late SpriteSpec skin;
  @override
  Future<void> preload(FlameGame game) async {
    final frames = await loadSheet(
        game, Assets.resources.images.buttonstart.path,
        spec: const SpriteSheetSpec(100, 22, 1));
    skin = SpriteSpec(frames.single, Vector2(100, 22));
  }
}
