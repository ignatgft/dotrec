import 'package:dotrec_link_desktop/services/hotkey_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HotkeyService tests', () {
    late HotkeyService hotkeys;

    setUp(() {
      hotkeys = HotkeyService();
    });

    tearDown(() {
      hotkeys.dispose();
    });

    test('default bindings contain all expected shortcuts', () {
      final bindings = hotkeys.bindings;
      expect(bindings.values, contains(HotkeyAction.toggleMirror));
      expect(bindings.values, contains(HotkeyAction.toggleRecording));
      expect(bindings.values, contains(HotkeyAction.captureScreenshot));
      expect(bindings.values, contains(HotkeyAction.requestKeyframe));
      expect(bindings.values, contains(HotkeyAction.openSettings));
      expect(bindings.values, contains(HotkeyAction.toggleFrameless));
      expect(bindings.values, contains(HotkeyAction.closeWindow));
      expect(bindings.values, contains(HotkeyAction.quitApp));

      // Check key activations
      final mirrorActivator = bindings.keys.firstWhere(
        (k) => bindings[k] == HotkeyAction.toggleMirror,
      );
      expect(mirrorActivator.trigger, equals(LogicalKeyboardKey.keyM));
      expect(mirrorActivator.control, isTrue);
      expect(mirrorActivator.shift, isTrue);
    });

    test('trigger emits action to actionStream', () async {
      final expectation = expectLater(
        hotkeys.actionStream,
        emitsInOrder([
          HotkeyAction.toggleMirror,
          HotkeyAction.toggleRecording,
          HotkeyAction.captureScreenshot,
        ]),
      );

      hotkeys.trigger(HotkeyAction.toggleMirror);
      hotkeys.trigger(HotkeyAction.toggleRecording);
      hotkeys.trigger(HotkeyAction.captureScreenshot);

      await expectation;
    });
  });
}
