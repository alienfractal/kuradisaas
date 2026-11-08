import 'package:kuradi_saased/gen/shaders.gen.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Captures the game once, then applies the shared CRT shader to that image.
/// Off bypasses capture entirely. Coordinates and hit testing never change.
class CrtRenderer {
  static const shaderPath = ShaderAssets.crt;
  FragmentShader? _shader;
  Image? _texture;
  bool get available => _shader != null;

  Future<void> preload() async {
    try {
      _shader = (await FragmentProgram.fromAsset(shaderPath)).fragmentShader();
    } catch (error) {
      debugPrint('CRT shader unavailable: $error');
    }
  }

  void render(Canvas canvas, Size size, void Function(Canvas) drawGame) {
    final shader = _shader;
    if (shader == null || size.isEmpty) {
      drawGame(canvas);
      return;
    }
    final recorder = PictureRecorder();
    final captured = Canvas(recorder);
    captured.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF000000));
    drawGame(captured);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(size.width.ceil(), size.height.ceil());
    picture.dispose();
    _texture?.dispose();
    _texture = image;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  void releaseFrame() {
    _texture?.dispose();
    _texture = null;
  }

  void dispose() {
    releaseFrame();
    _shader?.dispose();
    _shader = null;
  }
}
