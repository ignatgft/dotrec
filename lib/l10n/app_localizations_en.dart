// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DotRec';

  @override
  String get start => 'Start recording';

  @override
  String get stop => 'Stop';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get saved => 'Recording saved';

  @override
  String get open => 'Open';

  @override
  String get share => 'Share';

  @override
  String get delete => 'Delete';

  @override
  String get err_space => 'Low storage. Free up at least 200 MB';

  @override
  String get err_consent =>
      'Recording didn\'t start. Screen access wasn\'t granted';

  @override
  String get err_mic => 'No microphone access. Open app settings';

  @override
  String fps_cap(int n) {
    return 'Your screen supports up to $n Hz';
  }

  @override
  String get audio_blocked => 'Some apps blocked audio capture';

  @override
  String get empty_lib_title => 'Your recordings will appear here';

  @override
  String get ready => 'READY';

  @override
  String get paused => 'PAUSED';

  @override
  String get saving => 'SAVING';

  @override
  String get settings => 'Settings';

  @override
  String get library => 'Recordings';

  @override
  String get presetFast => 'Fast';

  @override
  String get presetBalanced => 'Balanced';

  @override
  String get presetQuality => 'Quality';

  @override
  String get presetCustom => 'Custom';

  @override
  String get begin => 'Start';

  @override
  String get presetLabel => 'Preset';

  @override
  String get resolutionLabel => 'Resolution';

  @override
  String get micLabel => 'Microphone';

  @override
  String get sysAudioLabel => 'System audio';

  @override
  String get videoLabel => 'Video';

  @override
  String bitrateLabel(int n) {
    return 'Bitrate: $n Mbps';
  }

  @override
  String get codecLabel => 'Codec';

  @override
  String get hevcMissing => 'No hardware HEVC on this device';

  @override
  String get audioLabel => 'Audio';

  @override
  String get sysAudioV11 => 'System audio (v1.1)';

  @override
  String get recordingLabel => 'Recording';

  @override
  String get countdownLabel => 'Countdown';

  @override
  String get noneLabel => 'Off';

  @override
  String countdownSec(int n) {
    return '$n s';
  }

  @override
  String get appearanceLabel => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get langSystem => 'System';

  @override
  String get quickAccess => 'Quick access';

  @override
  String get quickAccessBody =>
      'The tile and widget start recording without opening the app.';

  @override
  String get addTileBtn => 'Add tile';

  @override
  String get tileAdded => 'Tile added';

  @override
  String get tileUnavailable => 'Requires Android 13+';

  @override
  String get aboutLine => 'DotRec works offline.';

  @override
  String get overlayNeedPermission =>
      'Requires the “Display over other apps” permission.';

  @override
  String get openPermission => 'Open permission';

  @override
  String get errorLabel => 'Error';

  @override
  String get onboardingTitle => 'Screen recording without the clutter';

  @override
  String get ob1 => 'Works without internet';

  @override
  String get ob2 => 'No ads or watermarks';

  @override
  String get ob3 => 'Files in Movies/DotRec';

  @override
  String get guidesTitle => 'Guides & permissions';

  @override
  String get guides => 'Guides';

  @override
  String get openSettings => 'Open settings';

  @override
  String get guideCaptureTitle => 'Screen access';

  @override
  String get guideCaptureBody =>
      'When you start recording, Android shows a system screen-access dialog. On Android 14+ consent is asked on every recording — a system limitation.';

  @override
  String get guideMicTitle => 'Microphone';

  @override
  String get guideMicBody =>
      '1. Turn on the Microphone switch. 2. Allow access in the system dialog. 3. If you denied it, open app settings and enable the microphone manually.';

  @override
  String get guideNotifTitle => 'Notifications';

  @override
  String get guideNotifBody =>
      'The notification with timer and Pause/Stop buttons appears on first recording. If it\'s missing, allow notifications in app settings.';

  @override
  String get guideOverlayTitle => 'Floating pill';

  @override
  String get guideOverlayBody =>
      'The pill is off by default. 1. Enable it in settings. 2. Allow “Display over other apps” on the system screen. The pill should not appear in recordings.';

  @override
  String get guideBatteryTitle => 'Battery & background';

  @override
  String get guideBatteryBody =>
      'Some firmwares (Xiaomi, Samsung) kill background recording to save battery. Open battery settings, find DotRec and allow background activity.';

  @override
  String get guideTileTitle => 'Quick settings tile';

  @override
  String get guideTileBody =>
      '1. Open quick settings and tap Edit. 2. Drag the “Record” tile into the active area. On Android 13+ use the button below.';

  @override
  String get linkTitle => 'Stream to PC';

  @override
  String get linkMethod => 'Method';

  @override
  String get linkWifiPin => 'Wi-Fi pairing code';

  @override
  String get linkPinHint => 'Enter on PC. Code is valid for 2 minutes';

  @override
  String get linkStreamQuality => 'Stream quality';

  @override
  String get linkAudioToPc => 'Audio to PC';

  @override
  String get linkBlankScreen => 'Blank phone screen';

  @override
  String get linkParallelRecord => 'Record to phone in parallel';

  @override
  String get linkStartStream => 'Start streaming';

  @override
  String get linkStopStream => 'Stop streaming';

  @override
  String get linkWaiting => 'Waiting for PC...';

  @override
  String get linkConnected => 'Connected';

  @override
  String get deviceCheckTitle => 'Device check';

  @override
  String get deviceCheckBtn => 'Check device';

  @override
  String get screenResolution => 'Screen resolution';

  @override
  String get refreshRates => 'Refresh rate';

  @override
  String get hevcSupport => 'Hardware HEVC';

  @override
  String get freeStorage => 'Free storage';

  @override
  String get fileSizeEstimate => 'Estimated size';
}
