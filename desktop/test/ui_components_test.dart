import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dotrec_link_desktop/core/models/device_info.dart';
import 'package:dotrec_link_desktop/core/providers/link_providers.dart';
import 'package:dotrec_link_desktop/core/theme/dot_theme.dart';
import 'package:dotrec_link_desktop/features/main/main_screen.dart';

void main() {
  group('Desktop UI Components and Theme tests', () {
    testWidgets('MainScreen renders stream parameters and toggles correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedDeviceProvider.overrideWith(
              (ref) => const DeviceInfo(
                serial: '28271JEHN01358',
                model: 'Pixel 8',
                androidVersion: '15',
                transport: DeviceTransport.usb,
                state: AdbState.ready,
              ),
            ),
          ],
          child: MaterialApp(
            theme: DotTheme.dark(),
            home: const Scaffold(body: MainScreen()),
          ),
        ),
      );

      // Verify device summary text
      expect(find.text('Pixel 8 · USB · Android 15'), findsOneWidget);
      expect(find.text('Параметры потока'), findsOneWidget);
      expect(find.text('Опции трансляции'), findsOneWidget);
      expect(find.text('Зеркалировать'), findsOneWidget);
      expect(find.text('Ctrl+Shift+M'), findsOneWidget);

      // Verify preset labels
      expect(find.text('720'), findsOneWidget);
      expect(find.text('1080'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);

      // Tap 720 resolution chip
      await tester.tap(find.text('720'));
      await tester.pumpAndSettle();
    });
  });
}
