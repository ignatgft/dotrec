import 'package:flutter/material.dart';

/// Настройки десктоп-клиента DotRec Link.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.minimizeToTray = true,
    this.launchOnStartup = false,
    this.trayNotifications = true,
    this.autoReconnect = true,
    this.recordingsPath = 'Videos/DotRec',
    this.screenshotsPath = 'Pictures/DotRec',
    this.obsAutoConnect = false,
    this.obsHost = '127.0.0.1',
    this.obsWebSocketPort = 4455,
    this.browserSourcePort = 48212,
    this.linkServerPort = 48211,
    this.showFpsOverlay = true,
    this.showBitrateOverlay = true,
    this.showLatencyOverlay = true,
    this.lowLatencyBuffer = true,
    this.hardwareAcceleration = true,
  });

  final ThemeMode themeMode;
  final bool minimizeToTray;
  final bool launchOnStartup;
  final bool trayNotifications;
  final bool autoReconnect;
  final String recordingsPath;
  final String screenshotsPath;
  final bool obsAutoConnect;
  final String obsHost;
  final int obsWebSocketPort;
  final int browserSourcePort;
  final int linkServerPort;
  final bool showFpsOverlay;
  final bool showBitrateOverlay;
  final bool showLatencyOverlay;
  final bool lowLatencyBuffer;
  final bool hardwareAcceleration;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? minimizeToTray,
    bool? launchOnStartup,
    bool? trayNotifications,
    bool? autoReconnect,
    String? recordingsPath,
    String? screenshotsPath,
    bool? obsAutoConnect,
    String? obsHost,
    int? obsWebSocketPort,
    int? browserSourcePort,
    int? linkServerPort,
    bool? showFpsOverlay,
    bool? showBitrateOverlay,
    bool? showLatencyOverlay,
    bool? lowLatencyBuffer,
    bool? hardwareAcceleration,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      launchOnStartup: launchOnStartup ?? this.launchOnStartup,
      trayNotifications: trayNotifications ?? this.trayNotifications,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      recordingsPath: recordingsPath ?? this.recordingsPath,
      screenshotsPath: screenshotsPath ?? this.screenshotsPath,
      obsAutoConnect: obsAutoConnect ?? this.obsAutoConnect,
      obsHost: obsHost ?? this.obsHost,
      obsWebSocketPort: obsWebSocketPort ?? this.obsWebSocketPort,
      browserSourcePort: browserSourcePort ?? this.browserSourcePort,
      linkServerPort: linkServerPort ?? this.linkServerPort,
      showFpsOverlay: showFpsOverlay ?? this.showFpsOverlay,
      showBitrateOverlay: showBitrateOverlay ?? this.showBitrateOverlay,
      showLatencyOverlay: showLatencyOverlay ?? this.showLatencyOverlay,
      lowLatencyBuffer: lowLatencyBuffer ?? this.lowLatencyBuffer,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'minimizeToTray': minimizeToTray,
    'launchOnStartup': launchOnStartup,
    'trayNotifications': trayNotifications,
    'autoReconnect': autoReconnect,
    'recordingsPath': recordingsPath,
    'screenshotsPath': screenshotsPath,
    'obsAutoConnect': obsAutoConnect,
    'obsHost': obsHost,
    'obsWebSocketPort': obsWebSocketPort,
    'browserSourcePort': browserSourcePort,
    'linkServerPort': linkServerPort,
    'showFpsOverlay': showFpsOverlay,
    'showBitrateOverlay': showBitrateOverlay,
    'showLatencyOverlay': showLatencyOverlay,
    'lowLatencyBuffer': lowLatencyBuffer,
    'hardwareAcceleration': hardwareAcceleration,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    ThemeMode mode = ThemeMode.dark;
    if (json['themeMode'] == 'light') mode = ThemeMode.light;
    if (json['themeMode'] == 'system') mode = ThemeMode.system;

    return AppSettings(
      themeMode: mode,
      minimizeToTray: json['minimizeToTray'] as bool? ?? true,
      launchOnStartup: json['launchOnStartup'] as bool? ?? false,
      trayNotifications: json['trayNotifications'] as bool? ?? true,
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      recordingsPath: json['recordingsPath'] as String? ?? 'Videos/DotRec',
      screenshotsPath: json['screenshotsPath'] as String? ?? 'Pictures/DotRec',
      obsAutoConnect: json['obsAutoConnect'] as bool? ?? false,
      obsHost: json['obsHost'] as String? ?? '127.0.0.1',
      obsWebSocketPort: json['obsWebSocketPort'] as int? ?? 4455,
      browserSourcePort: json['browserSourcePort'] as int? ?? 48212,
      linkServerPort: json['linkServerPort'] as int? ?? 48211,
      showFpsOverlay: json['showFpsOverlay'] as bool? ?? true,
      showBitrateOverlay: json['showBitrateOverlay'] as bool? ?? true,
      showLatencyOverlay: json['showLatencyOverlay'] as bool? ?? true,
      lowLatencyBuffer: json['lowLatencyBuffer'] as bool? ?? true,
      hardwareAcceleration: json['hardwareAcceleration'] as bool? ?? true,
    );
  }
}
