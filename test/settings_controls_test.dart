import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/audio/audio_player_wrapper.dart';
import 'package:kuradi_saased/game/model/game_settings.dart';
import 'package:kuradi_saased/game/view/settings_controls.dart';
import 'package:kuradi_saased/game/view/cga_palette.dart';
import 'package:kuradi_saased/gamefsm/game_menu_fsm.dart';
import 'package:kuradi_saased/kuradi_saased.dart';

class SettingsAudio extends SilentAudioPlayer {
  double effects = -1, music = -1;
  @override
  Future<void> setSoundFxVolume(double value) async {
    effects = value;
  }

  @override
  Future<void> setMusicVolume(double value) async {
    music = value;
  }
}

void main() {
  test('settings use four independent volume steps and CRT defaults off', () {
    final settings = GameSettings();
    expect(settings.crtEnabled, isFalse);
    expect(settings.effectsVolume, 1);
    expect(settings.musicVolume, closeTo(1 / 3, .0001));
    final seen = <double>[];
    for (var i = 0; i < 4; i++) {
      seen.add(settings.effectsVolume);
      settings.cycleEffects();
    }
    expect(seen, GameSettings.volumeLevels);
    expect(settings.effectsVolume, 1);
    expect(settings.musicIndex, 2);
  });

  testWidgets('shared icons change real settings in Main Menu and Pause',
      (tester) async {
    final audio = SettingsAudio();
    final game = KuradiSaased(audioPlayer: audio);
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await game.loaded;
      await game.ready();
    });
    game.handleIntroInput();
    game.update(GameMenuFsm.logoDuration);
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.crt.available, isTrue);
    expect(game.settingsCache.effects, hasLength(4));
    expect(game.settingsCache.music, hasLength(4));
    expect(game.settingsCache.crt, hasLength(8));
    await tester.runAsync(() async {
      // Inspect the actual loaded sheets, including every animation frame.
      final colors = <int>{};
      final alphas = <int>{};
      for (final sheet in [
        game.settingsCache.effects.first.image,
        game.settingsCache.music.first.image,
        game.settingsCache.crt.first.image,
      ]) {
        final data =
            await sheet.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
        final pixels = data!.buffer.asUint8List();
        for (var i = 0; i < pixels.length; i += 4) {
          alphas.add(pixels[i + 3]);
          if (pixels[i + 3] == 0) continue;
          colors.add((pixels[i] << 16) | (pixels[i + 1] << 8) | pixels[i + 2]);
        }
      }
      expect(colors, isNotEmpty);
      expect(colors.difference(CgaPalette.rgb.toSet()), isEmpty);
      expect(alphas.difference({0, 255}), isEmpty);
    });
    expect(audio.effects, 1);
    expect(audio.music, closeTo(1 / 3, .0001));
    expect(game.world.children.whereType<SettingsControls>(), hasLength(1));

    Future<void> tap(double y) async {
      final point = game.camera.viewport.localToParent(Vector2(22, y));
      await tester.tapAt(Offset(point.x, point.y));
      await tester.pump(const Duration(milliseconds: 50));
    }

    for (var i = 0; i < 3; i++) {
      await tap(135);
    }
    expect(game.settings.effectsVolume, 0);
    expect(audio.effects, 0);
    await tap(135);
    expect(audio.effects, 1);
    await tap(160);
    expect(audio.music, 0);
    await tap(185);
    expect(game.settings.crtEnabled, isTrue);

    game.showLore();
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.settings.crtEnabled, isTrue);
    game.closeLore();
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.settings.musicIndex, 3);
    await tester.runAsync(() => game.startGame());
    await tester.runAsync(() => game.ready());
    await tester.pump();
    game.togglePause();
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.world.children.whereType<SettingsControls>(), hasLength(1));
    final time = game.combat.player.stateTime;
    await tap(160);
    expect(audio.music, 1);
    await tap(185);
    expect(game.settings.crtEnabled, isFalse);
    expect(game.combat.player.stateTime, time);
    game.togglePause();
    await tester.runAsync(() => game.ready());
    await tester.pump();
    expect(game.settings.musicIndex, 0);
    expect(game.settings.effectsIndex, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
