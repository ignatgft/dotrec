// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'DotRec';

  @override
  String get start => 'Начать запись';

  @override
  String get stop => 'Остановить';

  @override
  String get pause => 'Пауза';

  @override
  String get resume => 'Продолжить';

  @override
  String get saved => 'Запись сохранена';

  @override
  String get open => 'Открыть';

  @override
  String get share => 'Поделиться';

  @override
  String get delete => 'Удалить';

  @override
  String get err_space => 'Мало места. Освободите хотя бы 200 МБ';

  @override
  String get err_consent => 'Запись не началась. Доступ к экрану не выдан';

  @override
  String get err_mic =>
      'Нет доступа к микрофону. Откройте настройки приложения';

  @override
  String fps_cap(int n) {
    return 'Экран поддерживает до $n Гц';
  }

  @override
  String get audio_blocked => 'Часть приложений запретила захват звука';

  @override
  String get empty_lib_title => 'Здесь появятся ваши записи';

  @override
  String get ready => 'READY';

  @override
  String get paused => 'ПАУЗА';

  @override
  String get saving => 'СОХРАНЕНИЕ';

  @override
  String get settings => 'Настройки';

  @override
  String get library => 'Записи';

  @override
  String get presetFast => 'Быстро';

  @override
  String get presetBalanced => 'Баланс';

  @override
  String get presetQuality => 'Качество';

  @override
  String get presetCustom => 'Свой';

  @override
  String get begin => 'Начать';

  @override
  String get presetLabel => 'Пресет';

  @override
  String get resolutionLabel => 'Разрешение';

  @override
  String get micLabel => 'Микрофон';

  @override
  String get sysAudioLabel => 'Звук системы';

  @override
  String get videoLabel => 'Видео';

  @override
  String bitrateLabel(int n) {
    return 'Битрейт: $n Мбит/с';
  }

  @override
  String get codecLabel => 'Кодек';

  @override
  String get hevcMissing => 'В устройстве нет аппаратного HEVC';

  @override
  String get audioLabel => 'Звук';

  @override
  String get sysAudioV11 => 'Звук системы (v1.1)';

  @override
  String get recordingLabel => 'Запись';

  @override
  String get countdownLabel => 'Обратный отсчёт';

  @override
  String get noneLabel => 'Нет';

  @override
  String countdownSec(int n) {
    return '$n с';
  }

  @override
  String get appearanceLabel => 'Вид';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get language => 'Язык';

  @override
  String get langSystem => 'Системный';

  @override
  String get quickAccess => 'Быстрый доступ';

  @override
  String get quickAccessBody =>
      'Плитка и виджет запускают запись без открытия приложения.';

  @override
  String get addTileBtn => 'Добавить плитку';

  @override
  String get tileAdded => 'Плитка добавлена';

  @override
  String get tileUnavailable => 'Требуется Android 13+';

  @override
  String get aboutLine => 'DotRec работает офлайн.';

  @override
  String get overlayNeedPermission =>
      'Требуется разрешение «Поверх других окон».';

  @override
  String get openPermission => 'Открыть разрешение';

  @override
  String get errorLabel => 'Ошибка';

  @override
  String get onboardingTitle => 'Запись экрана без лишнего';

  @override
  String get ob1 => 'Работает без интернета';

  @override
  String get ob2 => 'Нет рекламы и водяных знаков';

  @override
  String get ob3 => 'Файлы хранятся в Movies/DotRec';

  @override
  String get guidesTitle => 'Гайды и разрешения';

  @override
  String get guides => 'Гайды';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get guideCaptureTitle => 'Доступ к экрану';

  @override
  String get guideCaptureBody =>
      'При старте записи Android покажет системный диалог доступа к экрану. На Android 14+ согласие запрашивается при каждой записи — это ограничение системы.';

  @override
  String get guideMicTitle => 'Микрофон';

  @override
  String get guideMicBody =>
      '1. Включите переключатель «Микрофон». 2. Разрешите доступ в системном диалоге. 3. Если отказали — откройте настройки приложения и включите микрофон вручную.';

  @override
  String get guideNotifTitle => 'Уведомления';

  @override
  String get guideNotifBody =>
      'Уведомление с таймером и кнопками «Пауза/Стоп» появляется при первой записи. Если его нет — разрешите уведомления в настройках приложения.';

  @override
  String get guideOverlayTitle => 'Плавающая плашка';

  @override
  String get guideOverlayBody =>
      'Плашка выключена по умолчанию. 1. Включите её в настройках. 2. Разрешите «Поверх других окон» на системном экране. Плашка не должна попадать в запись.';

  @override
  String get guideBatteryTitle => 'Батарея и фон';

  @override
  String get guideBatteryBody =>
      'Некоторые прошивки (Xiaomi, Samsung) убивают фоновую запись для экономии батареи. Откройте настройки батареи, найдите DotRec и разрешите работу в фоне.';

  @override
  String get guideTileTitle => 'Плитка в шторке';

  @override
  String get guideTileBody =>
      '1. Откройте шторку и нажмите «Изменить». 2. Перетащите плитку «Запись» в активную зону. На Android 13+ нажмите кнопку ниже — система сама предложит добавить плитку.';

  @override
  String get linkTitle => 'Передача на ПК';

  @override
  String get linkMethod => 'Способ';

  @override
  String get linkWifiPin => 'Код пары для Wi‑Fi';

  @override
  String get linkPinHint => 'Введите на ПК. Код действует 2 минуты';

  @override
  String get linkStreamQuality => 'Качество потока';

  @override
  String get linkAudioToPc => 'Звук на ПК';

  @override
  String get linkBlankScreen => 'Гасить экран телефона';

  @override
  String get linkParallelRecord => 'Писать на телефон параллельно';

  @override
  String get linkStartStream => 'Начать трансляцию';

  @override
  String get linkStopStream => 'Остановить трансляцию';

  @override
  String get linkWaiting => 'Ожидание ПК...';

  @override
  String get linkConnected => 'Подключён';
}
