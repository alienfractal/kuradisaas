import 'package:flame/game.dart';
import '../../../services/button_sprite_cache_service.dart';
import '../../../../utils/animator_cache_service.dart';

/// Assets owned by the end screen; shared artwork is loaded only once.
class EndCacheService extends SpriteAnimatorCache {
  EndCacheService(this.buttons);
  final ButtonSpriteCacheService buttons;
  late SpriteSpec menuButton;

  @override
  Future<void> preload(FlameGame game) async {
    await buttons.preload(game);
    menuButton = buttons.skin;
  }
}
