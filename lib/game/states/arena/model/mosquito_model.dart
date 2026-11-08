part of 'fighter_model.dart';

enum MosquitoRank { regular, veteran }

final class MosquitoModel extends EnemyModel {
  final MosquitoRank rank;

  MosquitoModel(
      {required super.id,
      required super.x,
      required super.y,
      this.rank = MosquitoRank.regular,
      super.facing = -1,
      super.maxHealth = 6})
      : super(
            attack: rank == MosquitoRank.veteran
                ? AttackSpec.veteranSting
                : AttackSpec.sting);

  @override
  FighterKind get kind => FighterKind.mosquito;
  @override
  AttackSpec get nextAttack =>
      rank == MosquitoRank.veteran ? AttackSpec.veteranSting : AttackSpec.sting;
  @override
  double get moveSpeed => 25;
}
