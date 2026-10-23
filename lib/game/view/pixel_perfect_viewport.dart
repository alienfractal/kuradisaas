import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';

/// One game pixel becomes a whole number of physical display pixels.
/// Spare space is letterboxed, rather than stretching the last few pixels.
class PixelPerfectViewport extends FixedResolutionViewport {
  PixelPerfectViewport(
      {required super.resolution, super.children, double devicePixelRatio = 1})
      : _devicePixelRatio = devicePixelRatio;

  double _devicePixelRatio;
  Vector2? _availableSize;

  set devicePixelRatio(double value) {
    if (value <= 0 || value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    if (_availableSize != null) _snap(_availableSize!);
  }

  @override
  void onLoad() {
    super.onLoad();
    _snap(findGame()!.canvasSize);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _snap(size);
  }

  void _snap(Vector2 canvasSize) {
    _availableSize = canvasSize.clone();
    final ratio = _devicePixelRatio;
    final physicalScale = math.max(
        1,
        math
            .min(canvasSize.x * ratio / resolution.x,
                canvasSize.y * ratio / resolution.y)
            .floor());
    size = resolution * (physicalScale / ratio);
    position.setValues(
        ((canvasSize.x - size.x) * ratio / 2).floorToDouble() / ratio,
        ((canvasSize.y - size.y) * ratio / 2).floorToDouble() / ratio);
  }

  @override
  void clip(Canvas canvas) =>
      canvas.clipRect(Rect.fromLTWH(0, 0, size.x, size.y), doAntiAlias: false);
}
