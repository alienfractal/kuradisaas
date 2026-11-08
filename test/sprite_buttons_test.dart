import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/audio/audio_player_wrapper.dart';
import 'package:kuradi_saased/game/states/main_menu/views/lore_view.dart';
import 'package:kuradi_saased/game/states/main_menu/views/main_menu_view.dart';
import 'package:kuradi_saased/game/states/pause/views/pause_view.dart';
import 'package:kuradi_saased/gamefsm/game_fsm.dart';
import 'package:kuradi_saased/gamefsm/game_menu_fsm.dart';
import 'package:kuradi_saased/kuradi_saased.dart';
import 'package:kuradi_saased/utils/game_button.dart';
import 'package:kuradi_saased/gen/assets.gen.dart';

Future<void> expectOriginalButtonColors(GameButton button) async {
  final source = await button.skin.sprite.image
      .toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  final recorder = ui.PictureRecorder();
  button.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = picture.toImageSync(190, 20);
  final rendered =
      await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  var checked = 0;
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      final src = (y * 100 + x) * 4;
      if (source!.getUint8(src + 3) != 255) continue;
      final dst = (y * 190 + x) * 4;
      expect(rendered!.buffer.asUint8List(dst, 4),
          orderedEquals(source.buffer.asUint8List(src, 4)));
      checked++;
    }
  }
  expect(checked, greaterThan(0));
  image.dispose();
  picture.dispose();
}

void main() {
  test('leaving outer Menu exits the submenu and stops its timer/input', () {
    final events = <String>[];
    final menu = GameMenuFsm(
        onEnter: (state) => events.add('enter $state'),
        onExit: (state) => events.add('exit $state'));
    menu.begin(showIntro: true);
    menu.acceptInput();
    menu.leave();
    menu.leave();
    menu.update(99);
    menu.openLore();
    menu.acceptInput();
    expect(events, [
      'enter MenuState.intro',
      'exit MenuState.intro',
      'enter MenuState.logo',
      'exit MenuState.logo',
    ]);
    menu.begin(showIntro: false);
    expect(events.last, 'enter MenuState.main');
    menu.openLore();
    expect(events.sublist(events.length - 2),
        ['exit MenuState.main', 'enter MenuState.lore']);
  });

  testWidgets('cached sprite buttons cancel, disable and route through the FSM',
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
    expect(
        game.stateSpriteServices.keys.toSet(), GlobalGameState.values.toSet());
    expect(
        game.stateSpriteServices[GlobalGameState.level], same(game.levelCache));
    expect(() => game.stateSpriteServices.clear(), throwsUnsupportedError);
    final menu = game.world as MainMenuView;
    final start = menu.primaryButton!;
    expect(start.skin.sprite.image,
        same(game.images.fromCache(Assets.resources.images.buttonstart.path)));
    await tester.runAsync(() => expectOriginalButtonColors(start));
    expect(start.skin.sprite, same(game.menuCache.startButton.sprite));
    expect(game.pauseCache.resumeButton.sprite, same(start.skin.sprite));
    expect(game.scoreCache.continueButton.sprite, same(start.skin.sprite));
    expect(game.endCache.menuButton.sprite, same(start.skin.sprite));

    Offset point(double x, double y) {
      final position = game.camera.viewport.localToParent(Vector2(x, y));
      return Offset(position.x, position.y);
    }

    final press = await tester.startGesture(point(160, 144));
    await tester.pump();
    expect(start.pressed, isTrue);
    await tester.runAsync(() => expectOriginalButtonColors(start));
    await press.cancel();
    await tester.pump();
    expect(start.pressed, isFalse);
    expect(game.fsm.phase, GlobalGameState.menu);
    start.enabled = false;
    await tester.tapAt(point(160, 144));
    expect(game.fsm.phase, GlobalGameState.menu);
    start.enabled = true;
    await tester.tapAt(point(160, 166));
    await tester.runAsync(() => game.ready());
    await tester.pump();
    final lore = game.world as LoreView;
    expect(menu.parent, isNull);
    expect(lore.children.whereType<GameButton>().single.skin.sprite,
        same(game.menuCache.backButton.sprite));
    await tester.tapAt(point(128, 239));
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.menuFsm.state, MenuState.main);
    expect(lore.parent, isNull);
    await tester.runAsync(() => game.startGame());
    game.menuFsm.openLore();
    expect(game.menuFsm.state, MenuState.main);
    expect(game.fsm.phase, GlobalGameState.level);
    game.togglePause();
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect((game.world as PauseView).sprites, same(game.pauseCache));
    await tester.tapAt(point(160, 120));
    expect(game.fsm.phase, GlobalGameState.level);
    game.togglePause();
    await tester.runAsync(() => game.ready());
    await tester.pump();
    await tester.tapAt(point(160, 150));
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.fsm.phase, GlobalGameState.menu);
    expect(game.menuFsm.state, MenuState.main);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
