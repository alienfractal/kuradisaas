import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/gamefsm/game_menu_fsm.dart';
import 'package:kuradi_saased/gamefsm/game_fsm.dart';
import 'package:kuradi_saased/kuradi_saased.dart';
import 'package:kuradi_saased/audio/audio_player_wrapper.dart';
import 'package:kuradi_saased/game/states/main_menu/views/menu_intro_view.dart';
import 'package:kuradi_saased/game/states/main_menu/views/main_menu_view.dart';
import 'package:kuradi_saased/game/states/main_menu/views/lore_view.dart';

void main() {
  test('menu FSM waits for input, holds the logo, then enters main once', () {
    final entered = <MenuState>[];
    final fsm = GameMenuFsm(onEnter: entered.add);
    fsm.begin(showIntro: true);
    fsm.update(100);
    expect(fsm.state, MenuState.intro);
    fsm.acceptInput();
    fsm.update(1);
    fsm.acceptInput();
    expect(fsm.state, MenuState.logo);
    fsm.update(1);
    fsm.update(100);
    fsm.acceptInput();
    expect(entered, [MenuState.intro, MenuState.logo, MenuState.main]);
    fsm.begin(showIntro: false);
    expect(fsm.state, MenuState.main);
  });

  testWidgets('a tap anywhere, including the black margin, reveals the logo',
      (tester) async {
    final game = KuradiSaased(audioPlayer: SilentAudioPlayer());
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await game.loaded;
      await game.ready();
    });
    await tester.pump();
    expect(game.world, isA<MenuIntroView>());
    expect((game.world as MenuIntroView).frameIndex, 0);
    expect(game.menuCache.introFrames[1].srcPosition.x, 256);
    await game.startGame();
    expect(game.menuFsm.state, MenuState.intro);
    await tester.tapAt(const Offset(5, 5));
    expect(game.menuFsm.state, MenuState.logo);
    expect((game.world as MenuIntroView).frameIndex, 1);
    await tester.tapAt(const Offset(5, 5));
    expect(game.menuFsm.state, MenuState.logo);
    game.update(GameMenuFsm.logoDuration);
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.world, isA<MainMenuView>());
    expect(game.fsm.phase, GlobalGameState.menu);
    expect(game.camera.viewport.virtualSize, Vector2(320, 200));
    expect(game.input.consumePunch(), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
  test('lore is a guarded menu sub-state and never skips the opening logo', () {
    final entered = <MenuState>[];
    final fsm = GameMenuFsm(onEnter: entered.add);
    fsm.begin(showIntro: true);
    fsm.openLore();
    fsm.closeLore();
    expect(fsm.state, MenuState.intro);
    fsm.acceptInput();
    fsm.openLore();
    expect(fsm.state, MenuState.logo);
    fsm.update(GameMenuFsm.logoDuration);
    fsm.openLore();
    fsm.openLore();
    fsm.acceptInput();
    fsm.update(100);
    expect(fsm.state, MenuState.lore);
    fsm.closeLore();
    fsm.closeLore();
    expect(entered, [
      MenuState.intro,
      MenuState.logo,
      MenuState.main,
      MenuState.lore,
      MenuState.main
    ]);
  });

  testWidgets(
      'LORE opens its animated world and supports button/keyboard return',
      (tester) async {
    final game = KuradiSaased(audioPlayer: SilentAudioPlayer());
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await game.loaded;
      await game.ready();
    });
    game.handleIntroInput();
    game.update(GameMenuFsm.logoDuration);
    await tester.runAsync(() => game.ready());
    await tester.pump();
    final button = game.camera.viewport.localToParent(Vector2(160, 166));
    await tester.tapAt(Offset(button.x, button.y));
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.world, isA<LoreView>());
    expect(game.menuFsm.state, MenuState.lore);
    expect(game.fsm.phase, GlobalGameState.menu);
    expect(game.camera.viewport.virtualSize, Vector2.all(256));
    expect(game.menuCache.loreFrames.length, 6);
    expect(game.menuCache.loreFrames.last.srcPosition.x, 1280);
    final lore = game.world as LoreView;
    final index = lore.background.animationTicker!.currentIndex;
    final simulationTime = game.combat.player.stateTime;
    game.update(LoreView.frameDuration);
    expect(lore.background.animationTicker!.currentIndex, (index + 1) % 6);
    expect(game.combat.player.stateTime, simulationTime);
    await game.startGame();
    expect(game.fsm.phase, GlobalGameState.menu);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    expect(game.input.consumePunch(), isFalse);
    expect(game.menuFsm.state, MenuState.lore);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.world, isA<MainMenuView>());
    expect(game.camera.viewport.virtualSize, Vector2(320, 200));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.world, isA<LoreView>());
    final back = game.camera.viewport.localToParent(Vector2(128, 239));
    await tester.tapAt(Offset(back.x, back.y));
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.world, isA<MainMenuView>());
    expect(lore.parent, isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.runAsync(() => game.ready());
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.world, isA<MainMenuView>());
    expect(game.campaign.levelIndex, 0);
    expect(game.campaign.totalScore, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
