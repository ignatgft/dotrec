import 'package:dotrec_link_desktop/services/tray_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrayService tests', () {
    late TrayService tray;

    setUp(() {
      tray = TrayService();
    });

    tearDown(() {
      tray.dispose();
    });

    test('initial status is idle and window is visible', () {
      expect(tray.status, equals(TrayStatus.idle));
      expect(tray.isWindowVisible, isTrue);
      expect(tray.isTrayActive, isTrue);
    });

    test('setStatus updates status and emits event', () async {
      final expectation = expectLater(
        tray.statusStream,
        emitsInOrder([
          TrayStatus.streaming,
          TrayStatus.recording,
          TrayStatus.idle,
        ]),
      );

      tray.setStatus(TrayStatus.streaming);
      expect(tray.status, equals(TrayStatus.streaming));

      tray.setStatus(TrayStatus.recording);
      expect(tray.status, equals(TrayStatus.recording));

      tray.setStatus(TrayStatus.idle);
      expect(tray.status, equals(TrayStatus.idle));

      await expectation;
    });

    test('setWindowVisible toggles state and emits action', () async {
      final expectation = expectLater(
        tray.actionStream,
        emitsInOrder([
          TrayAction.hideWindow,
          TrayAction.showWindow,
        ]),
      );

      tray.setWindowVisible(false);
      expect(tray.isWindowVisible, isFalse);

      tray.setWindowVisible(true);
      expect(tray.isWindowVisible, isTrue);

      await expectation;
    });

    test('dispatchAction updates visibility and notifies listeners', () async {
      final expectation = expectLater(
        tray.actionStream,
        emitsInOrder([
          TrayAction.toggleRecording,
          TrayAction.requestKeyframe,
          TrayAction.hideWindow,
        ]),
      );

      tray.dispatchAction(TrayAction.toggleRecording);
      tray.dispatchAction(TrayAction.requestKeyframe);
      tray.dispatchAction(TrayAction.hideWindow);
      expect(tray.isWindowVisible, isFalse);

      await expectation;
    });

    test('notify emits TrayNotification with correct data', () async {
      final expectation = expectLater(
        tray.notificationStream,
        emits(predicate<TrayNotification>(
          (n) => n.title == 'Тест' && n.message == 'Сообщение в трее',
        )),
      );

      tray.notify('Тест', 'Сообщение в трее');

      await expectation;
    });
  });
}
