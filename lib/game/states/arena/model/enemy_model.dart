part of 'fighter_model.dart';

sealed class EnemyModel extends FighterModel {
  EnemyModel(
      {required super.id,
      required super.x,
      required super.y,
      required super.attack,
      required super.maxHealth,
      super.facing = -1});

  AttackSpec get nextAttack;
  double get moveSpeed;
}
