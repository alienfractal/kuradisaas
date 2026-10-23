import 'dart:math' as math;
import 'dart:async';
import 'audio/audio_player_wrapper.dart';
import 'audio/game_audio_player.dart';
import 'audio/game_audio_service.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'gamefsm/game_fsm.dart';
import 'gamefsm/game_menu_fsm.dart';
import 'game/model/campaign_model.dart';
import 'game/model/game_settings.dart';
import 'game/services/settings_cache_service.dart';
import 'game/view/settings_controls.dart';
import 'game/view/crt_renderer.dart';
import 'game/model/level_ending_model.dart';
import 'game/states/arena/services/combat_logic_service.dart';
import 'game/states/arena/services/fighter_cache_service.dart';
import 'game/states/arena/services/input_service.dart';
import 'game/states/arena/view/arena_view.dart';
import 'game/states/arena/model/arena_config.dart';
import 'game/states/arena/services/scenario_cache_service.dart';
import 'game/view/arena_hud.dart';
import 'game/view/level_result_popup.dart';
import 'game/view/pixel_perfect_viewport.dart';
import 'game/states/main_menu/views/main_menu_view.dart';
import 'game/states/main_menu/views/menu_intro_view.dart';
import 'game/states/main_menu/views/lore_view.dart';
import 'game/states/main_menu/services/menu_cache_service.dart';
import 'game/states/loading/views/loading_view.dart';
import 'game/states/score/view/score_screen_view.dart';
import 'game/states/end/views/end_screen_view.dart';
import 'game/states/pause/views/pause_view.dart';

