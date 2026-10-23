import 'dart:math' as math;

enum FighterState { idle, walking, startup, active, recovery, hurt, dead }

enum PlayerDeathVariant { fall, wound }

enum AttackKind { punch, frontKick, highKick, veryHighKick, sting }

class AttackSpec {
  final AttackKind kind;
  final double launchSpeed, stunSeconds, comboRecovery;
  final bool critical;
  bool get isKick =>
      kind == AttackKind.frontKick ||
      kind == AttackKind.highKick ||
      kind == AttackKind.veryHighKick;
  final double startup,
      active,
      recovery,
      reach,
      laneTolerance,
      knockback,
      heightTolerance;
  final int damage;
  const AttackSpec(
      {required this.kind,
      this.launchSpeed = 0,
      this.stunSeconds = .25,
      this.comboRecovery = double.infinity,
      this.critical = false,
      required this.startup,
      required this.active,
      required this.recovery,
      required this.reach,
      required this.damage,
      this.laneTolerance = 10,
      this.knockback = 9,
      this.heightTolerance = 32});
  static const punch = AttackSpec(
      kind: AttackKind.punch,
      startup: .09,
      active: .075,
      recovery: .19,
      reach: 32,
      damage: 1);
  static const frontKick = AttackSpec(
      kind: AttackKind.frontKick,
      startup: .14,
      active: .10,
      recovery: .48,
      // Modest 4px reduction from the original range, preserving combo spacing.
      reach: 34,
      damage: 1,
      knockback: 12,
      comboRecovery: .08);
  static const highKick = AttackSpec(
      kind: AttackKind.highKick,
      startup: .12,
      active: .10,
      recovery: .50,
      reach: 38,
      damage: 2,
      knockback: 5,
      launchSpeed: 130,
      stunSeconds: .70,
      comboRecovery: .10,
      heightTolerance: 48);
  static const veryHighKick = AttackSpec(
      kind: AttackKind.veryHighKick,
      startup: .16,
      active: .10,
      recovery: .65,
      reach: 42,
      damage: 3,
      knockback: 3,
      launchSpeed: 200,
      stunSeconds: 1.2,
      critical: true,
      heightTolerance: 64);
  static const sting = AttackSpec(
      kind: AttackKind.sting,
      startup: .30,
      active: .10,
      recovery: .45,
      reach: 27,
      damage: 1,
      heightTolerance: 10);
}

class FighterModel {
  final math.Random _random;
  PlayerDeathVariant deathVariant = PlayerDeathVariant.fall;
  // Half-width of the debug body outline.
  static const hurtHalfWidth = 6.0;
  final int id;
  final bool isPlayer;
  final int maxHealth;
  AttackSpec attack;
  double x, y;
  int facing;
  late int health = maxHealth;
  FighterState state = FighterState.idle;
  double stateTime = 0;
  double invulnerability = 0;
  // Simulation-time presentation windows, never animation completion callbacks.
  static const hitReactionDuration = .25;
  static const deathReactionDuration = .56;
  static const playerDeathDuration = .84;
  double get deathAnimationDuration =>
      isPlayer ? playerDeathDuration : deathReactionDuration;
  bool get deathReactionFinished =>
      state == FighterState.dead && stateTime >= deathAnimationDuration;
  double hitStunDuration = hitReactionDuration;
  bool lastHitCritical = false;
  AttackSpec? nextComboAttack;
  int? comboTargetId;
  double comboWindow = 0;
  bool get comboReady => nextComboAttack != null && comboWindow > 0;
  void clearCombo() {
    nextComboAttack = null;
    comboTargetId = null;
    comboWindow = 0;
  }

  double attackBuffer = 0;
  AttackSpec? bufferedAttack;
  static const jumpSpeed = 135.0;
  static const gravity = 450.0;
  static const jumpDuration = 2 * jumpSpeed / gravity;
  double elevation = 0;
  double verticalVelocity = 0;
  double jumpTime = 0;
  bool get airborne => elevation > 0 || verticalVelocity > 0;
  int attackSerial = 0;
  final Set<int> hitTargets = {};
  FighterModel(
      {required this.id,
      required this.isPlayer,
      required this.x,
      required this.y,
      required this.attack,
      this.facing = 1,
      this.maxHealth = 3,
      math.Random? random})
      : _random = random ?? math.Random();
  bool get alive => health > 0;
  bool get canMove =>
      (isPlayer || !airborne) &&
      (state == FighterState.idle || state == FighterState.walking);
  bool get attacking =>
      state == FighterState.startup ||
      state == FighterState.active ||
      state == FighterState.recovery;
  void enter(FighterState next) {
    if (isPlayer && next == FighterState.dead && state != FighterState.dead) {
      deathVariant = PlayerDeathVariant
          .values[_random.nextInt(PlayerDeathVariant.values.length)];
    }
    state = next;
    stateTime = 0;
  }

  void queueAttack(AttackSpec spec) {
    bufferedAttack = spec;
    attackBuffer = .16;
  }

  void clearAttackBuffer() {
    attackBuffer = 0;
    bufferedAttack = null;
  }

  void beginJump() {
    verticalVelocity = jumpSpeed;
    jumpTime = 0;
  }

  void beginAttack([AttackSpec? spec]) {
    if (spec != null) attack = spec;
    clearAttackBuffer();
    attackSerial++;
    hitTargets.clear();
    enter(FighterState.startup);
  }
}
