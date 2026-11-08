import 'package:flame/game.dart';
import '../../../services/button_sprite_cache_service.dart';
import '../../../../utils/animator_cache_service.dart';

/// Assets owned by the score screen; shared artwork is loaded only once.
class ScoreCacheService extends SpriteAnimatorCache {
  ScoreCacheService(this.buttons);
  final ButtonSpriteCacheService buttons;
  late SpriteSpec continueButton;

  @override
  Future<void> preload(FlameGame game) async {
    await buttons.preload(game);
    continueButton = buttons.skin;
  }
}
