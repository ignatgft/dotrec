/// Настройки записи. Зеркало контракта каналов v1.
class RecordSettings {
  const RecordSettings({
    this.resolution = 1080,
    this.fps = 60,
    this.bitrateMbps = 20,
    this.codec = 'h264',
    this.mic = false,
    this.systemAudio = false,
    this.countdownSec = 3,
    this.preset = 'balanced',
    this.overlayPill = false,
    this.themeMode = 'system',
  });

  final int resolution;
  final int fps;
  final int bitrateMbps;
  final String codec;
  final bool mic;
  final bool systemAudio;
  final int countdownSec;
  final String preset;
  final bool overlayPill;
  final String themeMode;

  static const List<int> allowedResolutions = [720, 1080, 1440];
  static const List<int> allowedFps = [30, 60, 90];
  static const List<int> allowedBitrates = [4, 8, 12, 20, 40];
  static const List<String> allowedCodecs = ['h264', 'hevc'];
  static const List<int> allowedCountdowns = [0, 3, 5];
  static const List<String> allowedPresets = [
    'fast',
    'balanced',
    'quality',
    'game',
    'custom',
  ];
  static const List<String> allowedThemeModes = ['system', 'light', 'dark'];

  RecordSettings copyWith({
    int? resolution,
    int? fps,
    int? bitrateMbps,
    String? codec,
    bool? mic,
    bool? systemAudio,
    int? countdownSec,
    String? preset,
    bool? overlayPill,
    String? themeMode,
  }) {
    return RecordSettings(
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      bitrateMbps: bitrateMbps ?? this.bitrateMbps,
      codec: codec ?? this.codec,
      mic: mic ?? this.mic,
      systemAudio: systemAudio ?? this.systemAudio,
      countdownSec: countdownSec ?? this.countdownSec,
      preset: preset ?? this.preset,
      overlayPill: overlayPill ?? this.overlayPill,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  factory RecordSettings.fromMap(Map<Object?, Object?> m) {
    return RecordSettings(
      resolution: (m['resolution'] as num?)?.toInt() ?? 1080,
      fps: (m['fps'] as num?)?.toInt() ?? 60,
      bitrateMbps: (m['bitrateMbps'] as num?)?.toInt() ?? 20,
      codec: (m['codec'] as String?) ?? 'h264',
      mic: (m['mic'] as bool?) ?? false,
      systemAudio: (m['systemAudio'] as bool?) ?? false,
      countdownSec: (m['countdownSec'] as num?)?.toInt() ?? 3,
      preset: (m['preset'] as String?) ?? 'balanced',
      overlayPill: (m['overlayPill'] as bool?) ?? false,
      themeMode: (m['themeMode'] as String?) ?? 'system',
    );
  }

  Map<String, Object?> toMap() => {
    'resolution': resolution,
    'fps': fps,
    'bitrateMbps': bitrateMbps,
    'codec': codec,
    'mic': mic,
    'systemAudio': systemAudio,
    'countdownSec': countdownSec,
    'preset': preset,
    'overlayPill': overlayPill,
    'themeMode': themeMode,
  };

  /// При смене чипа пресет становится «Свой» (см. 06).
  RecordSettings withCustom({int? resolution, int? fps}) => copyWith(
    resolution: resolution ?? this.resolution,
    fps: fps ?? this.fps,
    preset: 'custom',
  );

  static RecordSettings presetNamed(String name) => switch (name) {
    'fast' => const RecordSettings(
      resolution: 720,
      fps: 30,
      bitrateMbps: 6,
      preset: 'fast',
    ),
    'quality' => const RecordSettings(
      resolution: 1440,
      fps: 60,
      bitrateMbps: 40,
      preset: 'quality',
    ),
    'game' => const RecordSettings(
      resolution: 1080,
      fps: 60,
      bitrateMbps: 20,
      systemAudio: true,
      mic: false,
      preset: 'game',
    ),
    'balanced' || _ => const RecordSettings(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordSettings &&
          resolution == other.resolution &&
          fps == other.fps &&
          bitrateMbps == other.bitrateMbps &&
          codec == other.codec &&
          mic == other.mic &&
          systemAudio == other.systemAudio &&
          countdownSec == other.countdownSec &&
          preset == other.preset &&
          overlayPill == other.overlayPill &&
          themeMode == other.themeMode;

  @override
  int get hashCode => Object.hash(
    resolution,
    fps,
    bitrateMbps,
    codec,
    mic,
    systemAudio,
    countdownSec,
    preset,
    overlayPill,
    themeMode,
  );
}
