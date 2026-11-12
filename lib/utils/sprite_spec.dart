import 'dart:ui' as ui;
import 'package:flame/components.dart';

/// Horizontal sheet metadata, independent of the view that consumes it.
class SpriteSheetSpec {
  final int width, height, frames;
  const SpriteSheetSpec(this.width, this.height, this.frames);

  factory SpriteSheetSpec.fromPath(String path) {
    final match = RegExp(r'[_-](\d+)x(\d+)t?-(\d+)(?:-sheet)?\.png$',
            caseSensitive: false)
        .firstMatch(path);
    if (match == null) throw FormatException('Missing sheet dimensions: $path');
    final values = [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
    if (values.any((value) => value <= 0)) {
      throw FormatException('Invalid sheet: $path');
    }
    return SpriteSheetSpec(values[0], values[1], values[2]);
  }

  void validate(ui.Image image, {int firstFrame = 0}) {
    if (width <= 0 || height <= 0 || frames <= 0 || firstFrame < 0) {
      throw const FormatException('Invalid sheet dimensions or frame offset');
    }
    if (image.width != (firstFrame + frames) * width ||
        image.height != height) {
      throw FormatException('Image does not fit declared frames: '
          'expected ${(firstFrame + frames) * width}x$height, '
          'got ${image.width}x${image.height}');
    }
  }

  List<Sprite> slice(ui.Image image, {int firstFrame = 0}) {
    validate(image, firstFrame: firstFrame);
    return List.unmodifiable(List.generate(
        frames,
        (i) => Sprite(image,
            srcPosition: Vector2((firstFrame + i) * width.toDouble(), 0),
            srcSize: Vector2(width.toDouble(), height.toDouble()))));
  }
}

/// A cached sprite and its intended component size. Components stay view-owned.
class SpriteSpec {
  final Sprite sprite;
  final double _width, _height;
  SpriteSpec(this.sprite, Vector2 imgSize)
      : _width = imgSize.x,
        _height = imgSize.y;

  Vector2 get imgSize => Vector2(_width, _height);

  SpriteComponent getSpriteComponent() =>
      SpriteComponent(sprite: sprite, size: imgSize);
}

/// Shared frames/timing; each consumer creates its own animation and ticker.
class SpriteAnimationSpec {
  final List<Sprite> frames;
  final double stepTime;
  final bool loop;

  SpriteAnimationSpec(List<Sprite> frames,
      {required this.stepTime, this.loop = true})
      : frames = List.unmodifiable(frames) {
    if (frames.isEmpty || !stepTime.isFinite || stepTime <= 0) {
      throw ArgumentError(
          'Animation needs frames and a positive finite step time');
    }
  }

  SpriteAnimation createAnimation() =>
      SpriteAnimation.spriteList(frames, stepTime: stepTime, loop: loop);

  /// Samples simulation/presentation time without an independent ticking clock.
  Sprite frameAt(double elapsed) {
    final index = elapsed <= 0 ? 0 : (elapsed / stepTime).floor();
    return frames[
        loop ? index % frames.length : index.clamp(0, frames.length - 1)];
  }
}
