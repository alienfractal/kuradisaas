import '../../../model/campaign_model.dart';
import '../../../view/screen_view.dart';

class GameScoreView extends ScreenView {
  final LevelResult result;
  final int levelNumber, levelCount, totalScore;
  final bool hasNextLevel;
  final void Function() onContinue;
  GameScoreView(
      {required this.result,
      required this.levelNumber,
      required this.levelCount,
      required this.totalScore,
      required this.hasNextLevel,
      required this.onContinue});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    title('SCORE');
    label(result.cleared ? 'LEVEL CLEARED' : 'LEVEL FAILED', 50);
    label('LEVEL $levelNumber / $levelCount', 65);
    label(
        'ATTACK HITS ${result.hits} x 10\n'
        'SAASED DEFEATED  ${result.defeated} x 100\n'
        'HEALTH BONUS  ${result.healthBonus}',
        83);
    label('LEVEL SCORE  ${result.score}\nTOTAL SCORE  $totalScore', 123);
    action(
        result.cleared && hasNextLevel ? 'LOAD NEXT LEVEL' : 'CONTINUE TO END',
        onContinue);
    label('ENTER TO CONTINUE', 181, fontSize: 5);
  }
}
