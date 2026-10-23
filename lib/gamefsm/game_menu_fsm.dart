enum MenuState { intro, logo, main, lore }

/// Menu sub-states live inside the global Menu state, separately from combat.
class GameMenuFsm {
  static const logoDuration = 2.0;
  GameMenuFsm({required this.onEnter});
  final void Function(MenuState) onEnter;
  MenuState state = MenuState.intro;
  double _logoTime = 0;

  void begin({required bool showIntro}) {
    _logoTime = 0;
    state = showIntro ? MenuState.intro : MenuState.main;
    onEnter(state);
  }

  void acceptInput() {
    if (state != MenuState.intro) return;
    state = MenuState.logo;
    _logoTime = 0;
    onEnter(state);
  }

  void openLore() {
    if (state != MenuState.main) return;
    state = MenuState.lore;
    onEnter(state);
  }

  void closeLore() {
    if (state != MenuState.lore) return;
    state = MenuState.main;
    onEnter(state);
  }

  void update(double dt) {
    if (state != MenuState.logo) return;
    _logoTime += dt;
    if (_logoTime < logoDuration) return;
    state = MenuState.main;
    onEnter(state);
  }
}
