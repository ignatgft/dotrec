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
}
