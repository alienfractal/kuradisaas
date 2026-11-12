import 'dart:ui' as ui;
import 'package:kuradi_saased/gen/assets.gen.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../../../utils/animator_cache_service.dart';

/// Shared immutable frames; each fighter owns its own presentation clock.
class FighterCacheService extends SpriteAnimatorCache {
  late List<Sprite> idle,
      walk,
      punch,
      midKick,
      highKick,
      jump,
      playerKo,
      playerDead,
      playerDeadWound,
      mosquito,
      mosquitoHit,
      mosquitoDead,
      gruntIdle,
      gruntLight,
      gruntHeavy,
      gruntKo,
      gruntDead;
  late SpriteAnimationSpec idleAnimation,
      walkAnimation,
      mosquitoAnimation,
      gruntIdleAnimation;

  final List<ui.Image> _prepared = [];
  final Map<String, Future<List<Sprite>>> _exportedSheets = {};

  Future<List<Sprite>> _loadExportedSheet(FlameGame game, String path,
      {({int width, int height})? exportSize}) async {
    final pending = _exportedSheets.putIfAbsent(path, () async {
      final spec = SpriteSheetSpec.fromPath(path);
      game.images.prefix = '';
      final original = await game.images.load(path);
      if (exportSize == null ||
          (original.width == spec.width * spec.frames &&
              original.height == spec.height)) {
        spec.validate(original);
        return spec.slice(await _clearAlphaOneBackground(original));
      }
      if (original.width != exportSize.width ||
          original.height != exportSize.height) {
        throw FormatException('Unexpected sprite sheet export size: $path');
      }
      // These exports differ from the filename. Use the full height and
      // round each frame boundary so every source pixel belongs to one frame.
      final source = await _clearAlphaOneBackground(original);
      return List.unmodifiable(List.generate(spec.frames, (index) {
        final start = (index * original.width / spec.frames).roundToDouble();
        final end =
            ((index + 1) * original.width / spec.frames).roundToDouble();
        return Sprite(source,
            srcPosition: Vector2(start, 0),
            srcSize: Vector2(end - start, original.height.toDouble()));
      }));
    });
    try {
      return await pending;
    } catch (_) {
      if (identical(_exportedSheets[path], pending)) {
        _exportedSheets.remove(path);
      }
      rethrow;
    }
  }

  Future<ui.Image> _clearAlphaOneBackground(ui.Image image) async {
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final pixels =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    // Some exports encode their magenta background at alpha 1.
    // Opaque magenta belongs to the artwork and is retained.
    var changed = false;
    for (var i = 0; i < pixels.length; i += 4) {
      if (pixels[i + 3] == 1) {
        pixels.fillRange(i, i + 4, 0);
        changed = true;
      }
    }
    if (!changed) return image;
    final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
    final descriptor = ui.ImageDescriptor.raw(buffer,
        width: image.width,
        height: image.height,
        pixelFormat: ui.PixelFormat.rgba8888);
    final codec = await descriptor.instantiateCodec();
    final prepared = (await codec.getNextFrame()).image;
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    _prepared.add(prepared);
    return prepared;
  }

  @override
  void dispose() {
    for (final image in _prepared) {
      image.dispose();
    }
    _prepared.clear();
    _exportedSheets.clear();
    super.dispose();
  }

  @override
  Future<void> preload(FlameGame game) async {
    walk = await _loadExportedSheet(
        game, Assets.resources.images.newJanAnimationwalking46x587.path);
    punch =
        await loadSheet(game, Assets.resources.images.newJanMpunch46x585.path);
    idle = List.unmodifiable([punch.first]);
    midKick =
        await loadSheet(game, Assets.resources.images.newJanMkick46x583.path);
    highKick =
        await loadSheet(game, Assets.resources.images.newJanHkick46x585.path);
    jump = await _loadExportedSheet(
        game, Assets.resources.images.newJanAnimationJump46x582.path);
    playerKo = await _loadExportedSheet(
        game, Assets.resources.images.newJanAnimationko48x566.path,
        exportSize: (width: 276, height: 58));
    playerDead =
        await loadSheet(game, Assets.resources.images.jannDeath24x247.path);
    playerDeadWound = await loadSheet(
        game, Assets.resources.images.jannDeathWound24x247.path);
    mosquito =
        await loadSheet(game, Assets.resources.images.sprMosquito96x964.path);
    mosquitoHit =
        await loadSheet(game, Assets.resources.images.mosquitoHit32x325.path);
    mosquitoDead =
        await loadSheet(game, Assets.resources.images.mosquitoDead32x32t7.path);
    gruntIdle = await _loadExportedSheet(
        game, Assets.resources.images.gruntIdle47x587.path);
    gruntLight = await _loadExportedSheet(
        game, Assets.resources.images.gruntAttackLight47x584.path,
        exportSize: (width: 190, height: 58));
    gruntHeavy = await _loadExportedSheet(
        game, Assets.resources.images.gruntAttackHeavy47x584.path,
        exportSize: (width: 188, height: 59));
    gruntKo = await _loadExportedSheet(
        game, Assets.resources.images.gruntMosquitoDead47x587.path);
    gruntDead = await _loadExportedSheet(
        game, Assets.resources.images.gruntFatal47x5815.path);
    gruntIdleAnimation = SpriteAnimationSpec(gruntIdle, stepTime: .13);
    idleAnimation = SpriteAnimationSpec(idle, stepTime: .20);
    walkAnimation = SpriteAnimationSpec(walk, stepTime: .09);
    mosquitoAnimation = SpriteAnimationSpec(mosquito, stepTime: .09);
  }
}
