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
      frontKick,
      highKick,
      veryHighKick,
      jump,
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
  final Map<String, Future<List<Sprite>>> _gruntSheets = {};

  Future<List<Sprite>> _loadGruntSheet(FlameGame game, String path,
      {bool useSheetDimensions = false}) async {
    final pending = _gruntSheets.putIfAbsent(path, () async {
      final spec = SpriteSheetSpec.fromPath(path);
      game.images.prefix = '';
      final original = await game.images.load(path);
      if (!useSheetDimensions) spec.validate(original);
      final source = await _removeGruntBackground(original);
      final width = useSheetDimensions ? spec.width : 32;
      final height = useSheetDimensions ? spec.height : 40;
      final preparedSpec = SpriteSheetSpec(width, height, spec.frames);
      if (source.width == width * spec.frames && source.height == height) {
        return preparedSpec.slice(source);
      }
      // The filename defines the frame and draw size. Fit whole-sheet exports
      // to that layout once at load time; components draw the frames at 1:1.
      final sourceWidth = source.width / spec.frames;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint()
        ..filterQuality = ui.FilterQuality.none
        ..isAntiAlias = false;
      for (var i = 0; i < spec.frames; i++) {
        canvas.drawImageRect(
            source,
            ui.Rect.fromLTWH(
                i * sourceWidth, 0, sourceWidth, source.height.toDouble()),
            ui.Rect.fromLTWH(
                (i * width).toDouble(), 0, width.toDouble(), height.toDouble()),
            paint);
      }
      final picture = recorder.endRecording();
      final image = picture.toImageSync(spec.frames * width, height);
      picture.dispose();
      _prepared.add(image);
      return preparedSpec.slice(image);
    });
    try {
      return await pending;
    } catch (_) {
      if (identical(_gruntSheets[path], pending)) _gruntSheets.remove(path);
      rethrow;
    }
  }

  @override
  Future<ui.Image> prepareImage(ui.Image image) async {
    // Grunt exports use opaque green as their background key.
    final gruntExport = (image.height == 119 && image.width % 95 == 0) ||
        (image.height == 58 && image.width % 47 == 0);
    if (!gruntExport) return image;
    return _removeGruntBackground(image);
  }

  Future<ui.Image> _removeGruntBackground(ui.Image image) async {
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final pixels =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    for (var i = 0; i < pixels.length; i += 4) {
      if (pixels[i] == 0 && pixels[i + 1] == 255 && pixels[i + 2] == 0) {
        // Raw image descriptors use premultiplied alpha; clear RGB as well.
        pixels.fillRange(i, i + 4, 0);
      }
    }
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
    _gruntSheets.clear();
    super.dispose();
  }

  @override
  Future<void> preload(FlameGame game) async {
    idle = await loadSheet(game, Assets.resources.images.jannIdle80x994.path);
    walk = await loadSheet(game, Assets.resources.images.jannWalk92x998.path);
    punch =
        await loadSheet(game, Assets.resources.images.jaanPunch108x984.path);
    // Existing combat stage IDs now present low -> frontal -> high kicks.
    frontKick =
        await loadSheet(game, Assets.resources.images.jannLowKick24x246.path);
    highKick = await loadSheet(
        game, Assets.resources.images.jannFrontalKick24x247.path);
    veryHighKick =
        await loadSheet(game, Assets.resources.images.jannHighKick24x247.path);
    jump = await loadSheet(game, Assets.resources.images.jaanJump61x995.path);
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
    gruntIdle = await _loadGruntSheet(game,
        Assets.resources.images.mosquitoGruntAnimationIdleSmall47x587.path,
        useSheetDimensions: true);
    gruntLight = await _loadGruntSheet(
        game,
        Assets
            .resources.images.mosquitoGruntAnimationLightAttackSmall47x584.path,
        useSheetDimensions: true);
    gruntHeavy = await _loadGruntSheet(
        game,
        Assets
            .resources.images.mosquitoGruntAnimationHeavyAttackSmall47x584.path,
        useSheetDimensions: true);
    gruntKo = await _loadGruntSheet(
        game, Assets.resources.images.mosquitoGruntKo95x1197Png.path);
    gruntDead = await _loadGruntSheet(
        game, Assets.resources.images.mosquitoGruntDeath195x11912.path);
    gruntIdleAnimation = SpriteAnimationSpec(gruntIdle, stepTime: .13);
    idleAnimation = SpriteAnimationSpec(idle, stepTime: .20);
    walkAnimation = SpriteAnimationSpec(walk, stepTime: .09);
    mosquitoAnimation = SpriteAnimationSpec(mosquito, stepTime: .09);
  }
}
