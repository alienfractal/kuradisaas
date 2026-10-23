import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'dart:ui' as ui;
import '../view/cga_palette.dart';

class SettingsCacheService {
  late List<Sprite> effects, music, crt;
  final List<ui.Image> _paletteImages = [];
  Future<List<Sprite>> _load(
      FlameGame game, String path, int count, int cell) async {
    final original = await game.images.load(path);
    final image = await CgaPalette.uiImage(original);
    _paletteImages.add(image);
    if (image.width != count * cell || image.height != cell) {
      throw FormatException('Unexpected settings sheet size: $path');
    }
    return List.generate(
        count,
        (i) => Sprite(image,
            srcPosition: Vector2((i * cell).toDouble(), 0),
            srcSize: Vector2.all(cell.toDouble())));
  }

  Future<void> preload(FlameGame game) async {
    effects = await _load(game, 'soundfx-volume.png', 4, 34);
    music = await _load(game, 'musicfx-volume.png', 4, 34);
    crt = await _load(game, 'crton-32x32-8.png', 8, 32);
  }

  void dispose() {
    for (final image in _paletteImages) {
      image.dispose();
    }
    _paletteImages.clear();
  }
}
