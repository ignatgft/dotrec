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

  // 1. Compile DotRec-Link.exe native binary
  String dartSdk = Platform.executable;
  if (!dartSdk.endsWith('dart.exe')) {
    const defaultDart = r'D:\flutter\bin\cache\dart-sdk\bin\dart.exe';
    if (File(defaultDart).existsSync()) {
      dartSdk = defaultDart;
    }
  }
  final dotrecLinkDart = File('${projectDir.path}/bin/dotrec_link.dart');
  if (dotrecLinkDart.existsSync()) {
    final exeTarget = '${distDir.path}/DotRec-Link.exe';
    final res = Process.runSync(
      dartSdk,
      ['compile', 'exe', dotrecLinkDart.path, '-o', exeTarget],
    );
    if (res.exitCode == 0 && File(exeTarget).existsSync()) {
      stdout.writeln('  [✓] Compiled DotRec-Link.exe standalone binary');
    } else {
      stdout.writeln('  [!] Compile exe error: ${res.stderr}');
    }
  }

  // 2. Copy font assets
  final fontFile = File('${projectDir.path}/assets/fonts/Doto-Variable.ttf');
  if (fontFile.existsSync()) {
    fontFile.copySync('${assetsDir.path}/Doto-Variable.ttf');
    stdout.writeln('  [✓] Bundled Doto font asset');
  }

  // 3. Write README.txt
  final readmeFile = File('${distDir.path}/README.txt');
  readmeFile.writeAsStringSync('''
DotRec Link Desktop Client v1.0.0 (Windows x64)
==============================================
Официальный компаньон для USB/Wi-Fi зеркалирования экрана и интеграции с OBS Studio.

1. БЫСТРЫЙ СТАРТ:
   - Подключите телефон по USB и включите «Отладка по USB» в параметрах разработчика.
   - Запустите DotRec-Link.exe. Приложение автоматически выполнит `adb forward tcp:48211 tcp:48211`.
   - В приложении на телефоне перейдите в «Передача на ПК» и нажмите «Начать трансляцию».
   - Нажмите M для открытия окна зеркала.

2. ИНТЕГРАЦИЯ С OBS STUDIO:
   - Вариант А (Browser Source): вставьте URL http://127.0.0.1:48212/?token=... в Browser Source OBS.
     Задержка ~30-40 мс с аппаратным ускорением WebCodecs.
   - Вариант Б (obs-websocket): нажмите O в консоли или «Добавить в OBS» в UI. Источник создастся автоматически!
   - Вариант В (Window Capture): нажмите F10 в окне зеркала для безрамочного режима и захватите окно в OBS.

3. ГОРЯЧИЕ КЛАВИШИ:
   - M : Открыть окно зеркала
   - R : Старт/стоп локальной записи потока на ПК в Videos/DotRec
   - S : Сохранить мгновенный снимок экрана в Pictures/DotRec
   - K : Запрос ключевого кадра (IDR)
   - O : Добавить Browser Source в OBS Studio
   - Q : Выход из приложения

Лицензия: DotRec Source-Available License (см. LICENSE.txt).
''');
  stdout.writeln('  [✓] Created README.txt');

  // 4. Write LICENSE.txt
  final rootLicense = File('${projectDir.parent.path}/LICENSE');
  final licenseContent = rootLicense.existsSync()
      ? rootLicense.readAsStringSync()
      : 'DotRec Source-Available License: Free for personal use, third-party app store publishing prohibited.';
  File('${distDir.path}/LICENSE.txt').writeAsStringSync(licenseContent);
  stdout.writeln('  [✓] Bundled LICENSE.txt');

  // 5. Write default configuration config.default.json
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

  // 6. Generate package manifest with sha256 checksums
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

  // 7. Compile Inno Setup Windows Installer if available
  const isccPaths = [
    r'C:\Users\ignatgift\AppData\Local\Programs\Inno Setup 6\ISCC.exe',
    r'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    r'C:\Program Files\Inno Setup 6\ISCC.exe',
  ];
  String? isccExe;
  for (final p in isccPaths) {
    if (File(p).existsSync()) {
      isccExe = p;
      break;
    }
  }
  if (isccExe != null) {
    final issFile = File('${projectDir.path}/installer/DotRec-Link.iss');
    if (issFile.existsSync()) {
      final res = Process.runSync(isccExe, [issFile.path]);
      if (res.exitCode == 0) {
        stdout.writeln('  [✓] Compiled DotRec-Link-Setup-v1.0.0.exe Windows Installer');
      } else {
        stdout.writeln('  [!] ISCC warning: ${res.stderr}');
      }
    }
  }

  stopwatch.stop();
  stdout.writeln('Build package completed in ${stopwatch.elapsedMilliseconds} ms.');
  stdout.writeln('Package directory: ${distDir.path}');
}
