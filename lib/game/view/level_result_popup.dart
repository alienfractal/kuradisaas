import 'cga_palette.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';
import '../../kuradi_saased.dart';
import '../../gamefsm/game_fsm.dart';

/// Fixed to the 256x128 gameplay viewport, above the world and HUD.
class LevelResultPopup extends Component {
  LevelResultPopup(this.game) : super(priority: 1000000);
  final KuradiSaased game;
  final title = TextPaint(
      style: const TextStyle(
          fontFamily: 'Arcade', fontSize: 11, color: CgaPalette.magenta));
  final text = TextPaint(
      style: const TextStyle(
          fontFamily: 'Arcade', fontSize: 5, color: CgaPalette.white));

  @override
  void render(Canvas canvas) {
    if (game.fsm.phase != GlobalGameState.level ||
        !game.levelEnding.showPopup) {
      return;
    }
    final won = game.levelEnding.result!.cleared;
    final paint = Paint()..isAntiAlias = false;
    canvas.drawRect(
        const Rect.fromLTWH(20, 32, 216, 62), paint..color = CgaPalette.white);
    canvas.drawRect(
        const Rect.fromLTWH(22, 34, 212, 58), paint..color = CgaPalette.black);
    title.render(canvas, won ? 'YOU WON!' : 'JAAN IS DOWN', Vector2(128, 44),
        anchor: Anchor.topCenter);
    text.render(
        canvas,
        won ? 'THE STREET IS CLEAR.' : 'THE SUMMER FIGHT IS NOT OVER.',
        Vector2(128, 65),
        anchor: Anchor.topCenter);
    text.render(canvas, 'SCORE UP NEXT', Vector2(128, 80),
        anchor: Anchor.topCenter);
  }
}
