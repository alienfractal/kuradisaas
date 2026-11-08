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
      tick(.30);
      controls.kick();
      tick(.35);
      expect(arena.hits, 3);
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
      arena.player.beginAttack(AttackSpec.veryHighKick);
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

  for (final spec in [
    AttackSpec.frontKick,
    AttackSpec.highKick,
    AttackSpec.veryHighKick
  ]) {
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
        arena.player.facing = facing;
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
        expect(target.health, 5);
        controls.kick();
        tick(.30);
        expect(arena.player.attack, AttackSpec.highKick);
        expect(target.health, 3);
        controls.kick();
        tick(.35);
        expect(arena.player.attack, AttackSpec.veryHighKick);
        expect(target.health, 0);
        expect(arena.hits, 3);
        expect(
            arena.player.x, 80); // No movement needed to follow the pushback.
      });
    }
  }

  late InputService input;
  void advance(double seconds) {
    for (var i = 0; i < (seconds * 120).ceil(); i++) {
      combat.update(1 / 120, input);
    }
  }

  void front() {
    input.kick();
    advance(.20);
  }

  void high() {
    input.kick();
    advance(.30);
  }

  void finisher() {
    input.kick();
    advance(.35);
  }

  setUp(() {
    combat = CombatLogicService(enemyCount: 1);
    input = InputService();
    combat.enemies.first
      ..x = 103
      ..y = combat.player.y;
  });

  test('three connected R presses use distinct attacks, damage and launches',
      () {
    final target = combat.enemies.first;
    front();
    expect(combat.player.attack, AttackSpec.frontKick);
    expect(target.health, 5);
    expect(target.x - combat.player.x, lessThan(AttackSpec.highKick.reach));
    high();
    expect(combat.player.attack, AttackSpec.highKick);
    expect(target.health, 3);
    expect(target.airborne, isTrue);
    expect(target.state, FighterState.hurt);
    finisher();
    expect(combat.player.attack, AttackSpec.veryHighKick);
    expect(combat.player.attackSerial, 3);
    expect(combat.hits, 3);
    expect(target.health, 0);
    expect(target.state, FighterState.dead);
    expect(target.lastHitCritical, isTrue);
    expect(target.verticalVelocity, greaterThan(0));
    advance(2);
    expect(combat.hits, 3);
    expect(target.airborne, isFalse);
    expect(target.state, FighterState.dead);
  });

  test('surviving critical victim stays stunned after landing then recovers',
      () {
    combat = CombatLogicService(enemyCount: 1, enemyHealth: 10);
    final target = combat.enemies.first
      ..x = 103
      ..y = combat.player.y;
    front();
    high();
    finisher();
    expect(target.health, 4);
    expect(target.lastHitCritical, isTrue);
    final serial = target.attackSerial;
    advance(1.0);
    expect(target.airborne, isFalse);
    expect(target.state, FighterState.hurt);
    expect(target.attackSerial, serial);
    advance(.4);
    expect(target.state, isNot(FighterState.hurt));
  });

  test('missed front kick cannot advance or cancel its recovery', () {
    combat.enemies.first.x = 500;
    front();
    input.kick();
    advance(.3);
    expect(combat.player.attackSerial, 1);
    expect(combat.player.comboReady, isFalse);
    advance(.3);
    input.kick();
    advance(.01);
    expect(combat.player.attack, AttackSpec.frontKick);
  });

  test('expired confirmation resets the chain', () {
    front();
    // Isolate combo expiry from the close target's next sting.
    combat.enemies.first.hitStunDuration = 2;
    advance(.6);
    expect(combat.player.comboReady, isFalse);
    input.kick();
    advance(.01);
    expect(combat.player.attack, AttackSpec.frontKick);
    expect(combat.player.attackSerial, 2);
  });

  test('high kick must hit the same victim to unlock the finisher', () {
    combat = CombatLogicService(enemyCount: 2);
    final original = combat.enemies[0]
      ..x = 103
      ..y = combat.player.y;
    final other = combat.enemies[1]
      ..x = 500
      ..y = combat.player.y;
    front();
    advance(.06); // Let the front kick leave its active phase first.
    original.x = 500;
    other.x = 110;
    high();
    expect(combat.player.attack, AttackSpec.highKick);
    expect(other.health, 4);
    expect(combat.player.comboReady, isFalse);
    input.kick();
    advance(.3);
    expect(combat.player.attackSerial, 2);
    advance(.2);
    input.kick();
    advance(.01);
    expect(combat.player.attack, AttackSpec.frontKick);
  });

  test('taking damage clears confirmation and buffered follow-up', () {
    front();
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
    expect(attacker.health, 5);
  });

  test('an early repeated R expires instead of queuing an entire combo', () {
    input.kick();
    advance(.02);
    input.kick();
    advance(.7);
    expect(combat.player.attackSerial, 1);
  });
}
