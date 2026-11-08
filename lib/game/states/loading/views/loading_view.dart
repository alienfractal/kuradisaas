import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../services/loading_cache_service.dart';
import '../../../view/screen_view.dart';

class LoadingView extends ScreenView {
  final String description;
  final LoadingCacheService sprites;
  LoadingView({required this.description, required this.sprites});
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    title('LOADING');
    label(description, 82, fontSize: 8);
    label('PREPARING THE NEXT WORLD...', 115);
    await add(SpriteAnimationComponent(
        animation: sprites.mosquito.createAnimation(),
        size: Vector2.all(32),
        position: Vector2(144, 143),
        paint: Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false));
  }
}
