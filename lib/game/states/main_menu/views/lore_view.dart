import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';
import '../../../view/screen_view.dart';

/// A separate menu World. Its decorative animation cannot advance game state.
class LoreView extends World {
  static const frameDuration = .25;
  static const story = 'JAAN. EX-COP. EX-KARATE MAN.\n'
      'HE THOUGHT HE WAS DONE FIGHTING.\n'
      '\n'
      'MUTANT MOSQUITOES RUINED HIS SUMMER.\n'
      "HE'S SEEN TOO MANY. HE WANTS REVENGE.";

  LoreView({required this.frames, required this.onBack});
  final List<Sprite> frames;
  final void Function() onBack;
  late final SpriteAnimationComponent background;

  @override
  Future<void> onLoad() async {
    background = SpriteAnimationComponent(
        animation: SpriteAnimation.spriteList(frames, stepTime: frameDuration),
        size: Vector2.all(256),
        paint: Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false);
    await add(background);
    await add(RectangleComponent(
        position: Vector2(8, 8),
        size: Vector2(240, 24),
        paint: Paint()..color = const Color(0xFF000000)));
    await add(TextComponent(
        text: "JAAN'S SUMMER",
        position: Vector2(128, 14),
        anchor: Anchor.topCenter,
        textRenderer: TextPaint(
            style: const TextStyle(
                fontFamily: 'Arcade',
                fontSize: 10,
                color: Color(0xFFFF55FF)))));
    await add(RectangleComponent(
        position: Vector2(7, 166),
        size: Vector2(242, 60),
        paint: Paint()..color = const Color(0xFF55FFFF)));
    await add(RectangleComponent(
        position: Vector2(8, 167),
        size: Vector2(240, 58),
        paint: Paint()..color = const Color(0xFF000000)));
    await add(TextComponent(
        text: story,
        position: Vector2(16, 172),
        textRenderer: TextPaint(
            style: const TextStyle(
                fontFamily: 'Arcade',
                fontSize: 6,
                height: 1.5,
                color: Color(0xFFFFFFFF)))));
    await add(ScreenButton('BACK TO MENU [ESC]', onBack,
        position: Vector2(128, 239)));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, 256, 256),
        Paint()..color = const Color(0xFF000000));
  }
}
