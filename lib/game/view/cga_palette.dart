import 'dart:ui';

/// Colors for drawn HUD/text/controls. Sprite artwork keeps its source palette.
abstract final class CgaPalette {
  static const black = Color(0xFF000000);
  static const cyan = Color(0xFF55FFFF);
  static const magenta = Color(0xFFFF55FF);
  static const white = Color(0xFFFFFFFF);
  static const rgb = [0x000000, 0x55FFFF, 0xFF55FF, 0xFFFFFF];
}
