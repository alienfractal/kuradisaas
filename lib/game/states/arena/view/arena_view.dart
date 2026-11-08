import 'dart:ui';
import 'package:flame/components.dart';
import '../services/combat_logic_service.dart';
import '../services/fighter_cache_service.dart';
import 'fighter_entity_factory.dart';
import 'street_scenery.dart';
import '../services/scenario_cache_service.dart';

class ArenaView extends World {
  final CombatLogicService combat;
  final FighterCacheService cache;
  final bool Function() showDebug;
  final ScenarioCacheService scenery;
  ArenaView(this.combat, this.cache, this.showDebug, this.scenery);
  @override
  Future<void> onLoad() async {
    await add(StreetScenery(scenery, combat.config));
    await addAll(
        combat.fighters.map((f) => createFighterEntity(f, cache, showDebug)));
    await add(_ArenaBounds(combat, showDebug));
  }
}

class _ArenaBounds extends Component {
  _ArenaBounds(this.combat, this.showDebug) : super(priority: 10000);
  final CombatLogicService combat;
  final bool Function() showDebug;

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFFFF55FF)
      ..isAntiAlias = false;
    if (showDebug()) {
      paint.style = PaintingStyle.stroke;
      canvas.drawRect(
          Rect.fromLTRB(combat.config.minX, combat.config.minY,
              combat.config.maxX, combat.config.maxY),
          paint);
    }
  }
}
