import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// Existing asset convention: name_WIDTHxHEIGHT-FRAMES.png (also hyphen separator / optional t export suffix).
class ScenarioSheet {
  final int width, height, frames;
  const ScenarioSheet(this.width, this.height, this.frames);
  factory ScenarioSheet.fromPath(String path) {
    final match = RegExp(r'[_-](\d+)x(\d+)t?-(\d+)\.png$', caseSensitive: false)
        .firstMatch(path);
    if (match == null) throw FormatException('Missing sheet dimensions: $path');
    final values = [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
    if (values.any((value) => value <= 0)) {
      throw FormatException('Invalid sheet: $path');
    }
    return ScenarioSheet(values[0], values[1], values[2]);
  }
}

class ScenarioCacheService {
  static const streetPath = 'scenariot-wide-front-street-house_640x320-1.png';
  static const starsPath = 'scenariot-wide-stars_640x320-3.png';
  late Sprite street;
  late List<Sprite> stars;

  Future<List<Sprite>> _load(FlameGame game, String path,
      {int firstFrame = 0}) async {
    final sheet = ScenarioSheet.fromPath(path);
    final image = await game.images.load(path);
    if (image.width < (firstFrame + sheet.frames) * sheet.width ||
        image.height != sheet.height) {
      throw FormatException('Image does not fit declared frames: $path');
    }
    return List.generate(
        sheet.frames,
        (i) => Sprite(image,
            srcPosition: Vector2((firstFrame + i) * sheet.width.toDouble(), 0),
            srcSize: Vector2(sheet.width.toDouble(), sheet.height.toDouble())));
  }

  Future<void> preload(FlameGame game) async {
    street = (await _load(game, streetPath)).single;
    // This export has an empty leading 640x320 cell before its three star frames.
    stars = await _load(game, starsPath, firstFrame: 1);
  }
}
