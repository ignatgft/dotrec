// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'DotRec';

  @override
  String get start => 'Démarrer';

  @override
  String get stop => 'Arrêter';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Reprendre';

  @override
  String get saved => 'Enregistrement terminé';

  @override
  String get open => 'Ouvrir';

  @override
  String get share => 'Partager';

  @override
  String get delete => 'Supprimer';

  @override
  String get err_space => 'Peu d\'espace. Libérez au moins 200 Mo';

  @override
  String get err_consent => 'Non démarré. Accès à l\'écran refusé';

  @override
  String get err_mic => 'Pas d\'accès au micro. Ouvrez les paramètres';

  @override
  String fps_cap(int n) {
    return 'Votre écran prend en charge jusqu\'à $n Hz';
  }

  @override
  String get audio_blocked => 'Certaines apps ont bloqué la capture audio';

  @override
  String get empty_lib_title => 'Vos enregistrements apparaîtront ici';

  @override
  String get ready => 'PRÊT';

  @override
  String get paused => 'PAUSE';

  @override
  String get saving => 'ENREGISTREMENT';

  @override
  String get settings => 'Paramètres';

  @override
  String get library => 'Enregistrements';

  @override
  String get presetFast => 'Rapide';

  @override
  String get presetBalanced => 'Équilibré';

  @override
  String get presetQuality => 'Qualité';

  @override
  String get presetCustom => 'Perso';

  @override
  String get begin => 'Commencer';

  @override
  String get presetLabel => 'Préréglage';

  @override
  String get resolutionLabel => 'Résolution';

  @override
  String get micLabel => 'Microphone';

  @override
  String get sysAudioLabel => 'Audio système';

  @override
  String get videoLabel => 'Vidéo';

  @override
  String bitrateLabel(int n) {
    return 'Débit : $n Mbit/s';
  }

  @override
  String get codecLabel => 'Codec';

  @override
  String get hevcMissing => 'Pas de HEVC matériel';

  @override
  String get audioLabel => 'Audio';

  @override
  String get sysAudioV11 => 'Audio système (v1.1)';

  @override
  String get recordingLabel => 'Enregistrement';

  @override
  String get countdownLabel => 'Compte à rebours';

  @override
  String get noneLabel => 'Non';

  @override
  String countdownSec(int n) {
    return '$n s';
  }

  @override
  String get appearanceLabel => 'Apparence';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get language => 'Langue';

  @override
  String get langSystem => 'Système';

  @override
  String get quickAccess => 'Accès rapide';

  @override
  String get quickAccessBody =>
      'La tuile et le widget démarrent sans ouvrir l\'app.';

  @override
  String get addTileBtn => 'Ajouter la tuile';

  @override
  String get tileAdded => 'Tuile ajoutée';

  @override
  String get tileUnavailable => 'Nécessite Android 13+';

  @override
  String get aboutLine => 'DotRec fonctionne hors ligne.';

  @override
  String get overlayNeedPermission =>
      'Nécessite «Par-dessus d\'autres applications».';

  @override
  String get openPermission => 'Ouvrir l\'autorisation';

  @override
  String get errorLabel => 'Erreur';

  @override
  String get onboardingTitle => 'Enregistrez votre écran, simplement';

  @override
  String get ob1 => 'Fonctionne hors ligne';

  @override
  String get ob2 => 'Sans pub ni filigrane';

  @override
  String get ob3 => 'Fichiers dans Movies/DotRec';

  @override
  String get guidesTitle => 'Guides et autorisations';

  @override
  String get guides => 'Guides';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get guideCaptureTitle => 'Accès à l\'écran';

  @override
  String get guideCaptureBody =>
      'Au démarrage, Android affiche un dialogue d\'accès à l\'écran. Sur Android 14+, l\'autorisation est demandée à chaque enregistrement : c\'est une limite du système.';

  @override
  String get guideMicTitle => 'Microphone';

  @override
  String get guideMicBody =>
      '1. Activez «Microphone». 2. Autorisez l\'accès dans le dialogue système. 3. En cas de refus, ouvrez les paramètres de l\'app et activez le micro manuellement.';

  @override
  String get guideNotifTitle => 'Notifications';

  @override
  String get guideNotifBody =>
      'La notification avec minuteur et boutons pause/stop apparaît au premier enregistrement. Si elle manque, autorisez les notifications dans les paramètres de l\'app.';

  @override
  String get guideOverlayTitle => 'Fenêtre flottante';

  @override
  String get guideOverlayBody =>
      'Désactivée par défaut. 1. Activez-la dans les réglages. 2. Autorisez «Afficher par-dessus d\'autres applications». Elle ne doit pas apparaître dans les enregistrements.';

  @override
  String get guideBatteryTitle => 'Batterie et arrière-plan';

  @override
  String get guideBatteryBody =>
      'Certaines surcouches (Xiaomi, Samsung) arrêtent l\'enregistrement en arrière-plan pour économiser la batterie. Ouvrez les paramètres de batterie, trouvez DotRec et autorisez l\'activité en arrière-plan.';

  @override
  String get guideTileTitle => 'Tuile';

  @override
  String get guideTileBody =>
      '1. Ouvrez les paramètres rapides et touchez Modifier. 2. Glissez la tuile «Enregistrer» dans la zone active. Sur Android 13+, utilisez le bouton ci-dessous.';

  @override
  String get linkTitle => 'Diffuser vers le PC';

  @override
  String get linkMethod => 'Méthode';

  @override
  String get linkWifiPin => 'Code de jumelage Wi-Fi';

  @override
  String get linkPinHint => 'Entrez sur le PC. Valide 2 minutes';

  @override
  String get linkStreamQuality => 'Qualité du flux';

  @override
  String get linkAudioToPc => 'Audio vers le PC';

  @override
  String get linkBlankScreen => 'Éteindre l écran du téléphone';

  @override
  String get linkParallelRecord => 'Enregistrer en parallèle sur téléphone';

  @override
  String get linkStartStream => 'Démarrer la diffusion';

  @override
  String get linkStopStream => 'Arrêter la diffusion';

  @override
  String get linkWaiting => 'En attente du PC...';

  @override
  String get linkConnected => 'Connecté';
}
