import 'dart:ui' as ui;
import 'package:flame/components.dart' show RectangleComponent;
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/game/view/pixel_perfect_viewport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final ratio in [1.0, 1.25, 2.0, 3.0]) {
    test('viewport uses whole physical pixels at device ratio $ratio',
        () async {
      final viewport = PixelPerfectViewport(
          resolution: Vector2(256, 128), devicePixelRatio: ratio);
      final game = FlameGame();
      game.camera.viewport = viewport;
      game.onGameResize(Vector2(1001, 601));
      // ignore: invalid_use_of_internal_member
      await game.load();
      // ignore: invalid_use_of_internal_member
      game.mount();
      await game.ready();
      final physicalScale = viewport.scale.x * ratio;
      expect(physicalScale, closeTo(physicalScale.round(), .00001));
      expect(viewport.scale.y, viewport.scale.x);
      expect(viewport.position.x * ratio,
          closeTo((viewport.position.x * ratio).round(), .00001));
      expect(viewport.position.y * ratio,
          closeTo((viewport.position.y * ratio).round(), .00001));
      expect(viewport.size.x, lessThanOrEqualTo(1001));
      expect(viewport.size.y, lessThanOrEqualTo(601));
      expect(viewport.virtualSize, Vector2(256, 128));
      // A marker in the bottom-right quadrant catches an incorrectly centred
      // clip rectangle even when all scale/size calculations are correct.
      await viewport.add(RectangleComponent(
          position: Vector2(240, 110),
          size: Vector2.all(10),
          paint: ui.Paint()..color = const ui.Color(0xFFFF00FF)));
      await game.ready();
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final image = picture.toImageSync(1001, 601);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final marker = viewport.localToGlobal(Vector2(245, 115));
      final offset = (marker.y.floor() * 1001 + marker.x.floor()) * 4;
      expect(bytes!.buffer.asUint8List().sublist(offset, offset + 4),
          [255, 0, 255, 255]);
      image.dispose();
      picture.dispose();
      game.onGameResize(Vector2(1200, 600));
      expect(viewport.scale.x * ratio,
          closeTo((viewport.scale.x * ratio).round(), .00001));
      expect(viewport.virtualSize, Vector2(256, 128));
      game.removeAll(game.children.toList());
      await game.ready();
      game.onDispose();
    });
  }
}
