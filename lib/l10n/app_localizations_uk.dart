// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'DotRec';

  @override
  String get start => 'Почати запис';

  @override
  String get stop => 'Зупинити';

  @override
  String get pause => 'Пауза';

  @override
  String get resume => 'Продовжити';

  @override
  String get saved => 'Запис збережено';

  @override
  String get open => 'Відкрити';

  @override
  String get share => 'Поділитися';

  @override
  String get delete => 'Видалити';

  @override
  String get err_space => 'Мало місця. Звільніть щонайменше 200 МБ';

  @override
  String get err_consent => 'Запис не почався. Немає доступу до екрана';

  @override
  String get err_mic => 'Немає доступу до мікрофона. Відкрийте налаштування';

  @override
  String fps_cap(int n) {
    return 'Екран підтримує до $n Гц';
  }

  @override
  String get audio_blocked => 'Деякі застосунки заборонили захоплення звуку';

  @override
  String get empty_lib_title => 'Тут з\'являться ваші записи';

  @override
  String get ready => 'ГОТОВО';

  @override
  String get paused => 'ПАУЗА';

  @override
  String get saving => 'ЗБЕРЕЖЕННЯ';

  @override
  String get settings => 'Налаштування';

  @override
  String get library => 'Записи';

  @override
  String get presetFast => 'Швидко';

  @override
  String get presetBalanced => 'Баланс';

  @override
  String get presetQuality => 'Якість';

  @override
  String get presetCustom => 'Свій';

  @override
  String get begin => 'Почати';

  @override
  String get presetLabel => 'Пресет';

  @override
  String get resolutionLabel => 'Роздільна здатність';

  @override
  String get micLabel => 'Мікрофон';

  @override
  String get sysAudioLabel => 'Системний звук';

  @override
  String get videoLabel => 'Відео';

  @override
  String bitrateLabel(int n) {
    return 'Бітрейт: $n Мбіт/с';
  }

  @override
  String get codecLabel => 'Кодек';

  @override
  String get hevcMissing => 'Немає апаратного HEVC';

  @override
  String get audioLabel => 'Звук';

  @override
  String get sysAudioV11 => 'Системний звук (v1.1)';

  @override
  String get recordingLabel => 'Запис';

  @override
  String get countdownLabel => 'Зворотний відлік';

  @override
  String get noneLabel => 'Ні';

  @override
  String countdownSec(int n) {
    return '$n с';
  }

  @override
  String get appearanceLabel => 'Вигляд';

  @override
  String get themeLight => 'Світла';

  @override
  String get themeDark => 'Темна';

  @override
  String get language => 'Мова';

  @override
  String get langSystem => 'Системна';

  @override
  String get quickAccess => 'Швидкий доступ';

  @override
  String get quickAccessBody =>
      'Плитка та віджет запускають запис без застосунку.';

  @override
  String get addTileBtn => 'Додати плитку';

  @override
  String get tileAdded => 'Плитку додано';

  @override
  String get tileUnavailable => 'Потрібен Android 13+';

  @override
  String get aboutLine => 'DotRec працює офлайн.';

  @override
  String get overlayNeedPermission =>
      'Потрібен дозвіл «Поверх інших застосунків».';

  @override
  String get openPermission => 'Відкрити дозвіл';

  @override
  String get errorLabel => 'Помилка';

  @override
  String get onboardingTitle => 'Запис екрана без зайвого';

  @override
  String get ob1 => 'Працює без інтернету';

  @override
  String get ob2 => 'Без реклами й водяних знаків';

  @override
  String get ob3 => 'Файли в Movies/DotRec';

  @override
  String get guidesTitle => 'Гайди та дозволи';

  @override
  String get guides => 'Гайди';

  @override
  String get openSettings => 'Відкрити налаштування';

  @override
  String get guideCaptureTitle => 'Доступ до екрана';

  @override
  String get guideCaptureBody =>
      'Під час старту Android покаже системний діалог доступу до екрана. На Android 14+ згода запитується перед кожним записом — це обмеження системи.';

  @override
  String get guideMicTitle => 'Мікрофон';

  @override
  String get guideMicBody =>
      '1. Увімкніть перемикач «Мікрофон». 2. Дозвольте доступ у системному діалозі. 3. Якщо відмовили — відкрийте налаштування застосунку та ввімкніть мікрофон вручну.';

  @override
  String get guideNotifTitle => 'Сповіщення';

  @override
  String get guideNotifBody =>
      'Сповіщення з таймером і кнопками паузи/стопу з\'явиться під час першого запису. Якщо його немає — дозвольте сповіщення в налаштуваннях застосунку.';

  @override
  String get guideOverlayTitle => 'Плаваюча плашка';

  @override
  String get guideOverlayBody =>
      'Вимкнена за замовчуванням. 1. Увімкніть її в налаштуваннях. 2. Дозвольте «Поверх інших застосунків» на системному екрані. Плашка не має потрапляти в запис.';

  @override
  String get guideBatteryTitle => 'Батарея і фон';

  @override
  String get guideBatteryBody =>
      'Деякі прошивки (Xiaomi, Samsung) вбивають фоновий запис заради економії батареї. Відкрийте налаштування батареї, знайдіть DotRec і дозвольте фонову роботу.';

  @override
  String get guideTileTitle => 'Плитка';

  @override
  String get guideTileBody =>
      '1. Відкрийте шторку та натисніть «Змінити». 2. Перетягніть плитку «Запис» в активну зону. На Android 13+ натисніть кнопку нижче — система сама запропонує додати плитку.';

  @override
  String get linkTitle => 'Передача на ПК';

  @override
  String get linkMethod => 'Спосіб';

  @override
  String get linkWifiPin => 'Код пари для Wi‑Fi';

  @override
  String get linkPinHint => 'Введіть на ПК. Код діє 2 хвилини';

  @override
  String get linkStreamQuality => 'Якість потоку';

  @override
  String get linkAudioToPc => 'Звук на ПК';

  @override
  String get linkBlankScreen => 'Гасити екран телефона';

  @override
  String get linkParallelRecord => 'Записувати на телефон паралельно';

  @override
  String get linkStartStream => 'Почати трансляцію';

  @override
  String get linkStopStream => 'Зупинити трансляцію';

  @override
  String get linkWaiting => 'Очікування ПК...';

  @override
  String get linkConnected => 'Підключено';
}
