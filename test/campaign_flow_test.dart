import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/game/model/campaign_model.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';
import 'package:kuradi_saased/game/view/game_controls_overlay.dart';
import 'package:kuradi_saased/game/states/main_menu/views/main_menu_view.dart';
import 'package:kuradi_saased/game/states/loading/views/loading_view.dart';
import 'package:kuradi_saased/game/states/score/view/score_screen_view.dart';
import 'package:kuradi_saased/game/states/end/views/end_screen_view.dart';
import 'package:kuradi_saased/game/states/pause/views/pause_view.dart';
import 'package:kuradi_saased/game/states/arena/view/arena_view.dart';
import 'package:kuradi_saased/game/states/arena/view/player_entity.dart';
import 'package:kuradi_saased/game/states/arena/view/mosquito_entity.dart';
import 'package:kuradi_saased/game/states/arena/view/grunt_entity.dart';
import 'package:kuradi_saased/gamefsm/game_fsm.dart';
import 'package:kuradi_saased/kuradi_saased.dart';
import 'package:kuradi_saased/audio/audio_player_wrapper.dart';
import 'package:kuradi_saased/gamefsm/game_menu_fsm.dart';
import 'package:kuradi_saased/game/states/main_menu/views/menu_intro_view.dart';

void main() {
  test('scores are counted once, carry across levels, and reset for a new run',
      () {
    final campaign = CampaignModel();
    expect(campaign.advance(), isFalse);
    const result =
        LevelResult(cleared: true, hits: 15, defeated: 5, healthRemaining: 6);
    campaign.recordResult(result);
    campaign.recordResult(result);
    expect(campaign.totalScore, 800);
    expect(campaign.canAdvance, isTrue);
    expect(campaign.advance(), isTrue);
    expect(campaign.levelIndex, 1);
    expect(campaign.result, isNull);
    expect(campaign.totalScore, 800);
    campaign.recordResult(const LevelResult(
        cleared: true, hits: 21, defeated: 7, healthRemaining: 4));
    expect(campaign.canAdvance, isTrue);
    expect(campaign.totalScore, 1810);
    expect(campaign.advance(), isTrue);
    expect(campaign.level.gruntCount, 2);
    campaign.recordResult(const LevelResult(
        cleared: true, hits: 30, defeated: 7, healthRemaining: 2));
    expect(campaign.completed, isTrue);
    expect(campaign.advance(), isFalse);
    expect(campaign.totalScore, 2860);
    campaign.reset();
    expect(campaign.levelIndex, 0);
    expect(campaign.totalScore, 0);
    expect(campaign.result, isNull);
  });

  test('defeat keeps earned points and cannot advance', () {
    final campaign = CampaignModel();
    campaign.recordResult(const LevelResult(
        cleared: false, hits: 4, defeated: 1, healthRemaining: 0));
    expect(campaign.totalScore, 140);
    expect(campaign.canAdvance, isFalse);
    expect(campaign.completed, isFalse);
    expect(campaign.advance(), isFalse);
  });

  testWidgets('menu -> loading -> level -> score -> next level -> end -> menu',
      (tester) async {
    final game = KuradiSaased(audioPlayer: SilentAudioPlayer());
    final visited = <GlobalGameState>[];
    game.phase.addListener(() => visited.add(game.phase.value));
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
          home: SizedBox(
        width: 800,
        height: 600,
        child: GameWidget<KuradiSaased>(game: game, overlayBuilderMap: {
          'controls': (_, game) => GameControlsOverlay(game: game)
        }, initialActiveOverlays: const [
          'controls'
        ]),
      )));
      await game.loaded.timeout(const Duration(seconds: 5),
          onTimeout: () => throw StateError('initial game load timed out'));
      await tester.pump();
      await game.ready().timeout(const Duration(seconds: 5),
          onTimeout: () => throw StateError('initial game mount timed out'));
    });
    await tester.pump();
    expect(game.fsm.phase, GlobalGameState.menu);
    expect(game.menuFsm.state, MenuState.intro);
    expect((game.world as MenuIntroView).frameIndex, 0);
    expect(game.camera.viewport.virtualSize, Vector2.all(256));
    game.update(5);
    expect(game.menuFsm.state, MenuState.intro);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyQ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyQ);
    expect(game.menuFsm.state, MenuState.logo);
    expect((game.world as MenuIntroView).frameIndex, 1);
    game.update(1);
    game.handleIntroInput();
    expect(game.menuFsm.state, MenuState.logo);
    game.update(1);
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.menuFsm.state, MenuState.main);
    expect(game.world, isA<MainMenuView>());
    expect(
        (game.world as MainMenuView).primaryButton!.label, 'ENTER THE SWARM');

    await tester.runAsync(() async {
      final loading = game.startGame();
      expect(game.fsm.phase, GlobalGameState.loading);
      expect(game.world, isA<LoadingView>());
      await loading.timeout(const Duration(seconds: 5));
    });
    expect(game.fsm.phase, GlobalGameState.level);
    expect(game.world, isA<ArenaView>());
    final currentArena = game.world;
    game.togglePause();
    expect(game.world, isA<PauseView>());
    game.update(1);
    expect(game.combat.player.stateTime, 0);
    game.togglePause();
    expect(identical(game.world, currentArena), isTrue);
    for (final enemy in game.combat.enemies) {
      enemy.health = 0;
      enemy.enter(FighterState.dead);
    }
    game.update(KuradiSaased.step);
    expect(game.fsm.phase, GlobalGameState.level); // Death burst stays visible.
    for (var i = 0; i < 10; i++) {
      game.update(.1);
    }
    expect(game.levelEnding.showPopup, isTrue);
    expect(game.combatInputEnabled.value, isFalse);
    expect(game.campaign.result, isNull);
    for (var i = 0; i < 17; i++) {
      game.update(.1);
    }
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.fsm.phase, GlobalGameState.score);
    expect(game.world, isA<GameScoreView>());
    expect(
        (game.world as GameScoreView).primaryButton!.label, 'LOAD NEXT LEVEL');
    expect(currentArena.parent, isNull);
    final firstScore = game.campaign.totalScore;
    game.update(1);
    expect(game.campaign.totalScore, firstScore);

    await tester.runAsync(() async {
      final nextLoading = game.continueFromScore();
      expect(game.fsm.phase, GlobalGameState.loading);
      expect(game.world, isA<LoadingView>());
      await nextLoading.timeout(const Duration(seconds: 5));
    });
    expect(game.fsm.phase, GlobalGameState.level);
    expect(game.campaign.levelIndex, 1);
    expect(game.combat.enemies.length, 7);
    final secondArena = game.world as ArenaView;
    expect(secondArena.children.whereType<PlayerEntity>().single.model,
        same(game.combat.player));
    expect(secondArena.children.whereType<MosquitoEntity>(), hasLength(7));
    expect(secondArena.children.whereType<GruntEntity>(), isEmpty);
    expect(
        game.combat.enemies
            .whereType<MosquitoModel>()
            .where((m) => m.rank == MosquitoRank.veteran),
        hasLength(1));
    expect(game.combat.player.health, 8);
    expect(game.levelEnding.active, isFalse);
    expect(game.combatInputEnabled.value, isTrue);
    expect(game.campaign.totalScore, firstScore);
    for (final enemy in game.combat.enemies) {
      enemy.health = 0;
      enemy.enter(FighterState.dead);
    }
    game.update(KuradiSaased.step);
    expect(game.fsm.phase, GlobalGameState.level);
    for (var i = 0; i < 10; i++) {
      game.update(.1);
    }
    expect(game.levelEnding.showPopup, isTrue);
    expect(game.combatInputEnabled.value, isFalse);
    expect(game.campaign.result, isNull);
    for (var i = 0; i < 17; i++) {
      game.update(.1);
    }
    expect(game.fsm.phase, GlobalGameState.score);
    await tester.runAsync(() => game.continueFromScore());
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.fsm.phase, GlobalGameState.level);
    expect(game.campaign.levelIndex, 2);
    final thirdArena = game.world as ArenaView;
    expect(thirdArena.children.whereType<GruntEntity>(), hasLength(2));
    expect(thirdArena.children.whereType<MosquitoEntity>(), hasLength(5));
    for (final entity in thirdArena.children.whereType<GruntEntity>()) {
      expect(game.combat.enemies, contains(same(entity.model)));
    }
    expect(game.combat.enemies.where((e) => e.kind == FighterKind.grunt),
        hasLength(2));
    expect(game.combat.enemies.where((e) => e.kind != FighterKind.grunt),
        hasLength(5));
    for (final enemy in game.combat.enemies) {
      enemy.health = 0;
      enemy.enter(FighterState.dead);
    }
    for (var i = 0; i < 30; i++) {
      game.update(.1);
    }
    expect(game.fsm.phase, GlobalGameState.score);
    await tester.runAsync(() => game.continueFromScore());
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.fsm.phase, GlobalGameState.end);
    expect(game.world, isA<GameEndView>());
    expect((game.world as GameEndView).completed, isTrue);
    // Exercise the real Flame button through its camera/viewport hit testing.
    final buttonPosition =
        game.camera.viewport.localToParent(Vector2(160, 160));
    await tester.tapAt(Offset(buttonPosition.x, buttonPosition.y));
    await tester.pump(const Duration(milliseconds: 50));
    expect(game.fsm.phase, GlobalGameState.menu);
    expect(game.world, isA<MainMenuView>());

    // A fresh run also exercises the defeat -> score -> end route.
    await tester.runAsync(() => game.startGame());
    expect(game.campaign.totalScore, 0);
    expect(game.campaign.levelIndex, 0);
    game.combat.player.health = 0;
    game.combat.player.enter(FighterState.dead);
    game.update(KuradiSaased.step);
    expect(game.fsm.phase, GlobalGameState.level);
    expect(game.levelEnding.active, isTrue);
    game.primaryAction(); // Enter cannot skip the death animation.
    for (var i = 0; i < 10; i++) {
      game.update(.1);
    }
    expect(game.levelEnding.showPopup, isTrue);
    expect(game.levelEnding.result!.cleared, isFalse);
    game.togglePause();
    final elapsed = game.levelEnding.elapsed;
    game.update(5);
    expect(game.levelEnding.elapsed, elapsed);
    game.togglePause();
    for (var i = 0; i < 17; i++) {
      game.update(.1);
    }
    expect(game.fsm.phase, GlobalGameState.score);
    await tester.runAsync(() => game.continueFromScore());
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.fsm.phase, GlobalGameState.end);
    expect(game.world, isA<GameEndView>());
    expect((game.world as GameEndView).completed, isFalse);
    game.primaryAction();
    expect(game.fsm.phase, GlobalGameState.menu);
    expect(
        visited,
        containsAllInOrder([
          GlobalGameState.menu,
          GlobalGameState.loading,
          GlobalGameState.level,
          GlobalGameState.paused,
          GlobalGameState.level,
          GlobalGameState.score,
          GlobalGameState.loading,
          GlobalGameState.level,
          GlobalGameState.score,
          GlobalGameState.end,
          GlobalGameState.menu,
        ]));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
