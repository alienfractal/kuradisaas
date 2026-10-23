import 'package:flame/components.dart';
import 'package:flame/game.dart';

class MenuCacheService {
  static const introPath = 'CGA-game-intro-logos_256x256-2.png';
  static const lorePath = 'CGA-intro-256x256-6.png';
  static const frameSize = 256.0;
  late List<Sprite> introFrames, loreFrames;

  Future<void> preload(FlameGame game) async {
    final image = await game.images.load(introPath);
    if (image.width != 512 || image.height != 256) {
      throw const FormatException(
          'Expected two 256x256 intro frames: $introPath');
    }
    introFrames = List.generate(
        2,
        (i) => Sprite(image,
            srcPosition: Vector2(i * frameSize, 0),
            srcSize: Vector2.all(frameSize)));
    final loreImage = await game.images.load(lorePath);
    if (loreImage.width != 6 * frameSize || loreImage.height != frameSize) {
      throw const FormatException(
          'Expected six 256x256 lore frames: $lorePath');
    }
    loreFrames = List.generate(
        6,
        (i) => Sprite(loreImage,
            srcPosition: Vector2(i * frameSize, 0),
            srcSize: Vector2.all(frameSize)));
  }
}
