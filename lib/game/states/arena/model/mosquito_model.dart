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
  double get moveSpeed => rank == MosquitoRank.veteran ? 34 : 25;

  @override
  double? sidestepDirection(PlayerModel player, ArenaConfig arena) {
    if (rank != MosquitoRank.veteran ||
        player.airborne ||
        (player.state != FighterState.startup &&
            player.state != FighterState.active)) {
      return null;
    }
    final forward = (x - player.x) * player.facing;
    if (forward < 0 || forward > player.attack.reach) return null;

    final clearance = player.attack.laneTolerance + 1;
    final canMoveUp = player.y - clearance >= arena.minY;
    final canMoveDown = player.y + clearance <= arena.maxY;
    if (!canMoveUp && !canMoveDown) return null;
    if ((y - player.y).abs() >= clearance) return 0;
    return canMoveDown && (!canMoveUp || y >= player.y) ? 1 : -1;
  }
}
