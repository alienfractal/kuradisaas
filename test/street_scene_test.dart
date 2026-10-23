import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/game/states/arena/model/arena_config.dart';
import 'package:kuradi_saased/game/states/arena/services/combat_logic_service.dart';
import 'package:kuradi_saased/game/states/arena/services/input_service.dart';
import 'package:kuradi_saased/game/states/arena/services/scenario_cache_service.dart';

void main() {
  test('scenario filenames describe frame size and animation count', () {
    final stars = ScenarioSheet.fromPath(ScenarioCacheService.starsPath);
    expect([stars.width, stars.height, stars.frames], [640, 320, 3]);
    expect(ScenarioSheet.fromPath(ScenarioCacheService.streetPath).frames, 1);
    final hurt = ScenarioSheet.fromPath('mosquito-hit-32x32-5.png');
    final dead = ScenarioSheet.fromPath('mosquito-dead_32x32t-7.png');
    expect([hurt.width, hurt.height, hurt.frames], [32, 32, 5]);
    expect([dead.width, dead.height, dead.frames], [32, 32, 7]);
    expect(() => ScenarioSheet.fromPath('missing.png'), throwsFormatException);
  });

  test('camera follows both axes and never leaves the 640x320 map', () {
    const config = ArenaConfig();
    expect(config.cameraX(0), 0);
    expect(config.cameraX(320), 192);
    expect(config.cameraX(640), 384);
    expect(config.cameraY(0), 0);
    expect(config.cameraY(250), 154);
    expect(config.cameraY(320), 192);
    for (var x = -100.0; x < 800; x += 10) {
      expect(config.cameraX(x), inInclusiveRange(0, 384));
      expect(config.cameraY(x), inInclusiveRange(0, 192));
    }
  });

  test('fighters spawn on the street and cannot walk past either floor edge',
      () {
    final combat = CombatLogicService(enemyCount: 0);
    expect(combat.player.y, inInclusiveRange(236, 310));
    final populated = CombatLogicService();
    for (final fighter in populated.fighters) {
      expect(fighter.y, inInclusiveRange(236, 310));
    }
    final input = InputService()..keyboard.add('up');
    for (var i = 0; i < 2400; i++) {
      combat.update(1 / 120, input);
    }
    expect(combat.player.y, 236);
    input.keyboard
      ..clear()
      ..add('down');
    for (var i = 0; i < 2400; i++) {
      combat.update(1 / 120, input);
    }
    expect(combat.player.y, 310);
  });
}
