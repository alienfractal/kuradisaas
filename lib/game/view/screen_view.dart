import 'package:kuradi_saased/gen/fonts.gen.dart';
import 'cga_palette.dart';
import 'package:flame/components.dart';
import '../../utils/game_button.dart';
import '../../utils/sprite_spec.dart';
export '../../utils/game_button.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';

/// Shared drawing primitives only. Each global screen owns its own World.
abstract class ScreenView extends World {
  GameButton? primaryButton;

  void label(String value, double y,
      {double fontSize = 6, Color color = CgaPalette.white}) {
    add(TextComponent(
      text: value,
      position: Vector2(160, y),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
          style: TextStyle(
              fontFamily: FontFamily.arcade,
              fontSize: fontSize,
              height: 1.7,
              color: color)),
    ));
  }

  void title(String value) =>
      label(value, 22, fontSize: 14, color: CgaPalette.magenta);

  void action(String value, void Function() callback,
      {required SpriteSpec skin, double y = 160}) {
    primaryButton =
        GameButton(value, callback, skin: skin, position: Vector2(160, y));
    add(primaryButton!);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 320, 200), Paint()..color = CgaPalette.black);
  }
}
