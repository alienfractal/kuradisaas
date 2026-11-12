import 'package:kuradi_saased/gen/fonts.gen.dart';
import 'cga_palette.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';
import '../../kuradi_saased.dart';
import '../../audio/game_audio_backend.dart';
import '../../utils/game_button.dart';

enum SettingControl { effects, music, crt }

/// Shared volume/CRT icons and effect mode selector for Main Menu and Pause.
class SettingsControls extends Component {
  SettingsControls(this.game);
  final KuradiSaased game;
  @override
  Future<void> onLoad() async {
    if (game.audio.supportedEffectsModes.length > 1) {
      await add(TextComponent(
          text: 'SFX MODE',
          position: Vector2(32, 89),
          anchor: Anchor.topCenter,
          textRenderer: TextPaint(
              style: const TextStyle(
                  fontFamily: FontFamily.arcade,
                  fontSize: 4,
                  color: CgaPalette.white))));
      await add(EffectsModeButton(game));
    }
    for (final kind in SettingControl.values) {
      await add(SettingsButton(game, kind,
          position: Vector2(8, 123 + kind.index * 25)));
    }
  }
}

class EffectsModeButton extends GameButton {
  EffectsModeButton(this.game)
      : super('', () => game.toggleEffectsMode(),
            skin: game.buttonCache.skin,
            position: Vector2(32, 107),
            size: Vector2(48, 18));

  final KuradiSaased game;
  @override
  String get label =>
      game.audio.effectsMode == EffectsMode.midi ? 'MIDI' : 'MP3';

  @override
  void onTapDown(TapDownEvent event) {
    game.notifyUserGesture();
    super.onTapDown(event);
  }
}

class SettingsButton extends PositionComponent with TapCallbacks {
  SettingsButton(this.game, this.kind, {required super.position})
      : super(size: Vector2(28, 24));
  final KuradiSaased game;
  final SettingControl kind;
  double elapsed = 0;
  final text = TextPaint(
      style: const TextStyle(
          fontFamily: FontFamily.arcade, fontSize: 4, color: CgaPalette.white));

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    final settings = game.settings;
    final frames = switch (kind) {
      SettingControl.effects => game.settingsCache.effects,
      SettingControl.music => game.settingsCache.music,
      SettingControl.crt => game.settingsCache.crt,
    };
    final index = switch (kind) {
      SettingControl.effects => settings.effectsIndex,
      SettingControl.music => settings.musicIndex,
      SettingControl.crt =>
        settings.crtEnabled ? (elapsed / .12).floor() % 8 : 0,
    };
    frames[index].render(canvas,
        // CRT art has an empty border around its 16px icon; retain its 32px
        // canvas so the visible icon matches the 17px volume buttons.
        position: kind == SettingControl.crt ? Vector2(-2, -8) : Vector2(5, 0),
        size: Vector2.all(kind == SettingControl.crt ? 32 : 17),
        overridePaint: Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false);
    final label = switch (kind) {
      SettingControl.effects => settings.effectsVolume == 0
          ? 'OFF'
          : '${(settings.effectsVolume * 100).round()}%',
      SettingControl.music => settings.musicVolume == 0
          ? 'OFF'
          : '${(settings.musicVolume * 100).round()}%',
      SettingControl.crt => !game.crt.available
          ? 'N/A'
          : settings.crtEnabled
              ? 'ON'
              : 'OFF',
    };
    text.render(canvas, label, Vector2(14, 19), anchor: Anchor.topCenter);
  }

  @override
  void onTapDown(TapDownEvent event) => game.notifyUserGesture();
  @override
  void onTapUp(TapUpEvent event) {
    switch (kind) {
      case SettingControl.effects:
        game.cycleEffectsVolume();
      case SettingControl.music:
        game.cycleMusicVolume();
      case SettingControl.crt:
        game.toggleCrt();
    }
  }
}
