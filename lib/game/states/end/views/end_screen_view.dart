import '../../../view/screen_view.dart';

class GameEndView extends ScreenView {
  final bool completed;
  final int totalScore;
  final void Function() onMenu;
  GameEndView(
      {required this.completed,
      required this.totalScore,
      required this.onMenu});
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    title('THE END');
    label(completed ? 'ALL SWARMS CLEARED' : 'THE MOSQUITOES WIN', 65,
        fontSize: 8);
    label('FINAL SCORE  $totalScore', 106, fontSize: 9);
    action('BACK TO MENU', onMenu);
    label('ENTER TO RETURN', 181, fontSize: 5);
  }
}
