enum MenuState { intro, logo, main, lore }

/// Menu sub-states live inside the global Menu state, separately from combat.
class GameMenuFsm {
  static const logoDuration = 2.0;
  GameMenuFsm({required this.onEnter, this.onExit});
  final void Function(MenuState) onEnter;
  final void Function(MenuState)? onExit;
  MenuState state = MenuState.intro;
  double _logoTime = 0;
  bool _active = false;

  void begin({required bool showIntro}) {
    _logoTime = 0;
    _transition(showIntro ? MenuState.intro : MenuState.main);
  }

  void _transition(MenuState next) {
    if (_active) onExit?.call(state);
    state = next;
    _active = true;
    onEnter(state);
  }

  /// The outer FSM owns whether the menu's lifecycle is active.
  void leave() {
    if (!_active) return;
    onExit?.call(state);
    _active = false;
    _logoTime = 0;
  }

  void acceptInput() {
    if (!_active || state != MenuState.intro) return;
    _logoTime = 0;
    _transition(MenuState.logo);
  }

  void openLore() {
    if (!_active || state != MenuState.main) return;
    _transition(MenuState.lore);
  }

  void closeLore() {
    if (!_active || state != MenuState.lore) return;
    _transition(MenuState.main);
  }

  void update(double dt) {
    if (!_active || state != MenuState.logo) return;
    _logoTime += dt;
    if (_logoTime < logoDuration) return;
    _transition(MenuState.main);
  }
}
