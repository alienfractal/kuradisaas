part of 'fighter_model.dart';

final class PlayerModel extends FighterModel {
  final math.Random _random;
  PlayerDeathVariant deathVariant = PlayerDeathVariant.fall;
  static const playerDeathDuration = .84;
  static const knockdownDuration = 1.05;
  static const getUpDuration = .48;

  PlayerModel(
      {required super.id,
      required super.x,
      required super.y,
      super.facing = 1,
      super.maxHealth = 8,
      math.Random? random})
      : _random = random ?? math.Random(),
        super(attack: AttackSpec.punch);

  @override
  FighterKind get kind => FighterKind.player;
  @override
  double get deathAnimationDuration => playerDeathDuration;
  @override
  double get hitInvulnerability => .7;
  @override
  bool get canMove =>
      state == FighterState.idle || state == FighterState.walking;

  AttackSpec? nextComboAttack;
  int? comboTargetId;
  double comboWindow = 0;
  bool get comboReady => nextComboAttack != null && comboWindow > 0;
  void clearCombo() {
    nextComboAttack = null;
    comboTargetId = null;
    comboWindow = 0;
  }

  @override
  void advanceTimers(double dt) {
    super.advanceTimers(dt);
    comboWindow = math.max(0, comboWindow - dt);
    if (comboWindow == 0) clearCombo();
  }

  @override
  void clearPendingActions() {
    super.clearPendingActions();
    clearCombo();
  }

  @override
  void enter(FighterState next) {
    if (next == FighterState.dead && state != FighterState.dead) {
      deathVariant = PlayerDeathVariant
          .values[_random.nextInt(PlayerDeathVariant.values.length)];
    }
    super.enter(next);
  }

  @override
  void reactToHit(AttackSpec incoming) {
    if (alive && incoming.knockdown) {
      deathVariant = PlayerDeathVariant.fall;
      elevation = 0;
      verticalVelocity = 0;
      jumpTime = 0;
      invulnerability = knockdownDuration + getUpDuration + .5;
      enter(FighterState.knockedDown);
    } else {
      super.reactToHit(incoming);
    }
  }
}
