enum GlobalGameState { menu, loading, level, paused, score, end }

/// Session state is separate from the state of any individual fighter.
class GlobalGameFsm {
  final void Function(GlobalGameState)? onEnter;
  GlobalGameFsm({this.onEnter});
  GlobalGameState phase = GlobalGameState.loading;
  bool transition(GlobalGameState next) {
    final allowed = switch (phase) {
      GlobalGameState.menu => {GlobalGameState.loading},
      GlobalGameState.loading => {GlobalGameState.menu, GlobalGameState.level},
      GlobalGameState.level => {GlobalGameState.paused, GlobalGameState.score},
      GlobalGameState.paused => {GlobalGameState.level, GlobalGameState.menu},
      GlobalGameState.score => {GlobalGameState.loading, GlobalGameState.end},
      GlobalGameState.end => {GlobalGameState.menu},
    };
    if (!allowed.contains(next)) return false;
    phase = next;
    onEnter?.call(next);
    return true;
  }
}
