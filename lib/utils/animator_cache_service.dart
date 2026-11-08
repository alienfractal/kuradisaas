import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'sprite_spec.dart';

export 'sprite_spec.dart';

/// Per-game sheet cache shared by the domain cache services.
/// Flame owns source images; subclasses own any transformed images they create.
abstract class SpriteAnimatorCache {
  FlameGame? _owner;
  final _sheets = <(String, int, int, int, int), Future<List<Sprite>>>{};

  Future<void> preload(FlameGame game);

  Future<ui.Image> prepareImage(ui.Image image) async => image;

  Future<List<Sprite>> loadSheet(FlameGame game, String path,
      {SpriteSheetSpec? spec, int firstFrame = 0}) async {
    if (_owner != null && !identical(_owner, game)) {
      throw StateError('A sprite cache belongs to one game instance');
    }
    _owner = game;
    final sheet = spec ?? SpriteSheetSpec.fromPath(path);
    final key = (path, sheet.width, sheet.height, sheet.frames, firstFrame);
    final pending = _sheets.putIfAbsent(key, () async {
      // FlutterGen supplies full bundle paths, so Flame adds no prefix.
      game.images.prefix = '';
      final image = await game.images.load(path);
      // Validate the declared layout before preparing shared frames.
      sheet.validate(image, firstFrame: firstFrame);
      final prepared = await prepareImage(image);
      return sheet.slice(prepared, firstFrame: firstFrame);
    });
    try {
      return await pending;
    } catch (_) {
      if (identical(_sheets[key], pending)) _sheets.remove(key);
      rethrow;
    }
  }

  void dispose() {
    _sheets.clear();
    _owner = null;
  }
}
