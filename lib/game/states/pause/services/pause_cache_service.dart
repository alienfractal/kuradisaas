import 'package:flame/game.dart';
import '../../../services/button_sprite_cache_service.dart';
import '../../../../utils/animator_cache_service.dart';

/// Assets owned by the pause screen; shared artwork is loaded only once.
class PauseCacheService extends SpriteAnimatorCache {
  PauseCacheService(this.buttons);
  final ButtonSpriteCacheService buttons;
  late SpriteSpec resumeButton, menuButton;

  @override
  Future<void> preload(FlameGame game) async {
    await buttons.preload(game);
    resumeButton = buttons.skin;
    menuButton = buttons.skin;
  }
}
