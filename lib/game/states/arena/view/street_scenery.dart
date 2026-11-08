import 'dart:ui';
import 'package:flame/components.dart';
import '../../../../kuradi_saased.dart';
import '../model/arena_config.dart';
import '../services/scenario_cache_service.dart';

/// Presentation only: animation never changes combat or ground bounds.
class StreetScenery extends Component with HasGameReference<KuradiSaased> {
  StreetScenery(this.cache, this.config) : super(priority: -100);
  final ScenarioCacheService cache;
  final ArenaConfig config;
  late final SpriteAnimationComponent stars;
  final _paint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  @override
  Future<void> onLoad() async {
    stars = SpriteAnimationComponent(
      animation: cache.starsAnimation.createAnimation(),
      size: Vector2(640, 320),
      paint: _paint,
    );
    await addAll([
      stars,
      SpriteComponent(
          sprite: cache.streetSpec.sprite,
          size: cache.streetSpec.imgSize,
          paint: _paint,
          priority: 1)
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // The distant sky scrolls slowly, keeping stars visible above the street.
    final camera = game.camera.viewfinder.position;
    stars.position.setValues(
        (camera.x * .5).roundToDouble(), (camera.y * .85).roundToDouble());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, config.width, config.height),
        Paint()..color = const Color(0xFF000000));
  }
}
