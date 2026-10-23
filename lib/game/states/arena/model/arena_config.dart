class ArenaConfig {
  static const viewWidth = 256.0;
  static const viewHeight = 128.0;
  final double width, height, minX, maxX, minY, maxY;
  const ArenaConfig(
      {this.width = 640,
      this.height = 320,
      this.minX = 22,
      this.maxX = 618,
      this.minY = 236,
      this.maxY = 310});

  /// Camera top-left: fighters' feet sit below centre, leaving room for heads.
  double cameraX(double playerX) => (playerX - viewWidth / 2)
      .clamp(0, (width - viewWidth).clamp(0, width))
      .roundToDouble();
  double cameraY(double playerY) => (playerY - viewHeight * .75)
      .clamp(0, (height - viewHeight).clamp(0, height))
      .roundToDouble();
}