class KuradiSaased extends FlameGame with KeyboardEvents, TapCallbacks {
  late final fsm = GlobalGameFsm(onEnter: _enterState);
  late final menuFsm = GameMenuFsm(onEnter: _enterMenuState);
  final phase = ValueNotifier(GlobalGameState.loading);
  final input = InputService();
  final GameAudioService audio;
  final levelEnding = LevelEndingModel();
  final combatInputEnabled = ValueNotifier(false);
  final spriteCache = FighterCacheService();
  final scenarioCache = ScenarioCacheService();
  final menuCache = MenuCacheService();
  final settings = GameSettings();
  final settingsCache = SettingsCacheService();
  final crt = CrtRenderer();
  bool _introCompleted = false;
  final CampaignModel campaign;
  String? loadingError;
  int _loadToken = 0;
  ArenaView? _levelView;
  CombatLogicService combat = CombatLogicService();
  bool showDebug = false;
  double _accumulator = 0;
  static const step = 1 / 120;
  KuradiSaased({CampaignModel? campaign, AudioPlayerWrapper? audioPlayer})
      : audio = GameAudioService(audioPlayer ?? GameAudioPlayer()),
        campaign = campaign ?? CampaignModel();
  @override
  Color backgroundColor() => const Color(0xFF000000);
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewport = FixedResolutionViewport(resolution: Vector2(320, 200));
    camera.viewfinder.anchor = Anchor.topLeft;
    switchToWorld(LoadingView(description: 'SPRITES'));
    await spriteCache.preload(this);
    await scenarioCache.preload(this);
    await menuCache.preload(this);
    await settingsCache.preload(this);
    await crt.preload();
    await audio.setVolumes(
        effects: settings.effectsVolume, music: settings.musicVolume);
    await audio.preload();
    _changePhase(GlobalGameState.menu);
  }

  void _changePhase(GlobalGameState next) {
    if (!fsm.transition(next)) return;
    input.clear();
    _accumulator = 0;
    combatInputEnabled.value =
        fsm.phase == GlobalGameState.level && !levelEnding.active;
    phase.value = fsm.phase;
  }

  /// Like Revalia, entering a global state selects that state's Flame World.
  void _enterState(GlobalGameState state) {
    if (state != GlobalGameState.menu && state != GlobalGameState.level) {
      audio.leaveScreen();
    }
    if (state == GlobalGameState.level) audio.beginLevel(combat);
    switch (state) {
      case GlobalGameState.menu:
        _levelView = null;
        menuFsm.begin(showIntro: !_introCompleted);
      case GlobalGameState.loading:
        switchToWorld(LoadingView(description: campaign.level.title));
      case GlobalGameState.level:
        switchToWorld(_levelView!);
      case GlobalGameState.paused:
        switchToWorld(PauseView(
            onResume: togglePause,
            onMenu: showMenu,
            settingsControls: SettingsControls(this)));
      case GlobalGameState.score:
        _levelView = null;
        switchToWorld(GameScoreView(
            result: campaign.result!,
            levelNumber: campaign.levelIndex + 1,
            levelCount: campaign.levels.length,
            totalScore: campaign.totalScore,
            hasNextLevel: campaign.hasNextLevel,
            onContinue: primaryAction));
      case GlobalGameState.end:
        switchToWorld(GameEndView(
            completed: campaign.completed,
            totalScore: campaign.totalScore,
            onMenu: showMenu));
    }
  }

  void _enterMenuState(MenuState state) {
    audio.enterMenu(state);
    switch (state) {
      case MenuState.intro:
        switchToWorld(MenuIntroView(menuCache.introFrames, 0));
      case MenuState.logo:
        switchToWorld(MenuIntroView(menuCache.introFrames, 1));
      case MenuState.main:
        _introCompleted = true;
        switchToWorld(MainMenuView(
            onStart: primaryAction,
            onLore: showLore,
            settingsControls: SettingsControls(this),
            loadingError: loadingError));
      case MenuState.lore:
        switchToWorld(
            LoreView(frames: menuCache.loreFrames, onBack: closeLore));
    }
  }

  void cycleEffectsVolume() {
    settings.cycleEffects();
    unawaited(audio.player.setSoundFxVolume(settings.effectsVolume));
  }

  void cycleMusicVolume() {
    settings.cycleMusic();
    unawaited(audio.player.setMusicVolume(settings.musicVolume));
  }

  void toggleCrt() {
    if (!crt.available) return;
    settings.crtEnabled = !settings.crtEnabled;
    if (!settings.crtEnabled) crt.releaseFrame();
  }

  @override
  void render(Canvas canvas) {
    if (settings.crtEnabled && crt.available) {
      crt.render(canvas, canvasSize.toSize(), (target) => super.render(target));
    } else {
      super.render(canvas);
    }
  }

  void showLore() {
    if (fsm.phase != GlobalGameState.menu) return;
    input.clear();
    menuFsm.openLore();
  }

  void closeLore() {
    if (fsm.phase != GlobalGameState.menu) return;
    input.clear();
    menuFsm.closeLore();
  }

  void handleIntroInput() {
    if (fsm.phase == GlobalGameState.menu) menuFsm.acceptInput();
  }

  @override
  void onTapDown(TapDownEvent event) {
    notifyUserGesture();
    handleIntroInput();
  }

  void notifyUserGesture() => audio.notifyUserGesture();

  void switchToWorld(World nextWorld) {
    world = nextWorld;
    final playing = nextWorld is ArenaView;
    camera.viewport = PixelPerfectViewport(
        devicePixelRatio: _devicePixelRatio,
        resolution: playing
            ? Vector2(ArenaConfig.viewWidth, ArenaConfig.viewHeight)
            : nextWorld is MenuIntroView || nextWorld is LoreView
                ? Vector2.all(256)
                : Vector2(320, 200),
        children: [ArenaHud(this), LevelResultPopup(this)]);
    camera.viewfinder.position =
        playing ? _arenaCameraPosition() : Vector2.zero();
  }

  Vector2 _arenaCameraPosition() => Vector2(
      combat.config.cameraX(combat.player.x),
      combat.config.cameraY(combat.player.y));

  double get _devicePixelRatio =>
      WidgetsBinding
          .instance.platformDispatcher.implicitView?.devicePixelRatio ??
      1;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final viewport = camera.viewport;
    if (viewport is PixelPerfectViewport) {
      viewport.devicePixelRatio = _devicePixelRatio;
    }
  }

  Future<void> startGame() async {
    if (fsm.phase != GlobalGameState.menu || menuFsm.state != MenuState.main) {
      return;
    }
    campaign.reset();
    await _loadLevel();
  }

  Future<void> _loadLevel() async {
    final token = ++_loadToken;
    loadingError = null;
    levelEnding.reset();
    _changePhase(GlobalGameState.loading);
    try {
      final definition = campaign.level;
      combat = CombatLogicService(
          config: definition.arena, enemyCount: definition.enemyCount);
      final nextLevel =
          ArenaView(combat, spriteCache, () => showDebug, scenarioCache);
      _levelView = nextLevel;
      // Load and mount off-camera while LoadingView remains the visible world.
      await add(nextLevel);
      await ready();
      if (token == _loadToken && fsm.phase == GlobalGameState.loading) {
        _changePhase(GlobalGameState.level);
      }
    } catch (error) {
      if (token != _loadToken) return;
      loadingError = 'Could not load the level: $error';
      _changePhase(GlobalGameState.menu);
    }
  }

  Future<void> continueFromScore() async {
    if (fsm.phase != GlobalGameState.score) return;
    if (campaign.advance()) {
      await _loadLevel();
    } else {
      _changePhase(GlobalGameState.end);
    }
  }

  void primaryAction() {
    switch (fsm.phase) {
      case GlobalGameState.menu:
        if (menuFsm.state == MenuState.main) {
          startGame();
        } else if (menuFsm.state == MenuState.lore) {
          closeLore();
        } else {
          handleIntroInput();
        }
      case GlobalGameState.paused:
        togglePause();
      case GlobalGameState.score:
        continueFromScore();
      case GlobalGameState.end:
        showMenu();
      case GlobalGameState.loading || GlobalGameState.level:
        break;
    }
  }

  void togglePause() {
    if (fsm.phase == GlobalGameState.level) {
      _changePhase(GlobalGameState.paused);
    } else if (fsm.phase == GlobalGameState.paused) {
      _changePhase(GlobalGameState.level);
    }
  }

  void showMenu() {
    if (fsm.phase != GlobalGameState.end &&
        fsm.phase != GlobalGameState.paused) {
      return;
    }
    ++_loadToken;
    _changePhase(GlobalGameState.menu);
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state != AppLifecycleState.resumed) {
      audio.suspend();
    } else if (fsm.phase == GlobalGameState.menu) {
      audio.resumeMenu(menuFsm.state);
    }
    if (state != AppLifecycleState.resumed &&
        fsm.phase == GlobalGameState.level) {
      _changePhase(GlobalGameState.paused);
    }
  }

  @override
  void update(double dt) {
    if (fsm.phase == GlobalGameState.menu) {
      menuFsm.update(dt);
      super.update(dt);
      return;
    }
    if (fsm.phase != GlobalGameState.level) {
      super.update(0);
      return;
    }
    _accumulator += math.min(dt, .1);
    while (_accumulator >= step) {
      if (!levelEnding.showPopup) {
        combat.update(step, input);
        audio.handleStep(combat);
      }
      _accumulator -= step;
      if (!levelEnding.active && (!combat.player.alive || combat.won)) {
        // Latch the outcome once; settlement cannot change score or victory.
        levelEnding.begin(LevelResult(
            cleared: combat.player.alive && combat.won,
            hits: combat.hits,
            defeated: combat.defeated,
            healthRemaining: combat.player.health));
        input.clear();
        combatInputEnabled.value = false;
        audio.stopWalking();
      }
      levelEnding.update(step,
          animationsFinished: combat.endingAnimationsFinished);
      if (levelEnding.complete) {
        campaign.recordResult(levelEnding.result!);
        _changePhase(GlobalGameState.score);
        break;
      }
    }
    if (fsm.phase == GlobalGameState.level) {
      camera.viewfinder.position = _arenaCameraPosition();
    }
    super.update(dt);
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) notifyUserGesture();
    if (fsm.phase == GlobalGameState.menu && menuFsm.state == MenuState.lore) {
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.enter)) {
        closeLore();
      }
      return KeyEventResult.handled;
    }
    if (fsm.phase == GlobalGameState.menu && menuFsm.state != MenuState.main) {
      if (event is KeyDownEvent) handleIntroInput();
      return KeyEventResult.handled;
    }
    if (fsm.phase == GlobalGameState.level && levelEnding.active) {
      input.clear();
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.keyP)) {
        togglePause();
      }
      return KeyEventResult.handled;
    }
    final directions = {
      LogicalKeyboardKey.arrowLeft: 'left',
      LogicalKeyboardKey.keyA: 'left',
      LogicalKeyboardKey.arrowRight: 'right',
      LogicalKeyboardKey.keyD: 'right',
      LogicalKeyboardKey.arrowUp: 'up',
      LogicalKeyboardKey.keyW: 'up',
      LogicalKeyboardKey.arrowDown: 'down',
      LogicalKeyboardKey.keyS: 'down',
    };
    input.keyboard
      ..clear()
      ..addAll(
          keysPressed.where(directions.containsKey).map((k) => directions[k]!));
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyL &&
          fsm.phase == GlobalGameState.menu) {
        showLore();
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        primaryAction();
      } else if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.keyP) {
        togglePause();
      } else if (event.logicalKey == LogicalKeyboardKey.f1) {
        showDebug = !showDebug;
      } else if (event.logicalKey == LogicalKeyboardKey.keyE) {
        if (fsm.phase == GlobalGameState.level) input.punch();
      } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
        if (fsm.phase == GlobalGameState.level) input.kick();
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        if (fsm.phase == GlobalGameState.level) input.jump();
      }
    }
    return KeyEventResult.handled;
  }

  @override
  void onDispose() {
    settingsCache.dispose();
    crt.dispose();
    unawaited(audio.dispose());
    super.onDispose();
  }
}
