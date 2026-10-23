import 'dart:math' as math;
import '../model/arena_config.dart';
import '../model/fighter_model.dart';
import '../model/combat_event.dart';
import 'input_service.dart';

/// Pure simulation. No Flame components, animations, or wall-clock callbacks.
class CombatLogicService {
  final ArenaConfig config;
  late final FighterModel player;
  late final List<FighterModel> enemies;
  int hits = 0;
  final List<CombatEvent> events = [];
  CombatLogicService(
      {this.config = const ArenaConfig(),
      int enemyCount = 5,
      int enemyHealth = 6}) {
    player = FighterModel(
        id: 0,
        isPlayer: true,
        x: 80.0.clamp(config.minX, config.maxX),
        y: (config.minY + config.maxY) / 2,
        attack: AttackSpec.punch,
        maxHealth: 8);
    enemies = List.generate(
        enemyCount,
        (i) => FighterModel(
            id: i + 1,
            isPlayer: false,
            x: 190 +
                (enemyCount == 1
                    ? 0
                    : i * (config.maxX - 100 - 190) / (enemyCount - 1)),
            y: config.minY + (config.maxY - config.minY) * (.2 + (i % 3) * .3),
            facing: -1,
            attack: AttackSpec.sting,
            maxHealth: enemyHealth));
  }
  List<FighterModel> get fighters => [player, ...enemies];
  int get defeated => enemies.where((e) => !e.alive).length;
  bool get won => defeated == enemies.length;
  bool get endingAnimationsFinished =>
      (!player.alive || won) &&
      fighters.every((f) =>
          !f.airborne &&
          (f.alive
              ? !f.attacking && f.state != FighterState.hurt
              : f.deathReactionFinished));
  void update(double dt, InputService input) {
    events.clear();
    final punch = input.consumePunch();
    final kick = input.consumeKick();
    final jump = input.consumeJump();
    final settling = !player.alive || (enemies.isNotEmpty && won);
    if (settling) {
      input.clear();
      for (final fighter in fighters) {
        fighter.clearAttackBuffer();
        fighter.clearCombo();
      }
    }
    if (player.alive && !settling) {
      if (kick) {
        player.queueAttack(AttackSpec.frontKick);
      } else if (punch) {
        player.queueAttack(AttackSpec.punch);
      }
      if (jump && player.canMove && !player.airborne) {
        player.beginJump();
        events.add(
            CombatEvent(CombatEventType.jumpStarted, fighterId: player.id));
      }
    }
    for (final fighter in fighters) {
      fighter.invulnerability = math.max(0, fighter.invulnerability - dt);
      fighter.attackBuffer = math.max(0, fighter.attackBuffer - dt);
      if (fighter.attackBuffer == 0) fighter.bufferedAttack = null;
      fighter.comboWindow = math.max(0, fighter.comboWindow - dt);
      if (fighter.comboWindow == 0) fighter.clearCombo();
      _advanceJump(fighter, dt);
      _advanceState(fighter, dt);
    }
    // Finish motion and current phases after an outcome, without new actions,
    // AI movement, or damage. The level-ending model owns the result delay.
    if (settling) return;
    // Only a confirmed follow-up may shorten recovery. Animation completion
    // has no authority over this transition.
    if (player.alive &&
        player.state == FighterState.recovery &&
        player.bufferedAttack == AttackSpec.frontKick &&
        _comboAvailable() &&
        player.stateTime >= player.attack.comboRecovery) {
      _beginPlayerAttack();
    }
    if (player.canMove && player.alive) {
      if (player.attackBuffer > 0) {
        _beginPlayerAttack();
      } else {
        _move(player, input.x, input.y, 72, dt);
      }
    }
    for (final enemy in enemies.where((e) => e.alive && e.canMove)) {
      if (!player.alive) {
        enemy.enter(FighterState.idle);
        continue;
      }
      final dx = player.x - enemy.x;
      final dy = player.y - enemy.y;
      enemy.facing = dx < 0 ? -1 : 1;
      if (dx.abs() <= 25 && dy.abs() <= 8) {
        enemy.beginAttack();
      } else {
        _move(enemy, dx.abs() > 23 ? dx.sign : 0, dy.abs() > 4 ? dy.sign : 0,
            25, dt);
      }
    }
    // Stable ordering gives the player's attack priority on simultaneous contact.
    for (final attacker in fighters) {
      if (attacker.state != FighterState.active) continue;
      final targets = attacker.isPlayer ? enemies : [player];
      for (final target in targets) {
        if (_canHit(attacker, target)) _hit(attacker, target);
      }
    }
  }

