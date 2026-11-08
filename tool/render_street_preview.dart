import 'package:kuradi_saased/gen/fonts.gen.dart';
import 'package:kuradi_saased/gen/assets.gen.dart';
// Run manually with: flutter test tool/render_street_preview.dart
// Headless visual check; no GameWidget, browser, or server is started.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/kuradi_saased.dart';
import 'package:kuradi_saased/audio/audio_player_wrapper.dart';
import 'package:kuradi_saased/gamefsm/game_menu_fsm.dart';
import 'package:kuradi_saased/gamefsm/game_fsm.dart';
import 'package:kuradi_saased/game/states/main_menu/views/lore_view.dart';
import 'package:kuradi_saased/game/states/arena/view/street_scenery.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';
import 'package:kuradi_saased/game/states/arena/handlers/fighter_animation_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('street viewport and original sprite sheets render headlessly',
      () async {
    await (FontLoader(FontFamily.arcade)
          ..addFont(
              rootBundle.load(Assets.resources.fonts.pressStart2PRegular)))
        .load();
    final game = KuradiSaased(audioPlayer: SilentAudioPlayer());
    game.onGameResize(Vector2(1024, 512));
    // ignore: invalid_use_of_internal_member
    await game.load();
    // ignore: invalid_use_of_internal_member
    game.mount();
    await game.ready();
    game.handleIntroInput();
    game.update(GameMenuFsm.logoDuration);
    await game.ready();
    Future<void> snapshot(String name) async {
      // Apply pending world/camera component transforms before a manual render.
      game.update(0);
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final rendered = picture.toImageSync(1024, 512);
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      rendered.dispose();
      picture.dispose();
    }

    expect(game.crt.available, isTrue);
    await snapshot('settings-main-menu-off');
    game.toggleCrt();
    await snapshot('settings-main-menu-crt');
    game.toggleCrt();
    await snapshot('settings-main-menu-restored');
    expect(
        await File('build/settings-main-menu-restored.png').readAsBytes(),
        orderedEquals(
            await File('build/settings-main-menu-off.png').readAsBytes()));
    game.showLore();
    await game.ready();
    expect(game.world, isA<LoreView>());
    game.update(.25);
    final loreRecorder = ui.PictureRecorder();
    game.render(ui.Canvas(loreRecorder));
    final lorePicture = loreRecorder.endRecording();
    final loreImage = lorePicture.toImageSync(1024, 512);
    final loreData = await loreImage.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build').create(recursive: true);
    await File('build/lore-preview.png')
        .writeAsBytes(loreData!.buffer.asUint8List());
    loreImage.dispose();
    lorePicture.dispose();
    game.closeLore();
    await game.ready();
    await game.startGame();
    await game.ready();
    game.update(KuradiSaased.step);
    expect(game.camera.viewport.virtualSize, Vector2(256, 128));
    expect(game.scenarioCache.stars, hasLength(3));
    expect(game.scenarioCache.stars.first.srcPosition.x, 640);
    final mosquitoPresentation = MosquitoAnimationHandler(game.spriteCache);
    final presentation = PlayerAnimationHandler(game.spriteCache);
    for (final (frames, width, height, count) in [
      (game.spriteCache.idle, 80, 99, 4),
      (game.spriteCache.walk, 92, 99, 8),
      (game.spriteCache.punch, 108, 98, 4),
      (game.spriteCache.jump, 61, 99, 5),
      (game.spriteCache.mosquito, 96, 96, 4),
    ]) {
      expect(frames, hasLength(count));
      for (var i = 0; i < count; i++) {
        expect(frames[i].image, same(frames.first.image));
        expect(frames[i].srcSize, Vector2(width.toDouble(), height.toDouble()));
        expect(frames[i].srcPosition, Vector2((i * width).toDouble(), 0));
      }
    }
    expect(
        presentation.displaySize(
            game.combat.player, game.spriteCache.idle.first),
        Vector2(20, 25));
    expect(
        mosquitoPresentation.displaySize(
            game.combat.enemies.whereType<MosquitoModel>().first,
            game.spriteCache.mosquito.first),
        Vector2(32, 32));
    final scenery = game.world.children.whereType<StreetScenery>().single;
    final firstFrame = scenery.stars.animationTicker!.currentIndex;
    game.update(.35);
    expect(scenery.stars.animationTicker!.currentIndex, isNot(firstFrame));

    await snapshot('street-preview-left');
    game.combat.player
      ..x = 560
      ..y = 236;
    game.update(KuradiSaased.step);
    expect(game.camera.viewfinder.position.x, 384);
    await snapshot('street-preview-right');
    for (final enemy in game.combat.enemies) {
      enemy
        ..x = 22
        ..y = 310;
    }
    game.combat.player
      ..x = 320
      ..y = 273
      ..enter(FighterState.idle);
    game.input.jump();
    game.update(.1);
    game.update(.1);
    expect(game.combat.player.airborne, isTrue);
    expect(game.spriteCache.jump,
        contains(presentation.frame(game.combat.player, 0)));
    await snapshot('street-preview-jump');
    game.input.kick();
    game.update(.1);
    game.update(.1);
    expect(game.combat.player.attack, AttackSpec.frontKick);
    expect(game.spriteCache.frontKick,
        contains(presentation.frame(game.combat.player, 0)));
    await snapshot('street-preview-kick');
    for (final spec in [
      AttackSpec.frontKick,
      AttackSpec.highKick,
      AttackSpec.veryHighKick
    ]) {
      final frames = switch (spec.kind) {
        AttackKind.frontKick => game.spriteCache.frontKick,
        AttackKind.highKick => game.spriteCache.highKick,
        _ => game.spriteCache.veryHighKick,
      };
      final low = spec == AttackSpec.frontKick;
      expect(frames.length, low ? 6 : 7);
      game.combat.player
        ..attack = spec
        ..enter(FighterState.active);
      expect(
          presentation.frame(game.combat.player, 0), same(frames[low ? 4 : 5]));
      expect(presentation.displaySize(game.combat.player, frames.first),
          Vector2(24, 24));
      expect(frames.first.srcSize, Vector2(24, 24));
      await snapshot('street-preview-${spec.kind.name}');
      for (final (state, duration, poses) in [
        (
          FighterState.startup,
          spec.startup,
          low ? [0, 1, 2, 3] : [0, 1, 2, 3, 4]
        ),
        (FighterState.active, spec.active, low ? [4, 5] : [5, 6]),
        (
          FighterState.recovery,
          spec.recovery,
          low ? [3, 2, 1, 0] : [4, 3, 2, 1, 0]
        ),
      ]) {
        game.combat.player.enter(state);
        for (var i = 0; i < poses.length; i++) {
          game.combat.player.stateTime = (i + .5) / poses.length * duration;
          expect(presentation.frame(game.combat.player, 0),
              same(frames[poses[i]]));
        }
      }
    }
    game.combat.player
      ..enter(FighterState.idle)
      ..elevation = 0
      ..verticalVelocity = 0;
    final victim = game.combat.enemies.whereType<MosquitoModel>().first
      ..x = 350
      ..y = 273
      ..enter(FighterState.hurt)
      ..stateTime = .11
      ..elevation = 15
      ..lastHitCritical = true
      ..invulnerability = .2;
    game.update(0);
    expect(mosquitoPresentation.frame(victim, 0),
        same(game.spriteCache.mosquitoHit[2]));
    await snapshot('street-preview-mosquito-hit');
    victim
      ..health = 0
      ..enter(FighterState.dead)
      ..stateTime = .20;
    expect(mosquitoPresentation.frame(victim, 0),
        same(game.spriteCache.mosquitoDead[2]));
    await snapshot('street-preview-mosquito-dead');
    game.togglePause();
    await game.ready();
    expect(game.camera.viewport.virtualSize, Vector2(320, 200));
    await snapshot('sprite-buttons-pause');
    game.togglePause();
    await game.ready();
    expect(game.camera.viewport.virtualSize, Vector2(256, 128));
    // A real victory settlement and popup, then the next level's defeat.
    game.combat.player
      ..enter(FighterState.idle)
      ..elevation = 0
      ..verticalVelocity = 0;
    for (final enemy in game.combat.enemies) {
      enemy
        ..health = 0
        ..enter(FighterState.dead)
        ..elevation = 0
        ..verticalVelocity = 0;
    }
    game.update(.1);
    expect(game.levelEnding.showPopup, isFalse);
    for (var i = 0; i < 9; i++) {
      game.update(.1);
    }
    expect(game.levelEnding.showPopup, isTrue);
    await snapshot('street-preview-you-won');
    for (var i = 0; i < 17; i++) {
      game.update(.1);
    }
    expect(game.fsm.phase, GlobalGameState.score);
    await game.ready();
    await snapshot('sprite-buttons-score');
    await game.continueFromScore();
    await game.ready();
    expect(game.levelEnding.active, isFalse);
    game.combat.player
      ..x = 320
      ..y = 273
      ..health = 0
      ..enter(FighterState.dead);
    game.update(.12);
    final deathFrames =
        game.combat.player.deathVariant == PlayerDeathVariant.wound
            ? game.spriteCache.playerDeadWound
            : game.spriteCache.playerDead;
    expect(presentation.frame(game.combat.player, 99), same(deathFrames[0]));
    await snapshot('street-preview-jaan-dying');
    for (var i = 0; i < 6; i++) {
      game.update(.1);
    }
    expect(game.levelEnding.showPopup, isFalse);
    await snapshot('street-preview-jaan-fallen');
    for (var i = 0; i < 4; i++) {
      game.update(.1);
    }
    expect(game.levelEnding.showPopup, isTrue);
    await snapshot('street-preview-jaan-is-down');
    for (var i = 0; i < 17; i++) {
      game.update(.1);
    }
    expect(game.fsm.phase, GlobalGameState.score);
    await game.continueFromScore();
    await game.ready();
    await snapshot('sprite-buttons-end');
    game.removeAll(game.children.toList());
    await game.ready();
    game.onDispose();
  });
}
