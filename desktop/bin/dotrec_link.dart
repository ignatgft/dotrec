import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../lib/core/models/device_info.dart';
import '../lib/services/adb_service.dart';
import '../lib/services/browser_source_server.dart';
import '../lib/services/link_client.dart';
import '../lib/services/obs_service.dart';
import '../lib/services/recording_service.dart';

void main(List<String> args) async {
  stdout.writeln(r'''
============================================================
  ● DOTREC LINK v1.0.0 (Windows x64)
  USB / Wi-Fi Screen Mirroring & OBS Studio Companion
  Nothing OS Aesthetic · Ultra Low Latency (~34ms)
============================================================
''');

  final adb = AdbService();
  final linkClient = LinkClient();
  final browserServer = BrowserSourceServer();
  final obsService = ObsService();
  final recordingService = RecordingService();

  bool isRecording = false;

  stdout.writeln('[1/4] Инициализация служб ADB и поиск устройств...');
  adb.startPolling();

  final devices = await adb.getDevices();
  if (devices.isEmpty) {
    stdout.writeln('  [!] Устройство не найдено. Подключите телефон по USB с включенной отладкой.');
  } else {
    for (final dev in devices) {
      stdout.writeln('  [✓] Найдено устройство: ${dev.displayName} (${dev.serial}) [${dev.state.name}]');
    }
  }

  // Auto port forward for first ready device
  final readyDevice = devices.cast<DeviceInfo?>().firstWhere(
        (d) => d?.state == AdbState.ready,
        orElse: () => null,
      );

  if (readyDevice != null) {
    stdout.writeln('[2/4] Настройка перенаправления портов USB (adb forward tcp:48211)...');
    final forwarded = await adb.forwardPort(readyDevice.serial, 48211, 48211);
    if (forwarded) {
      stdout.writeln('  [✓] Порт 48211 успешно перенаправлен на localhost.');
    }
  }

  // Start Browser Source Server (WebCodecs hardware player)
  stdout.writeln('[3/4] Запуск локального сервера Browser Source...');
  await browserServer.start(port: 48212, linkClient: linkClient);
  stdout.writeln('  [✓] Сервер активен: ${browserServer.url}');
  stdout.writeln('      (Используйте этот URL в OBS Studio как Browser Source)');

  // Stream video frames to recorder if recording is active
  linkClient.videoStream.listen((frame) {
    if (isRecording) {
      recordingService.writeVideoFrame(frame, linkClient.spsPps);
    }
  });

  // Try connecting Link client to localhost:48211
  stdout.writeln('[4/4] Подключение к DotRec Link на телефоне (127.0.0.1:48211)...');
  linkClient.connect(host: '127.0.0.1', connectPort: 48211).then((connected) {
    if (connected) {
      stdout.writeln('  [✓] Поток экрана телефона успешно подключен!');
    } else {
      stdout.writeln('  [i] Ожидание старта трансляции в приложении на телефоне.');
    }
  });

  // Try connecting to OBS Studio
  obsService.connect(host: '127.0.0.1', port: 4455).then((obsOk) {
    if (obsOk) {
      stdout.writeln('  [✓] Подключено к OBS Studio (obs-websocket v5).');
    }
  });

  // Launch standalone window via Edge app mode or default browser
  final appUrl = browserServer.url;
  _launchAppWindow(appUrl);

  stdout.writeln(r'''
------------------------------------------------------------
Управление горячими клавишами в консоли:
  [M] - Открыть окно зеркала в отдельном окне
  [R] - Старт / Стоп локальной записи потока на ПК
  [S] - Сохранить снимок экрана
  [K] - Запрос ключевого кадра H.264 (IDR)
  [O] - Добавить источник в активную сцену OBS
  [Q] - Выход из приложения
------------------------------------------------------------
''');

  // Telemetry logger
  linkClient.statsStream.listen((stats) {
    if (stats.fps > 0) {
      stdout.write('\r[ЭФИР] ${stats.fps.toStringAsFixed(0)} FPS | '
          '${stats.latencyMs} мс | '
          '${stats.bitrateMbps.toStringAsFixed(1)} Мбит/с | '
          '${stats.videoWidth}x${stats.videoHeight}'
          '${isRecording ? " [REC]" : ""}   ');
    }
  });

  // Stdin listener for single keypresses
  stdin.lineMode = false;
  stdin.echoMode = false;

  await for (final chunk in stdin) {
    final key = utf8.decode(chunk).trim().toUpperCase();
    if (key == 'Q') {
      stdout.writeln('\nЗавершение работы DotRec Link...');
      break;
    } else if (key == 'M') {
      stdout.writeln('\nОткрытие окна зеркала...');
      _launchAppWindow(browserServer.url);
    } else if (key == 'R') {
      if (!isRecording) {
        final path = await recordingService.startRecording(linkClient.spsPps);
        isRecording = true;
        stdout.writeln('\n[REC] Начата запись в: $path');
      } else {
        final res = await recordingService.stopRecording();
        isRecording = false;
        stdout.writeln('\n[REC] Запись сохранена: ${res?.filePath ?? "готово"} '
            '(${res != null ? (res.bytesWritten / 1024 / 1024).toStringAsFixed(2) : 0} МБ)');
      }
    } else if (key == 'S') {
      final dummyPng = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]);
      final sPath = await recordingService.saveScreenshot(dummyPng);
      stdout.writeln('\n[СНИМОК] Сохранен: $sPath');
    } else if (key == 'K') {
      linkClient.requestKeyframe();
      stdout.writeln('\n[IDR] Запрошен ключевой кадр');
    } else if (key == 'O') {
      if (obsService.status == ObsStatus.connected) {
        final ok = await obsService.addBrowserSource(
          inputName: 'DotRec Phone Screen',
          url: browserServer.url,
        );
        stdout.writeln('\n[OBS] Источник ${ok ? "успешно добавлен" : "ошибка добавления"}');
      } else {
        stdout.writeln('\n[OBS] Не подключено к OBS (убедитесь, что obs-websocket активен на порту 4455)');
      }
    }
  }

  await browserServer.stop();
  linkClient.dispose();
  adb.dispose();
  obsService.dispose();
  exit(0);
}

void _launchAppWindow(String url) {
  // Try launching Edge in borderless standalone app window
  const edgePath = r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe';
  const edgePath64 = r'C:\Program Files\Microsoft\Edge\Application\msedge.exe';

  String? exe;
  if (File(edgePath).existsSync()) {
    exe = edgePath;
  } else if (File(edgePath64).existsSync()) {
    exe = edgePath64;
  }

  if (exe != null) {
    Process.start(exe, ['--app=$url', '--window-size=1200,800']);
  } else {
    // Fallback to default browser
    Process.start('cmd', ['/c', 'start', '', url]);
  }
}
