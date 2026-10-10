/// Возможности устройства (контракт v1).
class DeviceCaps {
  const DeviceCaps({
    this.screenWidth = 1080,
    this.screenHeight = 2400,
    this.supportedRefreshHz = const [60],
    this.maxRefreshHz = 60,
    this.hevcSupported = false,
    this.availableResolutions = const [720, 1080],
    this.freeBytes = 0,
  });

  final int screenWidth;
  final int screenHeight;
  final List<int> supportedRefreshHz;
  final int maxRefreshHz;
  final bool hevcSupported;
  final List<int> availableResolutions;
  final int freeBytes;

  factory DeviceCaps.fromMap(Map<Object?, Object?> m) {
    List<int> ints(Object? v, List<int> fallback) {
      if (v is List) {
        return [for (final e in v) (e as num).toInt()];
      }
      return fallback;
    }

    return DeviceCaps(
      screenWidth: (m['screenWidth'] as num?)?.toInt() ?? 1080,
      screenHeight: (m['screenHeight'] as num?)?.toInt() ?? 2400,
      supportedRefreshHz: ints(m['supportedRefreshHz'], const [60]),
      maxRefreshHz: (m['maxRefreshHz'] as num?)?.toInt() ?? 60,
      hevcSupported: (m['hevcSupported'] as bool?) ?? false,
      availableResolutions: ints(m['availableResolutions'], const [720, 1080]),
      freeBytes: (m['freeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
    'screenWidth': screenWidth,
    'screenHeight': screenHeight,
    'supportedRefreshHz': supportedRefreshHz,
    'maxRefreshHz': maxRefreshHz,
    'hevcSupported': hevcSupported,
    'availableResolutions': availableResolutions,
    'freeBytes': freeBytes,
  };

  bool get lowStorage => freeBytes < 200 * 1024 * 1024;
}
