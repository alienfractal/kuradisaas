import 'dart:ui';
import 'package:flame/components.dart' hide ButtonState;
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import '../gen/fonts.gen.dart';
import '../game/view/cga_palette.dart';
import 'sprite_spec.dart';

/// Cached sprite frame, view-owned input state, and an independent action label.
class GameButton extends SpriteButtonComponent {
  final String label;
  final SpriteSpec skin;
  bool _enabled = true;
  final _paint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  GameButton(this.label, void Function() onPressed,
      {required this.skin, required Vector2 position, Vector2? size})
      : super(
            button: skin.sprite,
            buttonDown: skin.sprite,
            onPressed: onPressed,
            position: position,
            size: size ?? Vector2(190, 20),
            anchor: Anchor.center);

  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    if (!value) current = ButtonState.up;
  }

  bool get pressed => current == ButtonState.down;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Preserve the reference button's pixel border at any label width. Its
    // baked START label is covered; this component supplies each state's label.
    canvas.drawImageNine(
        button.image, const Rect.fromLTRB(4, 4, 96, 18), size.toRect(), _paint);
    // Repeat an undecorated patch of the original interior behind the label;
    // preserve its actual colors/texture instead of painting a black fill.
    for (var x = 4.0; x < size.x - 4; x += 8) {
      final width = (size.x - 4 - x).clamp(0.0, 8.0);
      canvas.drawImageRect(button.image, Rect.fromLTWH(5, 4, width, 14),
          Rect.fromLTWH(x, 4, width, size.y - 8), _paint);
    }
    TextPaint(
            style: const TextStyle(
                fontFamily: FontFamily.arcade,
                fontSize: 7,
                color: CgaPalette.white))
        .render(canvas, label, size / 2 + Vector2(0, pressed ? 1 : 0),
            anchor: Anchor.center);
  }

  @override
  // Flame names the parameter `_`; this handler needs to forward the event.
  // ignore: avoid_renaming_method_parameters
  void onTapDown(TapDownEvent event) {
    if (enabled) super.onTapDown(event);
  }

  @override
  // ignore: avoid_renaming_method_parameters
  void onTapUp(TapUpEvent event) {
    if (!enabled || !pressed) return;
    super.onTapUp(event);
  }
}
