// Run with flutter test tool/render_grunt_preview.dart.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:kuradi_saased/gen/assets.gen.dart';
import 'package:kuradi_saased/gen/fonts.gen.dart';
import 'package:kuradi_saased/kuradi_saased.dart';
import 'package:kuradi_saased/audio/audio_player_wrapper.dart';
import 'package:kuradi_saased/game/model/campaign_model.dart';
import 'package:kuradi_saased/gamefsm/game_menu_fsm.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render veteran, grunt encounter and knockdown', () async {
    await (FontLoader(FontFamily.arcade)
          ..addFont(
              rootBundle.load(Assets.resources.fonts.pressStart2PRegular)))
        .load();
    final campaign = CampaignModel();
    final game =
        KuradiSaased(campaign: campaign, audioPlayer: SilentAudioPlayer());
    game.onGameResize(Vector2(1024, 512));
    // ignore: invalid_use_of_internal_member
    await game.load();
    // ignore: invalid_use_of_internal_member
    game.mount();
    await game.ready();
    game.handleIntroInput();
    game.update(GameMenuFsm.logoDuration);
    await game.ready();
    await game.startGame();
    Future<void> snapshot(String name) async {
      game.update(0);
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final image = picture.toImageSync(1024, 512);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build').create(recursive: true);
      await File('build/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    for (var level = 0; level < 2; level++) {
      for (final enemy in game.combat.enemies) {
        enemy
          ..health = 0
          ..enter(FighterState.dead);
      }
      for (var i = 0; i < 30; i++) {
        game.update(.1);
      }
      await game.continueFromScore();
      if (level == 0) {
        await game.ready();
        expect(game.campaign.levelIndex, 1);
        final mosquitoes = game.combat.enemies.whereType<MosquitoModel>();
        final veteran =
            mosquitoes.singleWhere((m) => m.rank == MosquitoRank.veteran);
        final regular =
            mosquitoes.firstWhere((m) => m.rank == MosquitoRank.regular);
        game.combat.player
          ..x = 270
          ..y = 273;
        for (final enemy in game.combat.enemies) {
          enemy
            ..x = 460 + enemy.id * 18.0
            ..y = 310;
        }
        regular
          ..x = 220
          ..y = 273
          ..facing = 1;
        veteran
          ..x = 320
          ..y = 273
          ..facing = -1;
        await snapshot('level-2-veteran');
      }
    }
    await game.ready();
    final player = game.combat.player
      ..x = 290
      ..y = 273;
    var small = 0;
    var big = 0;
    for (final enemy in game.combat.enemies) {
      if (enemy.kind == FighterKind.grunt) {
        enemy
          ..x = 330 + big * 60
          ..y = 273
          ..facing = -1;
        big++;
      } else {
        enemy
          ..x = 175.0 + small * 18
          ..y = 260.0 + small * 8;
        small++;
      }
    }
    await snapshot('level-3-grunts');
    game.combat.enemies.firstWhere((e) => e.kind == FighterKind.grunt)
      ..beginAttack(AttackSpec.gruntHeavy)
      ..enter(FighterState.active);
    player
      ..enter(FighterState.knockedDown)
      ..stateTime = .9;
    await snapshot('level-3-knockdown');
    player.enter(FighterState.idle);
    final victim = game.combat.enemies.whereType<GruntModel>().first;
    for (final enemy in game.combat.enemies) {
      enemy.x = 550;
    }
    victim
      ..x = player.x + 23
      ..y = player.y
      ..enter(FighterState.idle);
    void advance(double seconds) {
      for (var i = 0; i < (seconds * 120).ceil(); i++) {
        game.update(1 / 120);
      }
    }

    game.input.kick();
    advance(.20);
    game.input.kick();
    advance(.30);
    game.input.kick();
    advance(.42);
    expect(game.combat.hits, 3);
    expect(victim.elevation, inExclusiveRange(10, 24));
    await snapshot('level-3-kick-launch');
    advance(.5);
    await snapshot('level-3-grunt-ko');
    advance(.4);
    await snapshot('level-3-grunt-getting-up');
    advance(.3);
    victim
      ..health = 1
      ..x = player.x + 20;
    game.input.punch();
    advance(.1);
    expect(victim.state, FighterState.dead);
    advance(.6);
    await snapshot('level-3-grunt-dying');
    advance(.3);
    await snapshot('level-3-grunt-dead');
    game.onDispose();
  });
}
