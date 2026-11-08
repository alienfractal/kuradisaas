import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/audio/audio_player_wrapper.dart';
import 'package:kuradi_saased/game/model/game_settings.dart';
import 'package:kuradi_saased/game/view/settings_controls.dart';
import 'package:kuradi_saased/gen/assets.gen.dart';
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
    // UI sheets must retain the actual source images, colors and transparency.
    for (final (frames, path) in [
      (game.settingsCache.effects, Assets.resources.images.soundfxVolume.path),
      (game.settingsCache.music, Assets.resources.images.musicfxVolume.path),
      (game.settingsCache.crt, Assets.resources.images.crton32x328.path),
    ]) {
      for (final frame in frames) {
        expect(frame.image, same(game.images.fromCache(path)));
      }
    }
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
