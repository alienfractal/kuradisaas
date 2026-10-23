import 'cga_palette.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';

/// Shared drawing primitives only. Each global screen owns its own World.
abstract class ScreenView extends World {
  ScreenButton? primaryButton;

  void label(String value, double y,
      {double fontSize = 6, Color color = CgaPalette.white}) {
    add(TextComponent(
      text: value,
      position: Vector2(160, y),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
          style: TextStyle(
              fontFamily: 'Arcade',
              fontSize: fontSize,
              height: 1.7,
              color: color)),
    ));
  }

  void title(String value) =>
      label(value, 22, fontSize: 14, color: CgaPalette.magenta);

  void action(String value, void Function() callback, {double y = 160}) {
    primaryButton = ScreenButton(value, callback, position: Vector2(160, y));
    add(primaryButton!);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 320, 200), Paint()..color = CgaPalette.black);
  }
}

class ScreenButton extends PositionComponent with TapCallbacks {
  final String label;
  final void Function() onPressed;
  bool _pressed = false;
  final TextPaint text = TextPaint(
      style: const TextStyle(
          fontFamily: 'Arcade', fontSize: 7, color: CgaPalette.black));
  ScreenButton(this.label, this.onPressed, {required super.position})
      : super(size: Vector2(190, 20), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(),
        Paint()..color = _pressed ? CgaPalette.cyan : CgaPalette.magenta);
    text.render(canvas, label, size / 2, anchor: Anchor.center);
  }

  @override
  void onTapDown(TapDownEvent event) => _pressed = true;
  @override
  void onTapCancel(TapCancelEvent event) => _pressed = false;
  @override
  void onTapUp(TapUpEvent event) {
    _pressed = false;
    onPressed();
  }
}
