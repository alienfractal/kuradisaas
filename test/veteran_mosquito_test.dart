import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/game/model/campaign_model.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';
import 'package:kuradi_saased/game/states/arena/services/combat_logic_service.dart';
import 'package:kuradi_saased/game/states/arena/services/fighter_cache_service.dart';
import 'package:kuradi_saased/game/states/arena/services/input_service.dart';
import 'package:kuradi_saased/game/states/arena/view/mosquito_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('campaign increases veterans from zero to one to three', () {
    final levels = CampaignModel().levels;
    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      final combat = CombatLogicService(
          enemyCount: level.enemyCount,
          gruntCount: level.gruntCount,
          veteranCount: level.veteranCount,
          random: Random(3));
      expect(
          combat.enemies
              .whereType<MosquitoModel>()
              .where((m) => m.rank == MosquitoRank.veteran),
          hasLength([0, 1, 3][i]));
    }
  });

  test(
      'veteran selection varies, is repeatable with a seed, and excludes grunts',
      () {
    int chosen(int seed) {
      final combat = CombatLogicService(
          enemyCount: 7, gruntCount: 2, veteranCount: 1, random: Random(seed));
      expect(combat.enemies.whereType<GruntModel>(), hasLength(2));
      return combat.enemies
          .whereType<MosquitoModel>()
          .singleWhere((m) => m.rank == MosquitoRank.veteran)
          .id;
    }

    expect(chosen(4), chosen(4));
    expect({for (var seed = 0; seed < 20; seed++) chosen(seed)}.length,
        greaterThan(1));
    expect(
        () => CombatLogicService(enemyCount: 2, gruntCount: 2, veteranCount: 1),
        throwsArgumentError);
  });

  test('veteran strikes earlier and attacks more often than a regular mosquito',
      () {
    final combat =
        CombatLogicService(enemyCount: 2, veteranCount: 1, random: Random(1));
    final mosquitoes = combat.enemies.whereType<MosquitoModel>();
    final veteran =
        mosquitoes.singleWhere((m) => m.rank == MosquitoRank.veteran);
    final regular =
        mosquitoes.singleWhere((m) => m.rank == MosquitoRank.regular);
    for (final mosquito in mosquitoes) {
      mosquito
        ..x = combat.player.x + 20
        ..y = combat.player.y;
    }
    combat.player.invulnerability = 10;
    final input = InputService();
    for (var i = 0; i < 31; i++) {
      combat.update(1 / 120, input);
    }
    expect(veteran.state, FighterState.active);
    expect(regular.state, FighterState.startup);
    for (var i = 0; i < 570; i++) {
      combat.update(1 / 120, input);
    }
    expect(veteran.attackSerial, greaterThan(regular.attackSerial));
    expect(veteran.maxHealth, regular.maxHealth);
    expect(combat.player.health, 8);
  });

  test('only a living veteran draws the yellow asterisk', () async {
    final cache = FighterCacheService();
    addTearDown(cache.dispose);
    await cache.preload(FlameGame());
    Future<int> yellowPixels(MosquitoModel model) async {
      final entity = MosquitoEntity(model, cache, () => false);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..translate(32, 64);
      entity.render(canvas);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(64, 80);
      final data =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      var yellow = 0;
      for (var y = 25; y < 32; y++) {
        for (var x = 14; x < 21; x++) {
          final i = (y * 64 + x) * 4;
          if (data.getUint8(i) == 255 &&
              data.getUint8(i + 1) == 255 &&
              data.getUint8(i + 2) == 85 &&
              data.getUint8(i + 3) == 255) {
            yellow++;
          }
        }
      }
      image.dispose();
      picture.dispose();
      return yellow;
    }

    final regular = MosquitoModel(id: 1, x: 0, y: 0);
    final veteran =
        MosquitoModel(id: 2, x: 0, y: 0, rank: MosquitoRank.veteran);
    expect(await yellowPixels(regular), 0);
    expect(await yellowPixels(veteran), greaterThan(0));
    veteran
      ..health = 0
      ..enter(FighterState.dead);
    expect(await yellowPixels(veteran), 0);
  });
}
