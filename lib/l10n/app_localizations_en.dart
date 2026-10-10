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
}
