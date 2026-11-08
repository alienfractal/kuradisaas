import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/utils/animator_cache_service.dart';

class CountingCache extends SpriteAnimatorCache {
  int preparations = 0;
  @override
  Future<void> preload(FlameGame game) async {}
  @override
  Future<ui.Image> prepareImage(ui.Image image) async {
    preparations++;
    return image;
  }
}

ui.Image sheetImage(int width, int height) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sheet offsets skip empty cells and reject incompatible layouts', () {
    final image = sheetImage(128, 32);
    addTearDown(image.dispose);
    const spec = SpriteSheetSpec(32, 32, 3);
    final frames = spec.slice(image, firstFrame: 1);
    expect(frames.map((frame) => frame.srcPosition.x), [32, 64, 96]);
    expect(() => spec.slice(image), throwsFormatException);
    expect(() => spec.slice(image, firstFrame: -1), throwsFormatException);
    expect(() => const SpriteSheetSpec(0, 32, 4).slice(image),
        throwsFormatException);
  });

  test('animations loop or hold, with independent Flame playback', () {
    final image = sheetImage(96, 32);
    addTearDown(image.dispose);
    final frames = const SpriteSheetSpec(32, 32, 3).slice(image);
    final loop = SpriteAnimationSpec(frames, stepTime: .25);
    final once = SpriteAnimationSpec(frames, stepTime: .25, loop: false);
    expect(loop.frameAt(-1), same(frames.first));
    expect(loop.frameAt(.25), same(frames[1]));
    expect(loop.frameAt(.75), same(frames.first));
    expect(once.frameAt(99), same(frames.last));
    final first = loop.createAnimation().createTicker();
    final second = loop.createAnimation().createTicker();
    first.update(.3);
    expect(first.currentIndex, 1);
    expect(second.currentIndex, 0);
    expect(() => loop.frames.clear(), throwsUnsupportedError);
    final size = Vector2(20, 25);
    final sprite = SpriteSpec(frames.first, size);
    size.x = 999;
    final component = sprite.getSpriteComponent();
    component.size.x = 100;
    expect(sprite.getSpriteComponent().size, Vector2(20, 25));
  });

  test('concurrent requests share frames; failures can retry; games isolate',
      () async {
    final game = FlameGame();
    game.images.add('test_32x32-3.png', sheetImage(96, 32));
    addTearDown(game.images.clearCache);
    final cache = CountingCache();
    addTearDown(cache.dispose);
    final results = await Future.wait([
      cache.loadSheet(game, 'test_32x32-3.png'),
      cache.loadSheet(game, 'test_32x32-3.png'),
    ]);
    expect(results[0], same(results[1]));
    expect(cache.preparations, 1);
    await expectLater(
        cache.loadSheet(FlameGame(), 'test_32x32-3.png'), throwsStateError);
    game.images.add('bad_32x32-3.png', sheetImage(32, 32));
    await expectLater(
        cache.loadSheet(game, 'bad_32x32-3.png'), throwsFormatException);
    game.images.add('bad_32x32-3.png', sheetImage(96, 32));
    expect(await cache.loadSheet(game, 'bad_32x32-3.png'), hasLength(3));
    expect(cache.preparations, 2);
  });
}
