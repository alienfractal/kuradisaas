import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'scenario_cache_service.dart';

/// Shared immutable frames; each fighter owns its own presentation clock.
class FighterCacheService {
  late List<Sprite> idle,
      walk,
      punch,
      frontKick,
      highKick,
      veryHighKick,
      jump,
      playerDead,
      playerDeadWound,
      mosquito,
      mosquitoHit,
      mosquitoDead;
  Future<List<Sprite>> _sheet(FlameGame game, String path) async {
    final sheet = ScenarioSheet.fromPath(path);
    final image = await game.images.load(path);
    if (image.width != sheet.width * sheet.frames ||
        image.height != sheet.height) {
      throw FormatException('Image does not fit declared frames: $path '
          '(expected ${sheet.width * sheet.frames}x${sheet.height}, '
          'got ${image.width}x${image.height})');
    }
    return List.generate(
        sheet.frames,
        (i) => Sprite(image,
            srcPosition: Vector2(i * sheet.width.toDouble(), 0),
            srcSize: Vector2(sheet.width.toDouble(), sheet.height.toDouble())));
  }

  Future<void> preload(FlameGame game) async {
    game.images.prefix = 'resources/images/';
    idle = await _sheet(game, 'jann_idle_80x99-4.png');
    walk = await _sheet(game, 'jann_walk_92x99-8.png');
    punch = await _sheet(game, 'jaan_punch_108x98-4.png');
    // Existing combat stage IDs now present low -> frontal -> high kicks.
    frontKick = await _sheet(game, 'jann_low_kick_24x24-5.png');
    highKick = await _sheet(game, 'jann_frontal_kick_24x24-7.png');
    veryHighKick = await _sheet(game, 'jann_high_kick_24x24-7.png');
    jump = await _sheet(game, 'jaan_jump_61x99-5.png');
    playerDead = await _sheet(game, 'jann_death_24x24-7.png');
    playerDeadWound = await _sheet(game, 'jann_death-wound_24x24-7.png');
    mosquito = await _sheet(game, 'spr_mosquito_96x96-4.png');
    mosquitoHit = await _sheet(game, 'mosquito-hit-32x32-5.png');
    mosquitoDead = await _sheet(game, 'mosquito-dead_32x32t-7.png');
  }
}