  bool _comboAvailable() =>
      player.comboReady &&
      enemies.any((e) => e.id == player.comboTargetId && e.alive);

  void _beginPlayerAttack() {
    var next = player.bufferedAttack!;
    if (next == AttackSpec.frontKick && _comboAvailable()) {
      next = player.nextComboAttack!;
      // Consume the confirmation. This attack must connect again to advance.
      player.nextComboAttack = null;
      if (next == AttackSpec.veryHighKick) player.clearCombo();
    } else {
      player.clearCombo();
    }
    player.beginAttack(next);
    events.add(CombatEvent(CombatEventType.attackStarted,
        fighterId: player.id, attack: next.kind));
  }

  void _advanceJump(FighterModel fighter, double dt) {
    if (!fighter.airborne) return;
    fighter.jumpTime += dt;
    fighter.elevation +=
        fighter.verticalVelocity * dt - .5 * FighterModel.gravity * dt * dt;
    fighter.verticalVelocity -= FighterModel.gravity * dt;
    if (fighter.elevation <= 0) {
      fighter.elevation = 0;
      fighter.verticalVelocity = 0;
      fighter.jumpTime = 0;
    }
  }

  void _advanceState(FighterModel f, double dt) {
    f.stateTime += dt;
    final duration = switch (f.state) {
      FighterState.startup => f.attack.startup,
      FighterState.active => f.attack.active,
      FighterState.recovery => f.attack.recovery,
      FighterState.hurt => f.hitStunDuration,
      _ => double.infinity,
    };
    if (f.stateTime < duration ||
        (f.state == FighterState.hurt && f.airborne)) {
      return;
    }
    if (f.state == FighterState.active &&
        f.attack.isKick &&
        (f.hitTargets.isEmpty ||
            (f.comboTargetId != null &&
                !f.hitTargets.contains(f.comboTargetId)))) {
      f.clearCombo();
    }
    final remainder = f.stateTime - duration;
    f.enter(switch (f.state) {
      FighterState.startup => FighterState.active,
      FighterState.active => FighterState.recovery,
      _ => FighterState.idle,
    });
    f.stateTime = remainder;
  }

  void _move(FighterModel f, double dx, double dy, double speed, double dt) {
    final length = math.sqrt(dx * dx + dy * dy);
    final next = length > 0 ? FighterState.walking : FighterState.idle;
    if (f.state != next) f.enter(next);
    if (length == 0) return;
    if (dx != 0) f.facing = dx < 0 ? -1 : 1;
    f.x = (f.x + dx / length * speed * dt).clamp(config.minX, config.maxX);
    f.y =
        (f.y + dy / length * speed * .65 * dt).clamp(config.minY, config.maxY);
  }

  bool _canHit(FighterModel a, FighterModel b) {
    final forward = (b.x - a.x) * a.facing;
    return b.alive &&
        b.invulnerability <= 0 &&
        !a.hitTargets.contains(b.id) &&
        forward >= 0 &&
        forward <= a.attack.reach &&
        (a.elevation - b.elevation).abs() <= a.attack.heightTolerance &&
        (a.y - b.y).abs() <= a.attack.laneTolerance;
  }

  void _hit(FighterModel a, FighterModel b) {
    a.hitTargets.add(b.id);
    events.add(CombatEvent(CombatEventType.hitLanded,
        fighterId: a.id, targetId: b.id, attack: a.attack.kind));
    b.health = math.max(0, b.health - a.attack.damage);
    b.clearAttackBuffer();
    b.clearCombo();
    b.hitStunDuration = a.attack.stunSeconds;
    b.lastHitCritical = a.attack.critical;
    if (a.attack.launchSpeed > 0) {
      b.verticalVelocity = a.attack.launchSpeed;
      b.jumpTime = 0;
    }
    b.invulnerability = b.isPlayer ? .7 : .28;
    b.x = (b.x + a.facing * a.attack.knockback).clamp(config.minX, config.maxX);
    b.enter(b.alive ? FighterState.hurt : FighterState.dead);
    if (a.isPlayer) {
      hits++;
      if (b.alive &&
          a.attack == AttackSpec.frontKick &&
          a.comboTargetId == null) {
        a.comboTargetId = b.id;
        a.nextComboAttack = AttackSpec.highKick;
        a.comboWindow = .42;
      } else if (b.alive &&
          a.attack == AttackSpec.highKick &&
          a.comboTargetId == b.id) {
        a.nextComboAttack = AttackSpec.veryHighKick;
        a.comboWindow = .42;
      }
    }
  }
}
