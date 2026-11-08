import '../services/end_cache_service.dart';
import '../../../view/screen_view.dart';

class GameEndView extends ScreenView {
  final EndCacheService sprites;
  final bool completed;
  final int totalScore;
  final void Function() onMenu;
  GameEndView(
      {required this.sprites,
      required this.completed,
      required this.totalScore,
      required this.onMenu});
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    title('THE END');
    label(completed ? 'ALL SWARMS CLEARED' : 'THE MOSQUITOES WIN', 65,
        fontSize: 8);
    label('FINAL SCORE  $totalScore', 106, fontSize: 9);
    action('BACK TO MENU', onMenu, skin: sprites.menuButton);
    label('ENTER TO RETURN', 181, fontSize: 5);
  }
}
