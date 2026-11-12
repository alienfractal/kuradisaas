import 'dart:ui';
import 'package:flame/components.dart';
import '../model/fighter_model.dart';
import '../handlers/fighter_animation_handler.dart';

abstract class FighterEntity<M extends FighterModel> extends PositionComponent {
  final M model;
  final FighterAnimationHandler<M> animations;
  final bool Function() showDebug;
  double elapsed = 0;
  FighterEntity(this.model, this.animations, this.showDebug);
  bool get visible => true;
  bool get blink => false;
  int get sourceFacing => 1;

  void transformSprite(Canvas canvas) {
    canvas.translate(0, -model.elevation.roundToDouble());
    canvas.scale(model.facing.toDouble() * sourceFacing, 1);
  }

  void renderStatus(Canvas canvas, Vector2 size, Paint paint) {}

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    position.setValues(model.x.roundToDouble(), model.y.roundToDouble());
    priority = model.y.round();
  }

  @override
  void render(Canvas canvas) {
    if (!visible) {
      return;
    }
    final sprite = animations.frame(model, elapsed);
    final size = animations.displaySize(model, sprite);
    final heightAboveGround = size.y - animations.groundPadding(sprite);
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..isAntiAlias = false;
    final shadowWidth = (size.x * .6).roundToDouble();
    final shadowLeft = (-shadowWidth / 2).floorToDouble();
    canvas.drawRect(Rect.fromLTWH(shadowLeft, -1, shadowWidth, 2), paint);
    canvas.drawRect(
        Rect.fromLTWH(shadowLeft + 2, -2, shadowWidth - 4, 4), paint);
    if (!blink) {
      canvas.save();
      transformSprite(canvas);
      sprite.render(canvas,
          position: Vector2((-size.x / 2).floorToDouble(), -heightAboveGround),
          size: size,
          overridePaint: Paint()
            ..filterQuality = FilterQuality.none
            ..isAntiAlias = false);
      canvas.restore();
    }
    renderStatus(canvas, size, paint);
    if (showDebug()) {
      paint
        ..color = const Color(0xFFFF55FF)
        ..style = PaintingStyle.stroke;
      canvas.drawRect(
          Rect.fromLTWH(
              -FighterModel.hurtHalfWidth,
              -heightAboveGround - model.elevation.roundToDouble(),
              FighterModel.hurtHalfWidth * 2,
              heightAboveGround),
          paint);
      if (model.attacking) {
        paint.color = model.state == FighterState.active
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF000000);
        canvas.drawRect(
            Rect.fromLTWH(
                model.facing > 0 ? 0 : -model.attack.reach,
                -model.attack.laneTolerance,
                model.attack.reach,
                model.attack.laneTolerance * 2),
            paint);
      }
    }
  }
}
