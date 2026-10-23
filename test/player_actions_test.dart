import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/kuradi_saased.dart';
import 'package:kuradi_saased/audio/audio_player_wrapper.dart';
import 'package:kuradi_saased/game/view/game_controls_overlay.dart';
import 'package:kuradi_saased/gamefsm/game_menu_fsm.dart';

void main() {
  testWidgets(
      'E/R/Space and touch controls produce the matching one-shot intent',
      (tester) async {
    final game = KuradiSaased(audioPlayer: SilentAudioPlayer());
    await tester.runAsync(() async {
      game.onGameResize(Vector2(800, 600));
      // ignore: invalid_use_of_internal_member
      await game.load();
      // ignore: invalid_use_of_internal_member
      game.mount();
      await game.ready();
      game.handleIntroInput();
      game.update(GameMenuFsm.logoDuration);
      await game.startGame();
      await game.ready();
    });
    game.onKeyEvent(
        const KeyDownEvent(
            timeStamp: Duration.zero,
            physicalKey: PhysicalKeyboardKey.keyE,
            logicalKey: LogicalKeyboardKey.keyE),
        {});
    expect(game.input.consumePunch(), isTrue);
    expect(game.input.consumePunch(), isFalse);
    game.onKeyEvent(
        const KeyDownEvent(
            timeStamp: Duration.zero,
            physicalKey: PhysicalKeyboardKey.keyR,
            logicalKey: LogicalKeyboardKey.keyR),
        {});
    expect(game.input.consumeKick(), isTrue);
    game.onKeyEvent(
        const KeyDownEvent(
            timeStamp: Duration.zero,
            physicalKey: PhysicalKeyboardKey.space,
            logicalKey: LogicalKeyboardKey.space),
        {});
    expect(game.input.consumeJump(), isTrue);
    expect(game.input.consumePunch(), isFalse);
    game.onKeyEvent(
        const KeyRepeatEvent(
            timeStamp: Duration.zero,
            physicalKey: PhysicalKeyboardKey.keyR,
            logicalKey: LogicalKeyboardKey.keyR),
        {});
    expect(game.input.consumeKick(), isFalse);
    await tester.pumpWidget(MaterialApp(home: GameControlsOverlay(game: game)));
    await tester.tap(find.text('JUMP'));
    expect(game.input.consumeJump(), isTrue);
    await tester.tap(find.text('PUNCH'));
    expect(game.input.consumePunch(), isTrue);
    await tester.tap(find.text('KICK'));
    expect(game.input.consumeKick(), isTrue);
    game.input
      ..jump()
      ..kick();
    game.togglePause();
    await tester.pump();
    expect(game.input.consumeJump(), isFalse);
    expect(game.input.consumeKick(), isFalse);
    expect(find.text('KICK'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      game.removeAll(game.children.toList());
      await game.ready();
      game.onDispose();
    });
  });
}
