import 'fighter_model.dart';

enum CombatEventType { jumpStarted, attackStarted, hitLanded }

/// Facts emitted after accepted simulation actions; never animation callbacks.
class CombatEvent {
  const CombatEvent(this.type,
      {required this.fighterId, this.targetId, this.attack});
  final CombatEventType type;
  final int fighterId;
  final int? targetId;
  final AttackKind? attack;
}
