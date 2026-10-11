import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('es'),
    Locale('de'),
    Locale('fr'),
    Locale('pt'),
    Locale('uk'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DotRec'**
  String get appTitle;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Recording saved'**
  String get saved;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @err_space.
  ///
  /// In en, this message translates to:
  /// **'Low storage. Free up at least 200 MB'**
  String get err_space;

  /// No description provided for @err_consent.
  ///
  /// In en, this message translates to:
  /// **'Recording didn\'t start. Screen access wasn\'t granted'**
  String get err_consent;

  /// No description provided for @err_mic.
  ///
  /// In en, this message translates to:
  /// **'No microphone access. Open app settings'**
  String get err_mic;

  /// No description provided for @fps_cap.
  ///
  /// In en, this message translates to:
  /// **'Your screen supports up to {n} Hz'**
  String fps_cap(int n);

  /// No description provided for @audio_blocked.
  ///
  /// In en, this message translates to:
  /// **'Some apps blocked audio capture'**
  String get audio_blocked;

  /// No description provided for @empty_lib_title.
  ///
  /// In en, this message translates to:
  /// **'Your recordings will appear here'**
  String get empty_lib_title;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get ready;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get paused;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'SAVING'**
  String get saving;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get library;

  /// No description provided for @presetFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get presetFast;

  /// No description provided for @presetBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get presetBalanced;

  /// No description provided for @presetQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get presetQuality;

  /// No description provided for @presetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get presetCustom;

  /// No description provided for @begin.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get begin;

  /// No description provided for @presetLabel.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get presetLabel;

  /// No description provided for @resolutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolutionLabel;

  /// No description provided for @micLabel.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get micLabel;

  /// No description provided for @sysAudioLabel.
  ///
  /// In en, this message translates to:
  /// **'System audio'**
  String get sysAudioLabel;

  /// No description provided for @videoLabel.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoLabel;

  /// No description provided for @bitrateLabel.
  ///
  /// In en, this message translates to:
  /// **'Bitrate: {n} Mbps'**
  String bitrateLabel(int n);

  /// No description provided for @codecLabel.
  ///
  /// In en, this message translates to:
  /// **'Codec'**
  String get codecLabel;

  /// No description provided for @hevcMissing.
  ///
  /// In en, this message translates to:
  /// **'No hardware HEVC on this device'**
  String get hevcMissing;

  /// No description provided for @audioLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioLabel;

  /// No description provided for @sysAudioV11.
  ///
  /// In en, this message translates to:
  /// **'System audio (v1.1)'**
  String get sysAudioV11;

  /// No description provided for @recordingLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingLabel;

  /// No description provided for @countdownLabel.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get countdownLabel;

  /// No description provided for @noneLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get noneLabel;

  /// No description provided for @countdownSec.
  ///
  /// In en, this message translates to:
  /// **'{n} s'**
  String countdownSec(int n);

  /// No description provided for @appearanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceLabel;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @langSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get langSystem;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get quickAccess;

  /// No description provided for @quickAccessBody.
  ///
  /// In en, this message translates to:
  /// **'The tile and widget start recording without opening the app.'**
  String get quickAccessBody;

  /// No description provided for @addTileBtn.
  ///
  /// In en, this message translates to:
  /// **'Add tile'**
  String get addTileBtn;

  /// No description provided for @tileAdded.
  ///
  /// In en, this message translates to:
  /// **'Tile added'**
  String get tileAdded;

  /// No description provided for @tileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Requires Android 13+'**
  String get tileUnavailable;

  /// No description provided for @aboutLine.
  ///
  /// In en, this message translates to:
  /// **'DotRec works offline.'**
  String get aboutLine;

  /// No description provided for @overlayNeedPermission.
  ///
  /// In en, this message translates to:
  /// **'Requires the “Display over other apps” permission.'**
  String get overlayNeedPermission;

  /// No description provided for @openPermission.
  ///
  /// In en, this message translates to:
  /// **'Open permission'**
  String get openPermission;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen recording without the clutter'**
  String get onboardingTitle;

  /// No description provided for @ob1.
  ///
  /// In en, this message translates to:
  /// **'Works without internet'**
  String get ob1;

  /// No description provided for @ob2.
  ///
  /// In en, this message translates to:
  /// **'No ads or watermarks'**
  String get ob2;

  /// No description provided for @ob3.
  ///
  /// In en, this message translates to:
  /// **'Files in Movies/DotRec'**
  String get ob3;

  /// No description provided for @guidesTitle.
  ///
  /// In en, this message translates to:
  /// **'Guides & permissions'**
  String get guidesTitle;

  /// No description provided for @guides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get guides;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @guideCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen access'**
  String get guideCaptureTitle;

  /// No description provided for @guideCaptureBody.
  ///
  /// In en, this message translates to:
  /// **'When you start recording, Android shows a system screen-access dialog. On Android 14+ consent is asked on every recording — a system limitation.'**
  String get guideCaptureBody;

  /// No description provided for @guideMicTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get guideMicTitle;

  /// No description provided for @guideMicBody.
  ///
  /// In en, this message translates to:
  /// **'1. Turn on the Microphone switch. 2. Allow access in the system dialog. 3. If you denied it, open app settings and enable the microphone manually.'**
  String get guideMicBody;

  /// No description provided for @guideNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get guideNotifTitle;

  /// No description provided for @guideNotifBody.
  ///
  /// In en, this message translates to:
  /// **'The notification with timer and Pause/Stop buttons appears on first recording. If it\'s missing, allow notifications in app settings.'**
  String get guideNotifBody;

  /// No description provided for @guideOverlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Floating pill'**
  String get guideOverlayTitle;

  /// No description provided for @guideOverlayBody.
  ///
  /// In en, this message translates to:
  /// **'The pill is off by default. 1. Enable it in settings. 2. Allow “Display over other apps” on the system screen. The pill should not appear in recordings.'**
  String get guideOverlayBody;

  /// No description provided for @guideBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery & background'**
  String get guideBatteryTitle;

  /// No description provided for @guideBatteryBody.
  ///
  /// In en, this message translates to:
  /// **'Some firmwares (Xiaomi, Samsung) kill background recording to save battery. Open battery settings, find DotRec and allow background activity.'**
  String get guideBatteryBody;

  /// No description provided for @guideTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick settings tile'**
  String get guideTileTitle;

  /// No description provided for @guideTileBody.
  ///
  /// In en, this message translates to:
  /// **'1. Open quick settings and tap Edit. 2. Drag the “Record” tile into the active area. On Android 13+ use the button below.'**
  String get guideTileBody;

  /// No description provided for @linkTitle.
  ///
  /// In en, this message translates to:
  /// **'Stream to PC'**
  String get linkTitle;

  /// No description provided for @linkMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get linkMethod;

  /// No description provided for @linkWifiPin.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi pairing code'**
  String get linkWifiPin;

  /// No description provided for @linkPinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter on PC. Code is valid for 2 minutes'**
  String get linkPinHint;

  /// No description provided for @linkStreamQuality.
  ///
  /// In en, this message translates to:
  /// **'Stream quality'**
  String get linkStreamQuality;

  /// No description provided for @linkAudioToPc.
  ///
  /// In en, this message translates to:
  /// **'Audio to PC'**
  String get linkAudioToPc;

  /// No description provided for @linkBlankScreen.
  ///
  /// In en, this message translates to:
  /// **'Blank phone screen'**
  String get linkBlankScreen;

  /// No description provided for @linkParallelRecord.
  ///
  /// In en, this message translates to:
  /// **'Record to phone in parallel'**
  String get linkParallelRecord;

  /// No description provided for @linkStartStream.
  ///
  /// In en, this message translates to:
  /// **'Start streaming'**
  String get linkStartStream;

  /// No description provided for @linkStopStream.
  ///
  /// In en, this message translates to:
  /// **'Stop streaming'**
  String get linkStopStream;

  /// No description provided for @linkWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for PC...'**
  String get linkWaiting;

  /// No description provided for @linkConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get linkConnected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'pt',
    'ru',
    'uk',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
