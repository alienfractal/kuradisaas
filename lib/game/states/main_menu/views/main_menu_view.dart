import '../services/menu_cache_service.dart';
import '../../../view/screen_view.dart';
import 'package:flame/components.dart';

class MainMenuView extends ScreenView {
  final MenuCacheService sprites;
  final void Function() onStart;
  final void Function() onLore;
  final String? loadingError;
  final Component settingsControls;
  MainMenuView(
      {required this.sprites,
      required this.onStart,
      required this.onLore,
      required this.settingsControls,
      this.loadingError});
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(settingsControls);
    title('KURADI SÄÄSED');
    label('NIGHT STREET CAMPAIGN', 55);
    label('A karate guy. Man-sized mosquitoes.', 78);
    label(
        'WASD / ARROWS : MOVE\nSPACE : JUMP    E : PUNCH    R : KICK\nP / ESC : PAUSE    F1 : HITBOXES',
        94,
        fontSize: 5.5);
    if (loadingError != null) {
      label('LOAD FAILED. PLEASE TRY AGAIN.', 124, fontSize: 5);
    }
    action('ENTER THE SWARM', onStart, skin: sprites.startButton, y: 144);
    await add(GameButton('LORE', onLore,
        skin: sprites.loreButton, position: Vector2(160, 166)));
    label('ENTER TO START / L FOR LORE', 185, fontSize: 5);
  }
}
