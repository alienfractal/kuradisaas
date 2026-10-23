import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/game/states/arena/model/fighter_model.dart';
import 'package:kuradi_saased/game/states/arena/services/combat_logic_service.dart';
import 'package:kuradi_saased/game/states/arena/services/input_service.dart';
import 'package:kuradi_saased/gamefsm/game_fsm.dart';
import 'package:kuradi_saased/game/states/arena/model/arena_config.dart';

void advance(CombatLogicService combat, InputService input, double seconds) {
  for (var i = 0; i < (seconds * 120).ceil(); i++) {
    combat.update(1 / 120, input);
  }
}

void main() {
  late CombatLogicService combat;
  late InputService input;
  setUp(() {
    // Keep combat timing fixtures on their original depth lanes.
    combat = CombatLogicService(
        enemyHealth: 3, config: const ArenaConfig(minY: 119, maxY: 180));
    combat.player.y = 153;
    input = InputService();
    for (final e in combat.enemies) {
      e.x = 600;
      e.y = 120;
    }
  });
  test('punch has startup and deals only one hit during active frames', () {
    final target = combat.enemies.first
      ..x = 103
      ..y = 153;
    input.punch();
    advance(combat, input, .05);
    expect(target.health, 3);
    expect(combat.player.state, FighterState.startup);
    advance(combat, input, .12);
    expect(target.health, 2);
    expect(combat.hits, 1);
    advance(combat, input, .3);
    expect(target.health, 2);
    expect(combat.player.state, FighterState.idle);
  });
  test('punch cannot hit behind Jaan or across a different depth lane', () {
    combat.enemies[0]
      ..x = 60
      ..y = 153;
    combat.enemies[1]
      ..x = 103
      ..y = 179;
    input.punch();
    advance(combat, input, .19);
    expect(combat.enemies[0].health, 3);
    expect(combat.enemies[1].health, 3);
  });
  test('movement and facing are locked during a punch', () {
    input.punch();
    advance(combat, input, .01);
    input.keyboard.add('left');
    advance(combat, input, .2);
    expect(combat.player.x, 80);
    expect(combat.player.facing, 1);
  });
  test('a buffered punch starts after recovery, without cancelling it', () {
    input.punch();
    advance(combat, input, .27);
    input.punch();
    advance(combat, input, .02);
    expect(combat.player.attackSerial, 1);
    advance(combat, input, .1);
    expect(combat.player.attackSerial, 2);
  });
  test('hurt interrupts a mosquito windup and prevents its sting', () {
    final target = combat.enemies.first
      ..x = 103
      ..y = 153;
    advance(combat, input, .02);
    expect(target.state, FighterState.startup);
    input.punch();
    advance(combat, input, .15);
    expect(target.state, FighterState.hurt);
    expect(combat.player.health, 8);
  });
  test('lethal damage is terminal and defeated mosquitoes stop attacking', () {
    final target = combat.enemies.first
      ..x = 103
      ..y = 153
      ..health = 1;
    input.punch();
    advance(combat, input, 1);
    expect(target.state, FighterState.dead);
    expect(combat.defeated, 1);
    expect(combat.player.health, 8);
  });
  test('movement stays inside stage and diagonal movement is normalized', () {
    input.keyboard.addAll(['right', 'down']);
    advance(combat, input, .1);
    final diagonalX = combat.player.x - 80;
    expect(diagonalX, lessThan(7.2));
    advance(combat, input, 30);
    expect(combat.player.x, lessThanOrEqualTo(combat.config.maxX));
    expect(combat.player.y, lessThanOrEqualTo(combat.config.maxY));
  });
  test('session FSM allows pause/resume and refuses invalid transitions', () {
    final fsm = GlobalGameFsm();
    expect(fsm.transition(GlobalGameState.score), isFalse);
    expect(fsm.transition(GlobalGameState.menu), isTrue);
    expect(fsm.transition(GlobalGameState.level), isFalse);
    expect(fsm.transition(GlobalGameState.loading), isTrue);
    expect(fsm.transition(GlobalGameState.level), isTrue);
    expect(fsm.transition(GlobalGameState.paused), isTrue);
    expect(fsm.transition(GlobalGameState.score), isFalse);
    expect(fsm.transition(GlobalGameState.level), isTrue);
    expect(fsm.transition(GlobalGameState.score), isTrue);
    expect(fsm.transition(GlobalGameState.level), isFalse);
    expect(fsm.transition(GlobalGameState.loading), isTrue);
    expect(fsm.transition(GlobalGameState.level), isTrue);
    expect(fsm.transition(GlobalGameState.score), isTrue);
    expect(fsm.transition(GlobalGameState.end), isTrue);
    expect(fsm.transition(GlobalGameState.level), isFalse);
    expect(fsm.transition(GlobalGameState.menu), isTrue);
  });

  test('low kick deals one damage with its original pushback, once per attack',
      () {
    final target = combat.enemies.first
      ..x = 103
      ..y = 153;
    input.kick();
    advance(combat, input, .12);
    expect(target.health, 3);
    expect(combat.player.attack, AttackSpec.frontKick);
    advance(combat, input, .08);
    expect(target.health, 2);
    expect(target.x, 115);
    expect(combat.hits, 1);
    advance(combat, input, .06);
    expect(target.health, 2);
    expect(combat.hits, 1);
    expect(AttackSpec.frontKick.knockback,
        greaterThan(AttackSpec.punch.knockback));
  });

  test('kick recovery cannot be cancelled by punch, kick or jump', () {
    input.kick();
    advance(combat, input, .28);
    expect(combat.player.state, FighterState.recovery);
    input
      ..punch()
      ..kick()
      ..jump();
    advance(combat, input, .31);
    expect(combat.player.state, FighterState.recovery);
    expect(combat.player.attackSerial, 1);
    expect(combat.player.airborne, isFalse);
    advance(combat, input, .06);
    input.punch(); // A late input buffers until the kick finishes.
    advance(combat, input, .1);
    expect(combat.player.attackSerial, 2);
    expect(combat.player.attack, AttackSpec.punch);
    expect(combat.player.state, FighterState.startup);
  });

  test('jump uses elevation, preserves its depth lane, and cannot double jump',
      () {
    final groundY = combat.player.y;
    input.jump();
    input.keyboard.add('right');
    advance(combat, input, .3);
    expect(combat.player.elevation, closeTo(20.25, .1));
    expect(combat.player.y, groundY);
    expect(combat.player.x, greaterThan(80));
    input.jump();
    advance(combat, input, .1);
    expect(combat.player.verticalVelocity, lessThan(0));
    advance(combat, input, .25);
    expect(combat.player.elevation, 0);
    expect(combat.player.airborne, isFalse);
    input.jump();
    advance(combat, input, .05);
    expect(combat.player.airborne, isTrue);
  });

  test('jump avoids a sting at height but landing remains vulnerable', () {
    final target = combat.enemies.first
      ..x = 103
      ..y = 153;
    target.beginAttack();
    input.jump();
    advance(combat, input, .34);
    expect(
        combat.player.elevation, greaterThan(AttackSpec.sting.heightTolerance));
    expect(combat.player.health, 8);
    advance(combat, input, .3);
    expect(combat.player.airborne, isFalse);
    target
      ..x = 103
      ..y = 153;
    target.beginAttack();
    advance(combat, input, .34);
    expect(combat.player.health, 7);
  });

  test('player can kick in the air and mosquitoes have the faster timing', () {
    final target = combat.enemies.first
      ..x = 103
      ..y = 153;
    input
      ..jump()
      ..kick();
    advance(combat, input, .2);
    expect(combat.player.airborne, isTrue);
    expect(target.health, 2);
    expect(AttackSpec.sting.startup, .30);
    expect(AttackSpec.sting.recovery, .45);
  });

  test('clearing input discards jump, punch and kick intents', () {
    input
      ..jump()
      ..punch()
      ..kick()
      ..clear();
    expect(input.consumeJump(), isFalse);
    expect(input.consumePunch(), isFalse);
    expect(input.consumeKick(), isFalse);
  });
}
