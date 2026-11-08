import 'package:flame/game.dart';
import '../../../../utils/animator_cache_service.dart';
import 'fighter_cache_service.dart';
import 'scenario_cache_service.dart';

/// The Level state's asset boundary: fighters and scenario layers.
class LevelCacheService extends SpriteAnimatorCache {
  LevelCacheService(this.fighters, this.scenario);
  final FighterCacheService fighters;
  final ScenarioCacheService scenario;

  @override
  Future<void> preload(FlameGame game) async {
    await fighters.preload(game);
    await scenario.preload(game);
  }

  @override
  void dispose() {
    fighters.dispose();
    scenario.dispose();
    super.dispose();
  }
}
