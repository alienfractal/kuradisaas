import '../services/pause_cache_service.dart';
import 'package:flame/components.dart';
import '../../../view/screen_view.dart';

class PauseView extends ScreenView {
  final PauseCacheService sprites;
  final void Function() onResume, onMenu;
  final Component settingsControls;
  PauseView(
      {required this.sprites,
      required this.onResume,
      required this.onMenu,
      required this.settingsControls});
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(settingsControls);
    title('PAUSED');
    label('THE CURRENT LEVEL IS HELD.', 75);
    action('RESUME', onResume, skin: sprites.resumeButton, y: 120);
    add(GameButton('BACK TO MENU', onMenu,
        skin: sprites.menuButton, position: Vector2(160, 150)));
    label('ENTER / P / ESC TO RESUME', 181, fontSize: 5);
  }
}
