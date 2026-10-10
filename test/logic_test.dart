import 'package:dotrec/platform/logic/file_namer.dart';
import 'package:dotrec/platform/logic/size_calc.dart';
import 'package:dotrec/platform/models/device_caps.dart';
import 'package:dotrec/platform/models/record_settings.dart';
import 'package:dotrec/platform/models/recorder_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SizeCalc', () {
    test('1080x2400 -> 720 даёт чётные стороны', () {
      final (int, int)? r = SizeCalc.fit(
        screenW: 1080,
        screenH: 2400,
        targetShortSide: 720,
      );
      expect(r, isNotNull);
      expect(r!.$1 % 2, 0);
      expect(r.$2 % 2, 0);
    });
    test('экран меньше целевого -> null', () {
      // 720p-экран не тянет 1080: пункт скрывается (FR-REC-02).
      expect(
        SizeCalc.fit(screenW: 720, screenH: 1280, targetShortSide: 1080),
        isNull,
      );
      expect(
        SizeCalc.fit(screenW: 1080, screenH: 2400, targetShortSide: 1080),
        isNotNull,
      );
      expect(
        SizeCalc.fit(screenW: 480, screenH: 800, targetShortSide: 720),
        isNull,
      );
    });
    test('нечётные размеры округляются вниз до чётных', () {
      final (int, int)? r = SizeCalc.fit(
        screenW: 1081,
        screenH: 2401,
        targetShortSide: 720,
      );
      expect(r, isNotNull);
      expect(r!.$1 % 2, 0);
      expect(r.$2 % 2, 0);
    });
    test('availableTargets скрывает недоступные', () {
      expect(SizeCalc.availableTargets(screenW: 720, screenH: 1280), [720]);
      expect(SizeCalc.availableTargets(screenW: 1080, screenH: 2400), [
        720,
        1080,
      ]);
      expect(SizeCalc.availableTargets(screenW: 1440, screenH: 3120), [
        720,
        1080,
        1440,
      ]);
    });
  });

  group('FileNamer', () {
    test('формат имени', () {
      expect(
        FileNamer.name(DateTime(2026, 10, 9, 17, 15, 0)),
        'DotRec_20261009_171500.mp4',
      );
    });
    test('паттерн', () {
      expect(FileNamer.pattern.hasMatch('DotRec_20261009_171500.mp4'), isTrue);
      expect(FileNamer.pattern.hasMatch('video.mp4'), isFalse);
    });
  });

  group('RecorderState сериализация', () {
    test('round-trip всех типов', () {
      const List<RecorderState> states = [
        Idle(),
        Countdown(3),
        Starting(),
        Saving(),
        Failed('encoder_error', 'msg'),
      ];
      for (final RecorderState s in states) {
        final RecorderState back = RecorderState.fromMap(s.toMap());
        expect(back.runtimeType, s.runtimeType);
      }
      const Recording rec = Recording(Duration(seconds: 42));
      expect(
        (RecorderState.fromMap(rec.toMap()) as Recording).elapsed.inSeconds,
        42,
      );
      const Paused p = Paused(Duration(seconds: 7));
      expect((RecorderState.fromMap(p.toMap()) as Paused).elapsed.inSeconds, 7);
      const Saved sv = Saved(
        uri: 'content://x',
        duration: Duration(seconds: 61),
        sizeBytes: 10,
      );
      final Saved back = RecorderState.fromMap(sv.toMap()) as Saved;
      expect(back.uri, 'content://x');
    });

    test('неизвестный тип -> Idle', () {
      expect(RecorderState.fromMap({'type': '???'}), isA<Idle>());
    });
  });

  group('RecordSettings', () {
    test('round-trip', () {
      const RecordSettings s = RecordSettings(
        resolution: 720,
        fps: 30,
        preset: 'fast',
      );
      expect(RecordSettings.fromMap(s.toMap()), s);
    });
    test('смена чипа -> custom', () {
      const RecordSettings s = RecordSettings();
      expect(s.withCustom(resolution: 720).preset, 'custom');
    });
    test('пресеты', () {
      expect(RecordSettings.presetNamed('fast').resolution, 720);
      expect(RecordSettings.presetNamed('balanced').fps, 60);
      expect(RecordSettings.presetNamed('quality').resolution, 1440);
    });
  });

  group('DeviceCaps', () {
    test('lowStorage порог 200МБ', () {
      expect(const DeviceCaps(freeBytes: 100 * 1024 * 1024).lowStorage, isTrue);
      expect(
        const DeviceCaps(freeBytes: 500 * 1024 * 1024).lowStorage,
        isFalse,
      );
    });
  });
}
