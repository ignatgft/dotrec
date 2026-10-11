enum VideoResolution {
  r720p('720', 1280, 720),
  r1080p('1080', 1920, 1080),
  r1440p('1440', 2560, 1440),
  rMax('Макс', 0, 0);

  const VideoResolution(this.label, this.width, this.height);
  final String label;
  final int width;
  final int height;
}

enum VideoFps {
  fps30(30, '30'),
  fps60(60, '60'),
  fps90(90, '90');

  const VideoFps(this.value, this.label);
  final int value;
  final String label;
}

enum VideoBitrate {
  b8(8, '8'),
  b16(16, '16'),
  b24(24, '24 Мбит/с'),
  b40(40, '40');

  const VideoBitrate(this.mbps, this.label);
  final int mbps;
  final String label;
}

class StreamConfig {
  const StreamConfig({
    this.resolution = VideoResolution.r1080p,
    this.fps = VideoFps.fps60,
    this.bitrate = VideoBitrate.b24,
    this.recordOnPc = false,
    this.phoneAudio = true,
    this.blankScreen = false,
  });

  final VideoResolution resolution;
  final VideoFps fps;
  final VideoBitrate bitrate;
  final bool recordOnPc;
  final bool phoneAudio;
  final bool blankScreen;

  StreamConfig copyWith({
    VideoResolution? resolution,
    VideoFps? fps,
    VideoBitrate? bitrate,
    bool? recordOnPc,
    bool? phoneAudio,
    bool? blankScreen,
  }) {
    return StreamConfig(
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      bitrate: bitrate ?? this.bitrate,
      recordOnPc: recordOnPc ?? this.recordOnPc,
      phoneAudio: phoneAudio ?? this.phoneAudio,
      blankScreen: blankScreen ?? this.blankScreen,
    );
  }
}
