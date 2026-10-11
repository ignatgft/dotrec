import 'package:dotrec_link_desktop/core/models/app_settings.dart';
import 'package:dotrec_link_desktop/core/providers/link_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings and SettingsNotifier tests', () {
    test('default settings have sensible initial values', () {
      const s = AppSettings();
      expect(s.themeMode, equals(ThemeMode.dark));
      expect(s.minimizeToTray, isTrue);
      expect(s.launchOnStartup, isFalse);
      expect(s.trayNotifications, isTrue);
      expect(s.autoReconnect, isTrue);
      expect(s.recordingsPath, equals('Videos/DotRec'));
      expect(s.screenshotsPath, equals('Pictures/DotRec'));
      expect(s.linkServerPort, equals(48211));
      expect(s.browserSourcePort, equals(48212));
      expect(s.obsWebSocketPort, equals(4455));
      expect(s.showFpsOverlay, isTrue);
      expect(s.showBitrateOverlay, isTrue);
      expect(s.showLatencyOverlay, isTrue);
    });

    test('toJson and fromJson preserve all fields', () {
      const s = AppSettings(
        themeMode: ThemeMode.light,
        minimizeToTray: false,
        launchOnStartup: true,
        trayNotifications: false,
        autoReconnect: false,
        recordingsPath: 'D:/CustomVideos',
        screenshotsPath: 'D:/CustomPics',
        obsAutoConnect: true,
        obsHost: '192.168.1.100',
        obsWebSocketPort: 4456,
        browserSourcePort: 49000,
        linkServerPort: 49001,
        showFpsOverlay: false,
        showBitrateOverlay: false,
        showLatencyOverlay: false,
        lowLatencyBuffer: false,
        hardwareAcceleration: false,
      );

      final json = s.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.themeMode, equals(ThemeMode.light));
      expect(restored.minimizeToTray, isFalse);
      expect(restored.launchOnStartup, isTrue);
      expect(restored.trayNotifications, isFalse);
      expect(restored.autoReconnect, isFalse);
      expect(restored.recordingsPath, equals('D:/CustomVideos'));
      expect(restored.screenshotsPath, equals('D:/CustomPics'));
      expect(restored.obsAutoConnect, isTrue);
      expect(restored.obsHost, equals('192.168.1.100'));
      expect(restored.obsWebSocketPort, equals(4456));
      expect(restored.browserSourcePort, equals(49000));
      expect(restored.linkServerPort, equals(49001));
      expect(restored.showFpsOverlay, isFalse);
      expect(restored.showBitrateOverlay, isFalse);
      expect(restored.showLatencyOverlay, isFalse);
      expect(restored.lowLatencyBuffer, isFalse);
      expect(restored.hardwareAcceleration, isFalse);
    });

    test('SettingsNotifier updates properties correctly', () {
      final notifier = SettingsNotifier();
      expect(notifier.state.themeMode, equals(ThemeMode.dark));

      notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state.themeMode, equals(ThemeMode.light));

      notifier.setMinimizeToTray(false);
      expect(notifier.state.minimizeToTray, isFalse);

      notifier.setLaunchOnStartup(true);
      expect(notifier.state.launchOnStartup, isTrue);

      notifier.setOverlayVisibility(fps: false, bitrate: false);
      expect(notifier.state.showFpsOverlay, isFalse);
      expect(notifier.state.showBitrateOverlay, isFalse);
      expect(notifier.state.showLatencyOverlay, isTrue); // unchanged

      notifier.resetToDefaults();
      expect(notifier.state.themeMode, equals(ThemeMode.dark));
      expect(notifier.state.minimizeToTray, isTrue);
      expect(notifier.state.showFpsOverlay, isTrue);
    });
  });
}
