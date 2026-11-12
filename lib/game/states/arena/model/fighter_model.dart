import 'dart:math' as math;
import 'arena_config.dart';

part 'player_model.dart';
part 'enemy_model.dart';
part 'mosquito_model.dart';
part 'grunt_model.dart';

enum FighterKind { player, mosquito, grunt }

enum FighterState {
  idle,
  walking,
  startup,
  active,
  recovery,
  hurt,
  knockedDown,
  gettingUp,
  dead
}

enum PlayerDeathVariant { fall, wound }

enum AttackKind { punch, midKick, highKick, sting, gruntLight, gruntHeavy }

class AttackSpec {
  final AttackKind kind;
  final double launchSpeed, stunSeconds, comboRecovery;
  final bool critical, knockdown;
  bool get isKick => kind == AttackKind.midKick || kind == AttackKind.highKick;
  final double startup,
      active,
      recovery,
      reach,
      laneTolerance,
      knockback,
      knockbackDuration,
      heightTolerance;
  final int damage;
  const AttackSpec(
      {required this.kind,
      this.launchSpeed = 0,
      this.stunSeconds = .25,
      this.comboRecovery = double.infinity,
      this.critical = false,
      this.knockdown = false,
      required this.startup,
      required this.active,
      required this.recovery,
      required this.reach,
      required this.damage,
      this.laneTolerance = 10,
      this.knockback = 9,
      this.knockbackDuration = 0,
      this.heightTolerance = 32});
  static const punch = AttackSpec(
      kind: AttackKind.punch,
      startup: .07,
      active: .075,
      recovery: .19,
      comboRecovery: .07,
      reach: 32,
      damage: 1);
  static const groundedPunchKnockback = 1.0;
  static const midKick = AttackSpec(
      kind: AttackKind.midKick,
      startup: .12,
      active: .10,
      recovery: .50,
      reach: 38,
      damage: 2,
      knockback: 5,
      launchSpeed: 90,
      stunSeconds: .70,
      comboRecovery: .10,
      heightTolerance: 48);
  static const highKick = AttackSpec(
      kind: AttackKind.highKick,
      startup: .16,
      active: .10,
      recovery: .65,
      reach: 42,
      damage: 3,
      knockback: 32,
      knockbackDuration: .22,
      launchSpeed: 120,
      stunSeconds: 1.2,
      critical: true,
      heightTolerance: 64);
  static const gruntLight = AttackSpec(
      kind: AttackKind.gruntLight,
      startup: .32,
      active: .12,
      recovery: .50,
      reach: 34,
      damage: 1,
      knockback: 12,
      heightTolerance: 14);
  static const gruntHeavy = AttackSpec(
      kind: AttackKind.gruntHeavy,
      startup: .65,
      active: .14,
      recovery: .85,
      reach: 40,
      damage: 2,
      knockback: 24,
      heightTolerance: 14,
      knockdown: true);
  static const sting = AttackSpec(
      kind: AttackKind.sting,
      startup: .24,
      active: .10,
      recovery: .36,
      reach: 27,
      damage: 1,
      heightTolerance: 10);
  static const veteranSting = AttackSpec(
      kind: AttackKind.sting,
      startup: .18,
      active: .10,
      recovery: .28,
      reach: 27,
      damage: 1,
      heightTolerance: 10);
}

sealed class FighterModel {
  FighterKind get kind;
  // Half-width of the debug body outline.
  static const hurtHalfWidth = 6.0;
  final int id;
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
  bool get knockedDown =>
      state == FighterState.knockedDown || state == FighterState.gettingUp;
  double get deathAnimationDuration => deathReactionDuration;
  double get hitInvulnerability => .28;
  double get knockbackMultiplier => 1;
  bool get deathReactionFinished =>
      state == FighterState.dead && stateTime >= deathAnimationDuration;
  double hitStunDuration = hitReactionDuration;
  bool lastHitCritical = false;
  double attackBuffer = 0;
  AttackSpec? bufferedAttack;
  static const jumpSpeed = 135.0;
  static const gravity = 450.0;
  static const maxLaunchHeight = 24.0;
  static const jumpDuration = 2 * jumpSpeed / gravity;
  double elevation = 0;
  double verticalVelocity = 0;
  double jumpTime = 0;
  double _knockbackVelocity = 0;
  double _knockbackTime = 0;
  bool get airborne => elevation > 0 || verticalVelocity > 0;
  int attackSerial = 0;
  final Set<int> hitTargets = {};
  FighterModel(
      {required this.id,
      required this.x,
      required this.y,
      required this.attack,
      this.facing = 1,
      this.maxHealth = 3});
  bool get alive => health > 0;
  bool get canMove =>
      !airborne &&
      (state == FighterState.idle || state == FighterState.walking);
  bool get attacking =>
      state == FighterState.startup ||
      state == FighterState.active ||
      state == FighterState.recovery;
  void enter(FighterState next) {
    state = next;
    stateTime = 0;
  }

  void advanceTimers(double dt) {
    invulnerability = math.max(0, invulnerability - dt);
    attackBuffer = math.max(0, attackBuffer - dt);
    if (attackBuffer == 0) bufferedAttack = null;
  }

  void clearPendingActions() => clearAttackBuffer();

  void reactToHit(AttackSpec incoming) {
    enter(alive ? FighterState.hurt : FighterState.dead);
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

  void launch(double speed) {
    // Relaunches use the remaining height budget rather than stacking arcs.
    final headroom = math.max(0.0, maxLaunchHeight - elevation);
    verticalVelocity = math.min(speed, math.sqrt(2 * gravity * headroom));
    jumpTime = 0;
  }

  void applyKnockback(double distance, double duration, ArenaConfig arena) {
    _knockbackTime = duration;
    if (duration == 0) {
      x = (x + distance).clamp(arena.minX, arena.maxX);
      _knockbackVelocity = 0;
      return;
    }
    _knockbackVelocity = 2 * distance / duration;
  }

  void advanceKnockback(double dt, ArenaConfig arena) {
    if (_knockbackTime == 0) return;
    final elapsed = math.min(dt, _knockbackTime);
    final remaining = _knockbackTime - elapsed;
    // Average the start and end velocities for constant deceleration.
    final nextVelocity = _knockbackVelocity * (remaining / _knockbackTime);
    final nextX = x + (_knockbackVelocity + nextVelocity) * .5 * elapsed;
    x = nextX.clamp(arena.minX, arena.maxX);
    _knockbackVelocity = nextVelocity;
    _knockbackTime = x == nextX ? remaining : 0;
  }

  void beginAttack([AttackSpec? spec]) {
    if (spec != null) attack = spec;
    clearAttackBuffer();
    attackSerial++;
    hitTargets.clear();
    enter(FighterState.startup);
  }
}
