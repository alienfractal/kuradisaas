part of 'fighter_model.dart';

final class GruntModel extends EnemyModel {
  static const koFallDuration = .56;
  static const koRiseDuration = .35;
  static const gruntDeathDuration = .96;
  AttackSpec _nextAttack = AttackSpec.gruntLight;

  GruntModel(
      {required super.id,
      required super.x,
      required super.y,
      super.facing = -1,
      super.maxHealth = 12})
      : super(attack: AttackSpec.gruntLight);

  @override
  FighterKind get kind => FighterKind.grunt;
  @override
  AttackSpec get nextAttack => _nextAttack;
  @override
  double get moveSpeed => 20;
  @override
  double get knockbackMultiplier => .25;
  @override
  double get deathAnimationDuration => gruntDeathDuration;

  @override
  void enter(FighterState next) {
    // Interrupted windups retain the pending swing; only a strike advances it.
    if (state == FighterState.startup && next == FighterState.active) {
      _nextAttack = attack.kind == AttackKind.gruntLight
          ? AttackSpec.gruntHeavy
          : AttackSpec.gruntLight;
    }
    super.enter(next);
  }
}
