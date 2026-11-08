import 'package:kuradi_saased/gen/assets.gen.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../../../utils/animator_cache_service.dart';
import '../../../services/button_sprite_cache_service.dart';

class MenuCacheService extends SpriteAnimatorCache {
  MenuCacheService(this.buttons);
  final ButtonSpriteCacheService buttons;
  late SpriteSpec startButton, loreButton, backButton;
  static final introPath =
      Assets.resources.images.cGAGameIntroLogos256x2562.path;
  static final lorePath = Assets.resources.images.cGAIntro256x2566.path;
  static const frameSize = 256.0;
  late List<Sprite> introFrames;
  late SpriteAnimationSpec loreAnimation;
  List<Sprite> get loreFrames => loreAnimation.frames;

  @override
  Future<void> preload(FlameGame game) async {
    await buttons.preload(game);
    startButton = buttons.skin;
    loreButton = buttons.skin;
    backButton = buttons.skin;
    introFrames = await loadSheet(game, introPath);
    loreAnimation =
        SpriteAnimationSpec(await loadSheet(game, lorePath), stepTime: .25);
  }
}
