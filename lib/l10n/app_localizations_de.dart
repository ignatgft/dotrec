// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'DotRec';

  @override
  String get start => 'Aufnahme starten';

  @override
  String get stop => 'Stoppen';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get saved => 'Aufnahme gespeichert';

  @override
  String get open => 'Öffnen';

  @override
  String get share => 'Teilen';

  @override
  String get delete => 'Löschen';

  @override
  String get err_space => 'Wenig Speicher. Mindestens 200 MB freigeben';

  @override
  String get err_consent => 'Nicht gestartet. Kein Bildschirmzugriff';

  @override
  String get err_mic => 'Kein Mikrofonzugriff. App-Einstellungen öffnen';

  @override
  String fps_cap(int n) {
    return 'Dein Bildschirm unterstützt bis zu $n Hz';
  }

  @override
  String get audio_blocked => 'Manche Apps haben Audio-Aufnahme blockiert';

  @override
  String get empty_lib_title => 'Deine Aufnahmen erscheinen hier';

  @override
  String get ready => 'BEREIT';

  @override
  String get paused => 'PAUSE';

  @override
  String get saving => 'SPEICHERN';

  @override
  String get settings => 'Einstellungen';

  @override
  String get library => 'Aufnahmen';

  @override
  String get presetFast => 'Schnell';

  @override
  String get presetBalanced => 'Ausgewogen';

  @override
  String get presetQuality => 'Qualität';

  @override
  String get presetCustom => 'Eigen';

  @override
  String get begin => 'Start';

  @override
  String get presetLabel => 'Profil';

  @override
  String get resolutionLabel => 'Auflösung';

  @override
  String get micLabel => 'Mikrofon';

  @override
  String get sysAudioLabel => 'Systemton';

  @override
  String get videoLabel => 'Video';

  @override
  String bitrateLabel(int n) {
    return 'Bitrate: $n Mbit/s';
  }

  @override
  String get codecLabel => 'Codec';

  @override
  String get hevcMissing => 'Kein Hardware-HEVC';

  @override
  String get audioLabel => 'Ton';

  @override
  String get sysAudioV11 => 'Systemton (v1.1)';

  @override
  String get recordingLabel => 'Aufnahme';

  @override
  String get countdownLabel => 'Countdown';

  @override
  String get noneLabel => 'Aus';

  @override
  String countdownSec(int n) {
    return '$n s';
  }

  @override
  String get appearanceLabel => 'Darstellung';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get language => 'Sprache';

  @override
  String get langSystem => 'System';

  @override
  String get quickAccess => 'Schnellzugriff';

  @override
  String get quickAccessBody =>
      'Kachel und Widget starten ohne die App zu öffnen.';

  @override
  String get addTileBtn => 'Kachel hinzufügen';

  @override
  String get tileAdded => 'Kachel hinzugefügt';

  @override
  String get tileUnavailable => 'Erfordert Android 13+';

  @override
  String get aboutLine => 'DotRec arbeitet offline.';

  @override
  String get overlayNeedPermission => 'Erfordert „Über anderen Apps“.';

  @override
  String get openPermission => 'Berechtigung öffnen';

  @override
  String get errorLabel => 'Fehler';

  @override
  String get onboardingTitle => 'Bildschirm aufnehmen, ohne Schnickschnack';

  @override
  String get ob1 => 'Funktioniert offline';

  @override
  String get ob2 => 'Keine Werbung, kein Wasserzeichen';

  @override
  String get ob3 => 'Dateien in Movies/DotRec';

  @override
  String get guidesTitle => 'Anleitungen und Berechtigungen';

  @override
  String get guides => 'Anleitungen';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get guideCaptureTitle => 'Bildschirmzugriff';

  @override
  String get guideCaptureBody =>
      'Beim Start zeigt Android einen Systemdialog für den Bildschirmzugriff. Ab Android 14 wird bei jeder Aufnahme gefragt – eine Systemvorgabe.';

  @override
  String get guideMicTitle => 'Mikrofon';

  @override
  String get guideMicBody =>
      '1. Schalte „Mikrofon“ ein. 2. Erlaube den Zugriff im Systemdialog. 3. Bei Ablehnung: App-Einstellungen öffnen und Mikrofon manuell aktivieren.';

  @override
  String get guideNotifTitle => 'Mitteilungen';

  @override
  String get guideNotifBody =>
      'Die Mitteilung mit Timer und Pause/Stopp erscheint bei der ersten Aufnahme. Falls sie fehlt, erlaube Mitteilungen in den App-Einstellungen.';

  @override
  String get guideOverlayTitle => 'Schwebendes Fenster';

  @override
  String get guideOverlayBody =>
      'Standardmäßig aus. 1. In den Einstellungen einschalten. 2. „Über anderen Apps einblenden“ erlauben. Es sollte nicht in Aufnahmen erscheinen.';

  @override
  String get guideBatteryTitle => 'Akku und Hintergrund';

  @override
  String get guideBatteryBody =>
      'Manche Oberflächen (Xiaomi, Samsung) beenden Aufnahmen im Hintergrund zum Akkusparen. Öffne die Akku-Einstellungen, suche DotRec und erlaube Hintergrundaktivität.';

  @override
  String get guideTileTitle => 'Kachel';

  @override
  String get guideTileBody =>
      '1. Schnelleinstellungen öffnen und Bearbeiten tippen. 2. Die Kachel „Aufnahme“ in den aktiven Bereich ziehen. Ab Android 13 geht es auch über die Schaltfläche unten.';
}
