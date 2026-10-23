import 'dart:ui';
import 'package:flame/components.dart';
import '../model/fighter_model.dart';
import '../handlers/fighter_animation_handler.dart';

class FighterEntity extends PositionComponent {
  final FighterModel model;
  final FighterAnimationHandler animations;
  final bool Function() showDebug;
  double elapsed = 0;
  FighterEntity(this.model, this.animations, this.showDebug);
  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    position.setValues(model.x.roundToDouble(), model.y.roundToDouble());
    priority = model.y.round();
  }

  @override
  void render(Canvas canvas) {
    if (!model.isPlayer && model.deathReactionFinished) {
      return;
    }
    final sprite = animations.frame(model, elapsed);
    final size = animations.displaySize(model, sprite);
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..isAntiAlias = false;
    final shadowWidth = (size.x * .6).roundToDouble();
    final shadowLeft = (-shadowWidth / 2).floorToDouble();
    canvas.drawRect(Rect.fromLTWH(shadowLeft, -1, shadowWidth, 2), paint);
    canvas.drawRect(
        Rect.fromLTWH(shadowLeft + 2, -2, shadowWidth - 4, 4), paint);
    // Mosquito hit/death art must stay visible; invulnerability is still
    // enforced by combat. Only Jaan uses the older blinking feedback.
    final blink = model.isPlayer &&
        model.alive &&
        model.invulnerability > 0 &&
        (elapsed * 24).floor().isEven;
    if (!blink) {
      final drawnSize = size;
      canvas.save();
      canvas.translate(0, -model.elevation.roundToDouble());
      canvas.scale(model.facing.toDouble(), 1);
      sprite.render(canvas,
          position: Vector2((-drawnSize.x / 2).floorToDouble(), -drawnSize.y),
          size: drawnSize,
          overridePaint: Paint()
            ..filterQuality = FilterQuality.none
            ..isAntiAlias = false);
      canvas.restore();
    }
    if (!model.isPlayer && model.alive) {
      canvas.save();
      canvas.translate(0, -model.elevation.roundToDouble());
      paint.color = const Color(0xFF000000);
      canvas.drawRect(Rect.fromLTWH(-10, -size.y - 5, 20, 3), paint);
      paint.color = const Color(0xFFFF55FF);
      canvas.drawRect(
          Rect.fromLTWH(-9, -size.y - 4,
              (18 * model.health / model.maxHealth).roundToDouble(), 1),
          paint);
      if (model.state == FighterState.startup) {
        canvas.drawRect(Rect.fromLTWH(-2, -size.y - 13, 4, 5), paint);
        canvas.drawRect(Rect.fromLTWH(-2, -size.y - 7, 4, 1), paint);
      }
      if (model.state == FighterState.hurt && model.lastHitCritical) {
        paint.color = const Color(0xFFFFFFFF);
        canvas.drawRect(Rect.fromLTWH(-3, -size.y - 12, 6, 2), paint);
        canvas.drawRect(Rect.fromLTWH(-1, -size.y - 14, 2, 6), paint);
      }
      canvas.restore();
    }
    if (showDebug()) {
      paint
        ..color = const Color(0xFFFF55FF)
        ..style = PaintingStyle.stroke;
      canvas.drawRect(
          Rect.fromLTWH(
              -FighterModel.hurtHalfWidth,
              -size.y - model.elevation.roundToDouble(),
              FighterModel.hurtHalfWidth * 2,
              size.y),
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
