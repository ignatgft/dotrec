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

  final distDir = Directory('${projectDir.path}/build/dist/DotRec-Link-v1.1.0-windows-x64');
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

  // 1.1 Compile DotRec-Link-App.exe using PyInstaller
  final rootDir = projectDir.parent;
  final specFile = File('${rootDir.path}/DotRec-Link-App.spec');
  if (specFile.existsSync()) {
    stdout.writeln('  [*] Compiling DotRec-Link-App.exe with PyInstaller...');
    final pyRes = Process.runSync('pyinstaller', [
      specFile.path,
      '--distpath', distDir.path,
      '--workpath', '${projectDir.path}/build/pyinstaller_work',
      '-y',
    ], workingDirectory: rootDir.path);
    if (pyRes.exitCode == 0 && File('${distDir.path}/DotRec-Link-App.exe').existsSync()) {
      stdout.writeln('  [✓] Compiled DotRec-Link-App.exe native WebView2 shell');
    } else {
      stdout.writeln('  [!] PyInstaller error: ${pyRes.stderr}');
    }
  }

  // 2. Copy all desktop assets (fonts, icons, tray)
  final srcAssets = Directory('${projectDir.path}/assets');
  if (srcAssets.existsSync()) {
    for (final entity in srcAssets.listSync(recursive: true)) {
      final rel = entity.path.substring(srcAssets.path.length + 1);
      final destPath = '${distDir.path}/assets/$rel';
      if (entity is Directory) {
        Directory(destPath).createSync(recursive: true);
      } else if (entity is File) {
        File(destPath).parent.createSync(recursive: true);
        entity.copySync(destPath);
      }
    }
    stdout.writeln('  [✓] Bundled desktop assets (fonts, 51 SVG icons, tray icons)');
  }

  // 3. Write README.txt
  final readmeFile = File('${distDir.path}/README.txt');
  readmeFile.writeAsStringSync('''
DotRec Link Desktop Client v1.1.0-beta (Windows x64)
===================================================
Официальный компаньон для USB/Wi-Fi зеркалирования экрана и интеграции с OBS Studio.

1. БЫСТРЫЙ СТАРТ:
   - Подключите телефон по USB и включите «Отладка по USB» в параметрах разработчика.
   - Запустите DotRec-Link-App.exe.
   - В приложении на телефоне перейдите в «Передача на ПК» и нажмите «Начать трансляцию».

2. ИНТЕГРАЦИЯ С OBS STUDIO:
   - Вариант А (Browser Source): вставьте URL http://127.0.0.1:48212/obs в Browser Source OBS.
     Задержка ~30-40 мс с аппаратным ускорением WebCodecs.
   - Вариант Б (obs-websocket): нажмите «Добавить в OBS» в UI. Источник создастся автоматически!
   - Вариант В (Window Capture): захватите окно зеркала в OBS.

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
    'version': '1.1.0-beta',
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
    'version': '1.1.0-beta',
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
        stdout.writeln('  [✓] Compiled DotRec-Link-Setup-v1.1.0-beta.exe Windows Installer');
      } else {
        stdout.writeln('  [!] ISCC warning: ${res.stderr}');
      }
    }
  }

  // 8. Create ZIP archive
  final zipTarget = '${projectDir.path}/build/dist/DotRec-Link-v1.1.0-beta-windows-x64.zip';
  final zipRes = Process.runSync('powershell', [
    '-NoProfile',
    '-Command',
    'Compress-Archive -Path "${distDir.path}\\*" -DestinationPath "$zipTarget" -Force',
  ]);
  if (zipRes.exitCode == 0 && File(zipTarget).existsSync()) {
    stdout.writeln('  [✓] Created DotRec-Link-v1.1.0-beta-windows-x64.zip portable archive');
  }

  stopwatch.stop();
  stdout.writeln('Build package completed in ${stopwatch.elapsedMilliseconds} ms.');
  stdout.writeln('Package directory: ${distDir.path}');
}
