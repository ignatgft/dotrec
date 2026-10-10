import 'package:dotrec/platform/logic/bitrate_calc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BitrateCalc', () {
    // NB: docs/04 говорит «1080×2400·60 даёт около 20», но формула
    // w*h*fps*0.07 даёт 10.9 Мбит/с → ближайший шаг 12. Тест фиксирует
    // формулу (источник правды — reference/BitrateCalc.kt).
    test('1080x2400 60fps h264 -> 12 по формуле', () {
      expect(
        BitrateCalc.defaultMbps(
          width: 1080,
          height: 2400,
          fps: 60,
          hevc: false,
        ),
        12,
      );
    });
    test('720p 30fps h264 -> 4..8', () {
      final int v = BitrateCalc.defaultMbps(
        width: 720,
        height: 1280,
        fps: 30,
        hevc: false,
      );
      expect([4, 8], contains(v));
    });
    test('hevc ниже чем h264 на тех же параметрах', () {
      final int h264 = BitrateCalc.defaultMbps(
        width: 1080,
        height: 2400,
        fps: 60,
        hevc: false,
      );
      final int hevc = BitrateCalc.defaultMbps(
        width: 1080,
        height: 2400,
        fps: 60,
        hevc: true,
      );
      expect(hevc <= h264, isTrue);
    });
    test('1440 wide 60fps -> 20 по формуле', () {
      expect(
        BitrateCalc.defaultMbps(
          width: 1440,
          height: 3120,
          fps: 60,
          hevc: false,
        ),
        20,
      );
    });
    test('маленькое видео -> 4', () {
      expect(
        BitrateCalc.defaultMbps(width: 640, height: 480, fps: 30, hevc: false),
        4,
      );
    });
    test('только значения из списка', () {
      for (final w in [720, 1080, 1440]) {
        for (final f in [30, 60, 90]) {
          final int v = BitrateCalc.defaultMbps(
            width: w,
            height: w * 2,
            fps: f,
            hevc: false,
          );
          expect(BitrateCalc.stepsMbps, contains(v));
        }
      }
    });
  });
}
