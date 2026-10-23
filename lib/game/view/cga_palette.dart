import 'dart:ui';

/// Shared high-intensity CGA colors for HUD, buttons and settings art.
abstract final class CgaPalette {
  static const black = Color(0xFF000000);
  static const cyan = Color(0xFF55FFFF);
  static const magenta = Color(0xFFFF55FF);
  static const white = Color(0xFFFFFFFF);
  static const rgb = [0x000000, 0x55FFFF, 0xFF55FF, 0xFFFFFF];

  static int nearestRgb(int red, int green, int blue) {
    var best = rgb.first;
    var distance = 1 << 30;
    for (final value in rgb) {
      final dr = red - ((value >> 16) & 255);
      final dg = green - ((value >> 8) & 255);
      final db = blue - (value & 255);
      final candidate = dr * dr + dg * dg + db * db;
      if (candidate < distance) {
        distance = candidate;
        best = value;
      }
    }
    return best;
  }

  /// Palette-convert shared UI sprites in memory; source artwork stays intact.
  static Future<Image> uiImage(Image source) async {
    final data =
        await source.toByteData(format: ImageByteFormat.rawStraightRgba);
    final pixels = data!.buffer.asUint8List();
    for (var i = 0; i < pixels.length; i += 4) {
      if (pixels[i + 3] == 0) {
        pixels[i] = pixels[i + 1] = pixels[i + 2] = 0;
        continue;
      }
      final color = nearestRgb(pixels[i], pixels[i + 1], pixels[i + 2]);
      pixels[i] = (color >> 16) & 255;
      pixels[i + 1] = (color >> 8) & 255;
      pixels[i + 2] = color & 255;
      pixels[i + 3] = 255;
    }
    final buffer = await ImmutableBuffer.fromUint8List(pixels);
    final descriptor = ImageDescriptor.raw(buffer,
        width: source.width,
        height: source.height,
        pixelFormat: PixelFormat.rgba8888);
    final codec = await descriptor.instantiateCodec();
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return image;
  }
}
