import 'dart:ui';
import 'package:flame/components.dart';
import '../model/fighter_model.dart';
import 'fighter_entity.dart';

/// Shared enemy overlays and disappearance after the death presentation.
abstract class EnemyEntity<M extends EnemyModel> extends FighterEntity<M> {
  EnemyEntity(super.model, super.animations, super.showDebug);

  @override
  bool get visible => !model.deathReactionFinished;

  @override
  void renderStatus(Canvas canvas, Vector2 size, Paint paint) {
    if (model.alive) {
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
  }
}
