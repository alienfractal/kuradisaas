import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuradi_saased/game/view/crt_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('CRT shader changes pixels, draws once, and releases obsolete frames',
      () async {
    final crt = CrtRenderer();
    await crt.preload();
    expect(crt.available, isTrue);
    var draws = 0;
    Future<List<int>> frame() async {
      final recorder = PictureRecorder();
      crt.render(Canvas(recorder), const Size(32, 32), (canvas) {
        draws++;
        canvas.drawRect(const Rect.fromLTWH(0, 0, 32, 32),
            Paint()..color = const Color(0xFF808080));
      });
      final picture = recorder.endRecording();
      final image = picture.toImageSync(32, 32);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      final pixel = bytes!.buffer
          .asUint8List()
          .sublist((8 * 32 + 16) * 4, (8 * 32 + 16) * 4 + 4);
      image.dispose();
      picture.dispose();
      return pixel;
    }

    final first = await frame();
    expect(first, isNot([128, 128, 128, 255]));
    expect(first.last, 255);
    expect(draws, 1);
    crt.releaseFrame();
    expect(await frame(), first);
    expect(draws, 2);
    crt.dispose();
    expect(crt.available, isFalse);
  });
}
