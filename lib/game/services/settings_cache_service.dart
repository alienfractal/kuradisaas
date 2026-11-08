import 'package:kuradi_saased/gen/assets.gen.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../utils/animator_cache_service.dart';

class SettingsCacheService extends SpriteAnimatorCache {
  late List<Sprite> effects, music, crt;
  @override
  Future<void> preload(FlameGame game) async {
    effects = await loadSheet(game, Assets.resources.images.soundfxVolume.path,
        spec: const SpriteSheetSpec(34, 34, 4));
    music = await loadSheet(game, Assets.resources.images.musicfxVolume.path,
        spec: const SpriteSheetSpec(34, 34, 4));
    crt = await loadSheet(game, Assets.resources.images.crton32x328.path);
  }
}
