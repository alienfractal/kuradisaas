import 'package:kuradi_saased/gen/fonts.gen.dart';
import 'cga_palette.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';
import '../../kuradi_saased.dart';
import '../../gamefsm/game_fsm.dart';

class ArenaHud extends Component {
  final KuradiSaased game;
  ArenaHud(this.game);
  final text = TextPaint(
      style: const TextStyle(
          fontFamily: FontFamily.arcade, fontSize: 6, color: CgaPalette.white));
  @override
  void render(Canvas canvas) {
    if (game.fsm.phase != GlobalGameState.level) {
      return;
    }
    final combat = game.combat;
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 256, 27), Paint()..color = CgaPalette.black);
    text.render(canvas, 'JAAN', Vector2(8, 6));
    for (var i = 0; i < combat.player.maxHealth; i++) {
      final x = 8 + i * 8.0;
      if (i < combat.player.health) {
        canvas.drawRect(
            Rect.fromLTWH(x, 17, 6, 4), Paint()..color = CgaPalette.magenta);
      } else {
        canvas.drawRect(
            Rect.fromLTWH(x, 17, 6, 4), Paint()..color = CgaPalette.cyan);
        canvas.drawRect(
            Rect.fromLTWH(x + 1, 18, 4, 2), Paint()..color = CgaPalette.black);
      }
    }
    text.render(canvas, 'SAASED ${combat.defeated}/${combat.enemies.length}',
        Vector2(188, 6));
    text.render(
        canvas, 'LEVEL ${game.campaign.levelIndex + 1}', Vector2(188, 17));
    text.render(canvas, 'SCORE ${game.campaign.totalScore}', Vector2(84, 6));
    if (game.showDebug) {
      text.render(
          canvas,
          '${combat.player.state.name.toUpperCase()}  HITS ${combat.hits}',
          Vector2(8, 33));
    }
  }
}
