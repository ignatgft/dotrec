import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dot_link_icons.dart';
import '../models/app_settings.dart';
import '../models/device_info.dart';
import '../models/link_stats.dart';
import '../models/stream_preset.dart';
import '../../services/adb_service.dart';
import '../../services/browser_source_server.dart';
import '../../services/hotkey_service.dart';
import '../../services/link_client.dart';
import '../../services/obs_service.dart';
import '../../services/recording_service.dart';
import '../../services/tray_service.dart';

// ADB Service
final adbServiceProvider = Provider<AdbService>((ref) {
  final service = AdbService();
  service.startPolling();
  ref.onDispose(service.dispose);
  return service;
});

// Devices Stream
final devicesProvider = StreamProvider<List<DeviceInfo>>((ref) {
  final adb = ref.watch(adbServiceProvider);
  return adb.devicesStream;
});

// Selected Device
final selectedDeviceProvider = StateProvider<DeviceInfo?>((ref) {
  final devicesAsync = ref.watch(devicesProvider);
  return devicesAsync.when(
    data: (devices) {
      if (devices.isEmpty) return null;
      // Prefer ready device
      return devices.firstWhere(
        (d) => d.state == AdbState.ready,
        orElse: () => devices.first,
      );
    },
    loading: () => null,
    error: (err, stack) => null,
  );
});

// Stream Config
final streamConfigProvider = StateProvider<StreamConfig>((ref) {
  return const StreamConfig();
});

// Link Client
final linkClientProvider = Provider<LinkClient>((ref) {
  final client = LinkClient();
  ref.onDispose(client.dispose);
  return client;
});

// Link Client Status
final linkStatusProvider = StreamProvider<LinkClientStatus>((ref) {
  final client = ref.watch(linkClientProvider);
  return client.statusStream;
});

// Link Stats
final linkStatsProvider = StreamProvider<LinkStats>((ref) {
  final client = ref.watch(linkClientProvider);
  return client.statsStream;
});

// Recording Service
final recordingServiceProvider = Provider<RecordingService>((ref) {
  return RecordingService();
});

// Browser Source Server
final browserSourceServerProvider = Provider<BrowserSourceServer>((ref) {
  final server = BrowserSourceServer();
  final client = ref.watch(linkClientProvider);
  server.start(port: 48212, linkClient: client);
  ref.onDispose(server.stop);
  return server;
});

// OBS Service
final obsServiceProvider = Provider<ObsService>((ref) {
  final service = ObsService();
  ref.onDispose(service.dispose);
  return service;
});

// OBS Status
final obsStatusProvider = StreamProvider<ObsStatus>((ref) {
  final obs = ref.watch(obsServiceProvider);
  return obs.statusStream;
});

// Tray Service
final trayServiceProvider = Provider<TrayService>((ref) {
  final service = TrayService();
  ref.onDispose(service.dispose);
  return service;
});

// Hotkey Service
final hotkeyServiceProvider = Provider<HotkeyService>((ref) {
  final service = HotkeyService();
  ref.onDispose(service.dispose);
  return service;
});

// App Settings Notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  void update(AppSettings Function(AppSettings current) updater) {
    state = updater(state);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setMinimizeToTray(bool value) {
    state = state.copyWith(minimizeToTray: value);
  }

  void setLaunchOnStartup(bool value) {
    state = state.copyWith(launchOnStartup: value);
  }

  void setTrayNotifications(bool value) {
    state = state.copyWith(trayNotifications: value);
  }

  void setAutoReconnect(bool value) {
    state = state.copyWith(autoReconnect: value);
  }

  void setRecordingsPath(String path) {
    state = state.copyWith(recordingsPath: path);
  }

  void setScreenshotsPath(String path) {
    state = state.copyWith(screenshotsPath: path);
  }

  void setOverlayVisibility({bool? fps, bool? bitrate, bool? latency}) {
    state = state.copyWith(
      showFpsOverlay: fps ?? state.showFpsOverlay,
      showBitrateOverlay: bitrate ?? state.showBitrateOverlay,
      showLatencyOverlay: latency ?? state.showLatencyOverlay,
    );
  }

  void resetToDefaults() {
    state = const AppSettings();
  }
}

final appSettingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
      return SettingsNotifier();
    });

// Desktop Navigation Tab
enum DesktopTab {
  mirror('Зеркало', DotLinkIcons.mirror),
  connection('Подключение', DotLinkIcons.usb),
  obs('OBS Studio', DotLinkIcons.obs),
  settings('Настройки', DotLinkIcons.settings);

  const DesktopTab(this.label, this.iconAsset);
  final String label;
  final String iconAsset;
}

final activeTabProvider = StateProvider<DesktopTab>((ref) {
  return DesktopTab.mirror;
});

// Theme Mode
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.dark;
});
