class LinkStats {
  const LinkStats({
    this.fps = 0.0,
    this.latencyMs = 0,
    this.bitrateMbps = 0.0,
    this.droppedFrames = 0,
    this.durationSeconds = 0,
    this.isStreaming = false,
    this.isRecording = false,
    this.videoWidth = 1080,
    this.videoHeight = 2400,
  });

  final double fps;
  final int latencyMs;
  final double bitrateMbps;
  final int droppedFrames;
  final int durationSeconds;
  final bool isStreaming;
  final bool isRecording;
  final int videoWidth;
  final int videoHeight;

  double get aspectRatio =>
      videoHeight > 0 ? videoWidth / videoHeight : 9 / 19.5;

  String get durationString {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  LinkStats copyWith({
    double? fps,
    int? latencyMs,
    double? bitrateMbps,
    int? droppedFrames,
    int? durationSeconds,
    bool? isStreaming,
    bool? isRecording,
    int? videoWidth,
    int? videoHeight,
  }) {
    return LinkStats(
      fps: fps ?? this.fps,
      latencyMs: latencyMs ?? this.latencyMs,
      bitrateMbps: bitrateMbps ?? this.bitrateMbps,
      droppedFrames: droppedFrames ?? this.droppedFrames,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isStreaming: isStreaming ?? this.isStreaming,
      isRecording: isRecording ?? this.isRecording,
      videoWidth: videoWidth ?? this.videoWidth,
      videoHeight: videoHeight ?? this.videoHeight,
    );
  }
}
