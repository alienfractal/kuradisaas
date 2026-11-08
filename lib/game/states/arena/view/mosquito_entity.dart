import 'dart:ui';
import 'package:flame/components.dart';
import '../model/fighter_model.dart';
import '../services/fighter_cache_service.dart';
import '../handlers/mosquito_animation_handler.dart';
import 'enemy_entity.dart';

class MosquitoEntity extends EnemyEntity<MosquitoModel> {
  MosquitoEntity(
      MosquitoModel model, FighterCacheService cache, bool Function() showDebug)
      : super(model, MosquitoAnimationHandler(cache), showDebug);

  @override
  void renderStatus(Canvas canvas, Vector2 size, Paint paint) {
    super.renderStatus(canvas, size, paint);
    if (!model.alive || model.rank != MosquitoRank.veteran) return;
    const left = -17.0;
    final top = -size.y - 6 - model.elevation.roundToDouble();
    paint.color = const Color(0xFF000000);
    canvas.drawRect(Rect.fromLTWH(left - 1, top - 1, 7, 7), paint);
    paint.color = const Color(0xFFFFFF55);
    // Five native game pixels per side: a persistent, font-independent '*'.
    const rows = ['..#..', '#.#.#', '.###.', '#.#.#', '..#..'];
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        if (rows[y][x] == '#') {
          canvas.drawRect(Rect.fromLTWH(left + x, top + y, 1, 1), paint);
        }
      }
    }
  }
}
