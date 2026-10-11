import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Скрипт сборки и упаковки дистрибутива DotRec Link для Windows.
void main(List<String> args) {
  final stopwatch = Stopwatch()..start();
  stdout.writeln('=== DotRec Link Desktop Packager (Windows x64) ===');

  final projectDir = Directory.current.path.endsWith('desktop')
      ? Directory.current
      : Directory('${Directory.current.path}/desktop');

  final distDir = Directory('${projectDir.path}/build/dist/DotRec-Link-v1.0.0-windows-x64');
  if (distDir.existsSync()) {
    distDir.deleteSync(recursive: true);
  }
  distDir.createSync(recursive: true);

  final assetsDir = Directory('${distDir.path}/assets/fonts');
  assetsDir.createSync(recursive: true);

  // 1. Copy font assets
  final fontFile = File('${projectDir.path}/assets/fonts/Doto-Variable.ttf');
  if (fontFile.existsSync()) {
    fontFile.copySync('${assetsDir.path}/Doto-Variable.ttf');
    stdout.writeln('  [✓] Bundled Doto font asset');
  }

  // 2. Write README.txt
  final readmeFile = File('${distDir.path}/README.txt');
  readmeFile.writeAsStringSync('''
DotRec Link Desktop Client v1.0.0 (Windows x64)
==============================================
Официальный компаньон для USB/Wi-Fi зеркалирования экрана и интеграции с OBS Studio.

1. БЫСТРЫЙ СТАРТ:
   - Подключите телефон по USB и включите «Отладка по USB» в параметрах разработчика.
   - Запустите DotRec Link. Приложение автоматически выполнит `adb forward tcp:48211 tcp:48211`.
   - В приложении на телефоне перейдите в «Передача на ПК» и нажмите «Начать трансляцию».
   - Нажмите Ctrl + Shift + M на ПК для открытия окна зеркала.

2. ИНТЕГРАЦИЯ С OBS STUDIO:
   - Вариант А (Browser Source): перейдите во вкладку «OBS» в DotRec Link, скопируйте URL браузерного источника и вставьте в OBS. Задержка ~30-40 мс с аппаратным ускорением WebCodecs.
   - Вариант Б (obs-websocket): введите порт (по умолчанию 4455) и нажмите «Добавить в OBS в 1 клик». Источник создастся автоматически!
   - Вариант В (Window Capture): нажмите F10 в окне зеркала для безрамочного режима и захватите окно в OBS.

3. ГОРЯЧИЕ КЛАВИШИ:
   - Ctrl + Shift + M : Открыть окно зеркала
   - Ctrl + Shift + R : Старт/стоп локальной записи потока на ПК
   - Ctrl + Shift + S : Сохранить мгновенный снимок экрана
   - Ctrl + K         : Запрос ключевого кадра (IDR)
   - F10              : Переключение безрамочного режима
   - Esc              : Закрыть окно зеркала
   - Ctrl + ,         : Настройки приложения

Лицензия: DotRec Source-Available License (см. LICENSE.txt).
''');
  stdout.writeln('  [✓] Created README.txt');

  // 3. Write LICENSE.txt
  final rootLicense = File('${projectDir.parent.path}/LICENSE');
  final licenseContent = rootLicense.existsSync()
      ? rootLicense.readAsStringSync()
      : 'DotRec Source-Available License: Free for personal use, third-party app store publishing prohibited.';
  File('${distDir.path}/LICENSE.txt').writeAsStringSync(licenseContent);
  stdout.writeln('  [✓] Bundled LICENSE.txt');

  // 4. Write default configuration config.default.json
  final configFile = File('${distDir.path}/config.default.json');
  final configData = {
    'version': '1.0.0',
    'themeMode': 'dark',
    'minimizeToTray': true,
    'launchOnStartup': false,
    'trayNotifications': true,
    'autoReconnect': true,
    'lowLatencyBuffer': true,
    'hardwareAcceleration': true,
    'recordingsPath': 'Videos/DotRec',
    'screenshotsPath': 'Pictures/DotRec',
    'linkServerPort': 48211,
    'browserSourcePort': 48212,
    'obsWebSocketPort': 4455,
  };
  configFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(configData));
  stdout.writeln('  [✓] Created config.default.json');

  // 5. Generate package manifest with sha256 checksums
  final manifestFiles = <Map<String, dynamic>>[];
  for (final file in distDir.listSync(recursive: true).whereType<File>()) {
    final bytes = file.readAsBytesSync();
    final hash = sha256.convert(bytes).toString();
    final relativePath = file.path.substring(distDir.path.length + 1).replaceAll(r'\', '/');
    manifestFiles.add({
      'path': relativePath,
      'size': bytes.length,
      'sha256': hash,
    });
  }

  final manifest = {
    'package': 'DotRec-Link-Desktop',
    'version': '1.0.0+1',
    'target': 'windows-x64',
    'builtAt': DateTime.now().toUtc().toIso8601String(),
    'files': manifestFiles,
  };

  File('${distDir.path}/manifest.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
  stdout.writeln('  [✓] Generated manifest.json with ${manifestFiles.length} file checksums');

  stopwatch.stop();
  stdout.writeln('Build package completed in ${stopwatch.elapsedMilliseconds} ms.');
  stdout.writeln('Package directory: ${distDir.path}');
}
