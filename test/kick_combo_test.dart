import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';
import 'package:kuradi_saased/game/states/arena/services/combat_logic_service.dart';
import 'package:kuradi_saased/game/states/arena/services/input_service.dart';

void main() {
  for (final grunts in [0, 1]) {
    test('kick combo keeps victim near the ground (grunts: $grunts)', () {
      final arena = CombatLogicService(enemyCount: 1, gruntCount: grunts);
      final controls = InputService();
      final target = arena.enemies.single
        ..x = arena.player.x + 23
        ..y = arena.player.y;
      var peak = 0.0;
      void tick(double seconds) {
        for (var i = 0; i < (seconds * 120).ceil(); i++) {
          arena.update(1 / 120, controls);
          if (target.elevation > peak) peak = target.elevation;
        }
      }

      controls.kick();
      tick(.20);
      controls.kick();
      tick(.35);
      expect(arena.hits, 2);
      tick(.8);
      expect(peak, greaterThan(0));
      expect(peak, lessThanOrEqualTo(24));
      expect(target.airborne, isFalse);
    });
  }

  test('repeated launches cannot stack height beyond the kick ceiling', () {
    final arena = CombatLogicService(enemyCount: 1, enemyHealth: 100);
    final controls = InputService();
    final target = arena.enemies.single..y = arena.player.y;
    var peak = 0.0;
    for (var hit = 0; hit < 8; hit++) {
      target.x = arena.player.x + 20;
      arena.player.beginAttack(AttackSpec.highKick);
      for (var frame = 0; frame < 40; frame++) {
        arena.update(1 / 120, controls);
        if (target.elevation > peak) peak = target.elevation;
      }
    }
    expect(arena.hits, 8);
    expect(peak, lessThanOrEqualTo(24));
    for (var frame = 0; frame < 120; frame++) {
      arena.update(1 / 120, controls);
    }
    expect(target.airborne, isFalse);
  });

  for (final spec in [AttackSpec.midKick, AttackSpec.highKick]) {
    for (final facing in [-1, 1]) {
      for (final gap in [0.0, .01, 20.0]) {
        test(
            '${spec.kind.name} facing $facing respects its contact range ($gap)',
            () {
          final arena = CombatLogicService(enemyCount: 1, enemyHealth: 10);
          final attacker = arena.player
            ..facing = facing
            ..beginAttack(spec)
            ..enter(FighterState.active);
          final target = arena.enemies.first
            ..x = attacker.x + facing * (spec.reach + gap)
            ..y = attacker.y
            ..hitStunDuration = 10
            ..enter(FighterState.hurt); // Freeze AI so range is tested exactly.
          arena.update(1 / 120, InputService());
          expect(target.health, gap == 0 ? 10 - spec.damage : 10);
        });
      }
    }
  }

  late CombatLogicService combat;
  for (final facing in [-1, 1]) {
    for (final spacing in [23.0, 25.0]) {
      test(
          'full combo connects at normal enemy spacing $spacing facing $facing',
          () {
        final arena = CombatLogicService(enemyCount: 1);
        final controls = InputService();
        arena.player
          ..x = 100
          ..facing = facing;
        final target = arena.enemies.first
          ..x = arena.player.x + facing * spacing
          ..y = arena.player.y;
        void tick(double seconds) {
          for (var i = 0; i < (seconds * 120).ceil(); i++) {
            arena.update(1 / 120, controls);
          }
        }

        controls.kick();
        tick(.20);
        expect(arena.player.attack, AttackSpec.midKick);
        expect(target.health, 4);
        final beforeHeavyKick = target.x;
        controls.kick();
        for (var frame = 0; frame < 36 && arena.hits < 2; frame++) {
          tick(1 / 120);
        }
        expect(arena.player.attack, AttackSpec.highKick);
        expect(target.health, 1);
        expect(arena.hits, 2);
        expect(target.x, beforeHeavyKick, reason: 'No snap on contact');
        tick(.05);
        final firstPush = (target.x - beforeHeavyKick) * facing;
        expect(firstPush, inExclusiveRange(0, 32));
        tick(.05);
        final secondPush = (target.x - beforeHeavyKick) * facing - firstPush;
        expect(secondPush, inExclusiveRange(0, firstPush));
        tick(.2);
        expect(target.x - beforeHeavyKick, closeTo(facing * 32, .001));
        expect(arena.player.x, 100);
      });
    }
  }

  late InputService input;
  void advance(double seconds) {
    for (var i = 0; i < (seconds * 120).ceil(); i++) {
      combat.update(1 / 120, input);
    }
  }

  void mid() {
    input.kick();
    advance(.20);
  }

  void high() {
    input.kick();
    advance(.30);
  }

  test('lethal high kick still moves the victim up to the arena edge', () {
    final arena = CombatLogicService(enemyCount: 1, enemyHealth: 3);
    final controls = InputService();
    final edge = arena.config.maxX;
    final target = arena.enemies.single
      ..x = edge - 16
      ..y = arena.player.y;
    arena.player
      ..x = target.x - 20
      ..beginAttack(AttackSpec.highKick)
      ..enter(FighterState.active);

    arena.update(1 / 120, controls);
    expect(arena.won, isTrue);
    expect(target.x, edge - 16);
    arena.update(1 / 120, controls);
    expect(target.x, inExclusiveRange(edge - 16, edge));
    arena.update(.25, controls);
    expect(target.x, edge);
    arena.update(.25, controls);
    expect(target.x, edge);
  });

  setUp(() {
    combat = CombatLogicService(enemyCount: 1);
    input = InputService();
    combat.enemies.first
      ..x = 103
      ..y = combat.player.y;
  });

  for (final facing in [-1, 1]) {
    test('a grounded punch and both kicks defeat a mosquito facing $facing',
        () {
      final player = combat.player..facing = facing;
      final target = combat.enemies.single
        ..x = player.x + facing * 25
        ..y = player.y;

      input.punch();
      advance(.08);
      expect(target.health, 5);
      input.kick();
      advance(.15);
      expect(player.attack, AttackSpec.midKick);
      expect(player.state, FighterState.startup);
      advance(.20);
      expect(target.health, 3);
      high();
      expect(player.attack, AttackSpec.highKick);
      expect(target.state, FighterState.dead);
      expect(combat.hits, 3);
      expect(player.x, 80);
    });
  }

  test('a missed punch cannot cancel recovery into a kick', () {
    combat.enemies.single.x = 500;
    input.punch();
    advance(.10);
    input.kick();
    advance(.15);
    expect(combat.player.attack, AttackSpec.punch);
    expect(combat.player.state, FighterState.recovery);
    advance(.15);
    expect(combat.player.attackSerial, 1);
  });

  test('an airborne punch keeps its original push and recovery', () {
    final target = combat.enemies.single;
    input
      ..jump()
      ..punch();
    advance(.10);
    expect(combat.player.airborne, isTrue);
    expect(target.health, 5);
    expect(target.x, 103 + AttackSpec.punch.knockback);
    input.kick();
    advance(.15);
    expect(combat.player.attack, AttackSpec.punch);
    expect(combat.player.state, FighterState.recovery);
  });

  test('two connected R presses launch and critically stun a mosquito', () {
    final target = combat.enemies.first;
    mid();
    expect(combat.player.attack, AttackSpec.midKick);
    expect(target.health, 4);
    expect(target.x - combat.player.x, lessThan(AttackSpec.highKick.reach));
    expect(target.airborne, isTrue);
    expect(target.state, FighterState.hurt);
    high();
    expect(combat.player.attack, AttackSpec.highKick);
    expect(combat.player.attackSerial, 2);
    expect(combat.hits, 2);
    expect(target.health, 1);
    expect(target.state, FighterState.hurt);
    expect(target.lastHitCritical, isTrue);
    expect(target.verticalVelocity, greaterThan(0));
    advance(2);
    expect(combat.hits, 2);
    expect(target.airborne, isFalse);
    expect(target.alive, isTrue);
  });

  test('surviving critical victim stays stunned after landing then recovers',
      () {
    combat = CombatLogicService(enemyCount: 1, enemyHealth: 10);
    final target = combat.enemies.first
      ..x = 103
      ..y = combat.player.y;
    mid();
    high();
    expect(target.health, 5);
    expect(target.lastHitCritical, isTrue);
    final serial = target.attackSerial;
    advance(1.0);
    expect(target.airborne, isFalse);
    expect(target.state, FighterState.hurt);
    expect(target.attackSerial, serial);
    advance(.4);
    expect(target.state, isNot(FighterState.hurt));
  });

  test('missed mid kick cannot advance or cancel its recovery', () {
    combat.enemies.first.x = 500;
    mid();
    input.kick();
    advance(.3);
    expect(combat.player.attackSerial, 1);
    expect(combat.player.comboReady, isFalse);
    advance(.3);
    input.kick();
    advance(.01);
    expect(combat.player.attack, AttackSpec.midKick);
  });

  test('expired confirmation resets the chain', () {
    mid();
    // Isolate combo expiry from the close target's next sting.
    combat.enemies.first.hitStunDuration = 2;
    advance(.6);
    expect(combat.player.comboReady, isFalse);
    input.kick();
    advance(.01);
    expect(combat.player.attack, AttackSpec.midKick);
    expect(combat.player.attackSerial, 2);
  });

  test('mid kick after a punch must hit the same victim to unlock high kick',
      () {
    combat = CombatLogicService(enemyCount: 2);
    final original = combat.enemies[0]
      ..x = 103
      ..y = combat.player.y;
    final other = combat.enemies[1]
      ..x = 500
      ..y = combat.player.y;
    input.punch();
    advance(.18);
    original.x = 500;
    other.x = 110;
    input.kick();
    advance(.35);
    expect(combat.player.attack, AttackSpec.midKick);
    expect(other.health, 4);
    expect(combat.player.comboReady, isFalse);
    input.kick();
    advance(.3);
    expect(combat.player.attackSerial, 2);
    advance(.2);
    input.kick();
    advance(.01);
    expect(combat.player.attack, AttackSpec.midKick);
  });

  test('taking damage clears confirmation and buffered follow-up', () {
    mid();
    final attacker = combat.enemies.first
      ..x = combat.player.x + 10
      ..invulnerability = 0
      ..facing = -1
      ..beginAttack()
      ..enter(FighterState.active);
    advance(.01);
    expect(combat.player.state, FighterState.hurt);
    expect(combat.player.comboReady, isFalse);
    expect(combat.player.bufferedAttack, isNull);
    expect(attacker.health, 4);
  });

  test('an early repeated R expires instead of queuing an entire combo', () {
    input.kick();
    advance(.02);
    input.kick();
    advance(.7);
    expect(combat.player.attackSerial, 1);
  });
}
