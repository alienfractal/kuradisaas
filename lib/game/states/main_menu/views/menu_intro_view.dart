import 'dart:ui';
import 'package:flame/components.dart';

/// A menu FSM frame, displayed at its native square resolution.
class MenuIntroView extends World {
  MenuIntroView(this.frames, this.frameIndex);
  final List<Sprite> frames;
  final int frameIndex;

  @override
  Future<void> onLoad() async {
    await add(SpriteComponent(
        sprite: frames[frameIndex],
        size: Vector2.all(256),
        paint: Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, 256, 256),
        Paint()..color = const Color(0xFF000000));
  }
}
