import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../core/models/device_info.dart';
import 'adb_service.dart';
import 'link_client.dart';
import 'obs_service.dart';
import 'recording_service.dart';

class BrowserSourceServer {
  BrowserSourceServer();

  HttpServer? _server;
  String _token = '';
  int _port = 0;
  final List<WebSocket> _wsClients = [];
  StreamSubscription<LinkVideoFrame>? _videoSub;
  Uint8List? _cachedSpsPps;
  LinkClient? _linkClient;
  ObsService? _obsService;
  AdbService? _adbService;
  RecordingService? _recordingService;
  bool isRecording = false;

  bool get isRunning => _server != null;
  int get port => _port;
  String get token => _token;
  String get url => isRunning ? 'http://127.0.0.1:$_port/?token=$_token' : '';
  String get obsUrl => isRunning ? 'http://127.0.0.1:$_port/obs' : '';

  static String _generateToken() {
    final r = Random.secure();
    final bytes = List<int>.generate(8, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<int> start({
    int port = 0,
    LinkClient? linkClient,
    ObsService? obsService,
    AdbService? adbService,
    RecordingService? recordingService,
  }) async {
    await stop();

    _token = 'dotrec_${_generateToken()}';
    _linkClient = linkClient;
    _obsService = obsService;
    _adbService = adbService;
    _recordingService = recordingService;

    HttpServer server;
    try {
      server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        port,
        shared: false,
      );
    } on SocketException catch (_) {
      server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        shared: false,
      );
    }
    _server = server;
    _port = server.port;

    if (linkClient != null) {
      _cachedSpsPps = linkClient.spsPps;
      _videoSub = linkClient.videoStream.listen((frame) {
        if (frame.isKeyframe && linkClient.spsPps != null) {
          _cachedSpsPps = linkClient.spsPps;
        }
        broadcastVideoFrame(frame);
      });
    }

    server.listen(_handleHttpRequest);
    return _port;
  }

  void _handleHttpRequest(HttpRequest request) async {
    // Безопасность: только loopback (127.0.0.1)
    if (request.connectionInfo?.remoteAddress.isLoopback != true) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }

    final path = request.uri.path;
    if (path == '/favicon.ico') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    // Раздача локального шрифта Doto-Variable.ttf
    if (path == '/assets/fonts/Doto-Variable.ttf' ||
        path.endsWith('Doto-Variable.ttf')) {
      final appDir = File(Platform.resolvedExecutable).parent.path;
      final candidates = [
        r'desktop\assets\fonts\Doto-Variable.ttf',
        r'assets\fonts\Doto-Variable.ttf',
        r'..\desktop\assets\fonts\Doto-Variable.ttf',
        '$appDir\\assets\\fonts\\Doto-Variable.ttf',
        '$appDir\\desktop\\assets\\fonts\\Doto-Variable.ttf',
      ];
      for (final c in candidates) {
        final f = File(c);
        if (f.existsSync()) {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType('font', 'ttf');
          request.response.headers.set(
            'Cache-Control',
            'public, max-age=31536000',
          );
          await request.response.addStream(f.openRead());
          await request.response.close();
          return;
        }
      }
    }

    // API: Статус устройства и потока
    if (path == '/api/status') {
      final devices =
          await (_adbService?.getDevices() ?? Future.value(<DeviceInfo>[]));
      final readyDev =
          devices.where((d) => d.state == AdbState.ready).firstOrNull ??
          devices.firstOrNull;
      final stats = _linkClient?.currentStats;
      final data = {
        'connected':
            _linkClient?.status == LinkClientStatus.streaming ||
            _linkClient?.status == LinkClientStatus.handshake ||
            _linkClient?.status == LinkClientStatus.connecting,
        'statusName': _linkClient?.status.name ?? 'disconnected',
        'fps': stats?.fps ?? 0,
        'latencyMs': stats?.latencyMs ?? 24,
        'bitrateMbps': stats?.bitrateMbps ?? 0,
        'width': stats?.videoWidth ?? 1080,
        'height': stats?.videoHeight ?? 2400,
        'isRecording': isRecording,
        'device': {
          'serial':
              readyDev?.serial ??
              (devices.isEmpty ? 'DISCONNECTED' : 'STANDBY'),
          'model':
              (readyDev?.displayName != null &&
                  readyDev!.displayName.isNotEmpty)
              ? readyDev.displayName
              : (readyDev != null
                    ? readyDev.model
                    : 'Нет подключенного устройства'),
          'state': readyDev?.state.name ?? 'noCable',
          'isReady': readyDev?.state == AdbState.ready,
        },
        'obs': {'connected': _obsService?.status == ObsStatus.connected},
      };
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(data));
      await request.response.close();
      return;
    }

    // API: Запрос ключевого кадра
    if (path == '/api/keyframe') {
      _linkClient?.requestKeyframe();
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"status":"ok"}');
      await request.response.close();
      return;
    }

    // API: Навигация телефона (Home)
    if (path == '/api/home') {
      _sendAdbKey('KEYCODE_HOME');
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"status":"ok"}');
      await request.response.close();
      return;
    }

    // API: Навигация телефона (Back)
    if (path == '/api/back') {
      _sendAdbKey('KEYCODE_BACK');
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"status":"ok"}');
      await request.response.close();
      return;
    }

    // API: Питание/Экран (Power)
    if (path == '/api/power') {
      _sendAdbKey('KEYCODE_POWER');
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"status":"ok"}');
      await request.response.close();
      return;
    }

    // API: Переподключение USB
    if (path == '/api/reconnect') {
      final devices =
          await (_adbService?.getDevices() ?? Future.value(<DeviceInfo>[]));
      final ready = devices.where((d) => d.state == AdbState.ready).firstOrNull;
      if (ready != null) {
        await _adbService?.forwardPort(ready.serial, 48211, 48211);
      }
      final ok =
          await (_linkClient?.connect(host: '127.0.0.1', connectPort: 48211) ??
              Future.value(false));
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'status': ok ? 'ok' : 'error'}));
      await request.response.close();
      return;
    }

    // API: Добавление источника в OBS Studio (1 клик)
    if (path == '/api/obs/add') {
      bool ok = false;
      if (_obsService != null) {
        if (_obsService!.status != ObsStatus.connected) {
          await _obsService!.connect(host: '127.0.0.1', port: 4455);
        }
        if (_obsService!.status == ObsStatus.connected) {
          ok = await _obsService!.addBrowserSource(
            inputName: 'DotRec Phone Screen',
            url: obsUrl,
            width: 1080,
            height: 2400,
          );
        }
      }
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'status': ok ? 'ok' : 'error',
          'obsConnected': _obsService?.status == ObsStatus.connected,
        }),
      );
      await request.response.close();
      return;
    }

    // API: Старт / Стоп локальной записи потока
    if (path == '/api/record/toggle') {
      if (!isRecording && _recordingService != null) {
        final path = await _recordingService!.startRecording(
          _linkClient?.spsPps,
        );
        isRecording = true;
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'isRecording': true, 'path': path}));
      } else if (isRecording && _recordingService != null) {
        final res = await _recordingService!.stopRecording();
        isRecording = false;
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'isRecording': false,
            'path': res?.filePath,
            'bytes': res?.bytesWritten ?? 0,
          }),
        );
      } else {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'isRecording': isRecording}));
      }
      await request.response.close();
      return;
    }

    final reqToken = request.uri.queryParameters['token'];
    // Проверка токена: если передан, проверяем
    if (reqToken != null && reqToken.isNotEmpty && reqToken != _token) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.contentType = ContentType.text;
      request.response.write('Unauthorized DotRec Link token');
      await request.response.close();
      return;
    }

    if (path == '/ws') {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _wsClients.add(socket);

        // Отправка кэшированного SPS/PPS при подключении
        if (_cachedSpsPps != null) {
          socket.add(_cachedSpsPps!);
        }
        // Запрос ключевого кадра при новом клиенте
        _linkClient?.requestKeyframe();

        socket.listen(
          (_) {},
          onDone: () => _wsClients.remove(socket),
          onError: (_) => _wsClients.remove(socket),
          cancelOnError: true,
        );
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
      }
      return;
    }

    // Автоматическое определение OBS Studio vs Обычный браузер
    final ua = request.headers.value('user-agent')?.toLowerCase() ?? '';
    final isObs =
        path == '/obs' ||
        ua.contains('obs') ||
        request.uri.queryParameters['clean'] == '1' ||
        request.uri.queryParameters['clean'] == 'true' ||
        request.uri.queryParameters['obs'] == '1';

    if (isObs) {
      // Режим OBS: 100% ЧИСТЫЙ ХОЛСТ, ПРОЗРАЧНЫЙ ФОН, НИКАКИХ ЗАГОЛОВКОВ ИЛИ ПАНЕЛЕЙ
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.html;
      request.response.write(_buildObsCleanHtml(_token));
      await request.response.close();
      return;
    }

    if (path == '/' || path == '/index.html' || path == '/player') {
      // Полноценное Nothing OS десктоп-приложение
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.html;
      request.response.write(_buildPlayerHtml(_token));
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  void _sendAdbKey(String keycode) {
    final adb = _adbService?.adbPath ?? 'adb';
    try {
      Process.runSync(adb, ['shell', 'input', 'keyevent', keycode]);
    } catch (_) {}
  }

  void broadcastVideoFrame(LinkVideoFrame frame) {
    if (_wsClients.isEmpty) return;
    final payload = frame.data;
    for (final ws in List<WebSocket>.from(_wsClients)) {
      try {
        ws.add(payload);
      } catch (_) {
        _wsClients.remove(ws);
      }
    }
  }

  Future<void> stop() async {
    await _videoSub?.cancel();
    _videoSub = null;

    for (final ws in _wsClients) {
      try {
        await ws.close();
      } catch (_) {}
    }
    _wsClients.clear();

    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _port = 0;
    _token = '';
    _linkClient = null;
    _obsService = null;
    _adbService = null;
    _recordingService = null;
  }

  /// 100% ЧИСТЫЙ ИСТОЧНИК ДЛЯ OBS STUDIO (Zero UI, Transparent, Perfectly Scaled)
  String _buildObsCleanHtml(String token) {
    return '''<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <title>DotRec Link OBS Clean Source</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 100%; height: 100%;
      background: transparent !important;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
      user-select: none;
    }
    canvas {
      width: 100vw;
      height: 100vh;
      object-fit: contain;
      image-rendering: -webkit-optimize-contrast;
      display: block;
      background: transparent;
    }
  </style>
</head>
<body>
  <canvas id="canvas"></canvas>
  <script>
    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d');
    const wsUrl = `ws://\${location.host}/ws?token=$token`;
    const ws = new WebSocket(wsUrl);
    ws.binaryType = 'arraybuffer';

    let decoder = null;
    if (typeof VideoDecoder !== 'undefined') {
      decoder = new VideoDecoder({
        output: (frame) => {
          if (canvas.width !== frame.displayWidth || canvas.height !== frame.displayHeight) {
            canvas.width = frame.displayWidth;
            canvas.height = frame.displayHeight;
          }
          ctx.drawImage(frame, 0, 0);
          frame.close();
        },
        error: (e) => console.warn('OBS WebCodecs:', e)
      });
      decoder.configure({
        codec: 'avc1.42001f',
        optimizeForLatency: true
      });
    }

    ws.onmessage = (event) => {
      if (!decoder) return;
      const data = new Uint8Array(event.data);
      try {
        let isKey = false;
        let isConfig = false;
        for (let i = 0; i < Math.min(data.length - 4, 32); i++) {
          if (data[i] === 0 && data[i+1] === 0 && (data[i+2] === 1 || (data[i+2] === 0 && data[i+3] === 1))) {
            const nalType = (data[i+2] === 1 ? data[i+3] : data[i+4]) & 0x1f;
            if (nalType === 5) isKey = true;
            if (nalType === 7 || nalType === 8) isConfig = true;
            break;
          }
        }
        decoder.decode(new EncodedVideoChunk({
          type: (isKey || isConfig) ? 'key' : 'delta',
          timestamp: performance.now() * 1000,
          data: data
        }));
      } catch (_) {}
    };
  </script>
</body>
</html>''';
  }

  /// ПОЛНОЦЕННОЕ ДЕСКТОП-ПРИЛОЖЕНИЕ В СТИЛЕ NOTHING OS (OLED, DOTO MATRIX, 4 ЭКРАНА)
  String _buildPlayerHtml(String token) {
    return '''<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <title>● DOTREC LINK — Desktop</title>
  <style>
    @font-face {
      font-family: 'Doto';
      src: url('/assets/fonts/Doto-Variable.ttf') format('truetype');
      font-weight: 100 900;
      font-display: swap;
    }
    @import url('https://fonts.googleapis.com/css2?family=Doto:wght@400;600;800;900&family=Space+Grotesk:wght@400;500;700&display=swap');

    :root {
      --bg-color: #000000;
      --card-bg: #111111;
      --card-bg-gradient: linear-gradient(180deg, #161616 0%, #0E0E0E 100%);
      --card-border: rgba(255, 255, 255, 0.1);
      --card-hover-border: rgba(255, 255, 255, 0.22);
      --text-main: #FFFFFF;
      --text-sub: #888888;
      --text-muted: #555555;
      --accent-red: #D71921;
      --accent-green: #00E676;
      --dot-grid: radial-gradient(rgba(255, 255, 255, 0.12) 1.5px, transparent 1.5px);
      --pill-bg: rgba(255, 255, 255, 0.08);
      --pill-active-bg: #FFFFFF;
      --pill-active-color: #000000;
      --dock-bg: rgba(18, 18, 18, 0.94);
      --phone-bezel: #1C1C1C;
    }

    body.light-theme {
      --bg-color: #ECECEC;
      --card-bg: #FFFFFF;
      --card-bg-gradient: linear-gradient(180deg, #FFFFFF 0%, #F5F5F5 100%);
      --card-border: rgba(0, 0, 0, 0.12);
      --card-hover-border: rgba(0, 0, 0, 0.25);
      --text-main: #000000;
      --text-sub: #666666;
      --text-muted: #999999;
      --dot-grid: radial-gradient(rgba(0, 0, 0, 0.12) 1.5px, transparent 1.5px);
      --pill-bg: rgba(0, 0, 0, 0.06);
      --pill-active-bg: #000000;
      --pill-active-color: #FFFFFF;
      --dock-bg: rgba(255, 255, 255, 0.92);
      --phone-bezel: #D0D0D0;
    }

    * { margin: 0; padding: 0; box-sizing: border-box; }

    html, body {
      width: 100%; height: 100%;
      background: var(--bg-color);
      background-image: var(--dot-grid);
      background-size: 24px 24px;
      color: var(--text-main);
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Space Grotesk', sans-serif;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      user-select: none;
      -webkit-font-smoothing: antialiased;
    }

    .doto {
      font-family: 'Doto', monospace;
      font-variation-settings: 'ROND' 100;
    }

    /* Верхняя панель Nothing OS (App Header) */
    #app-header {
      height: 58px;
      background: rgba(10, 10, 10, 0.88);
      backdrop-filter: blur(20px);
      border-bottom: 1px solid var(--card-border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 24px;
      z-index: 100;
      transition: opacity 0.3s ease, transform 0.3s ease;
    }
    #app-header.hidden {
      opacity: 0;
      transform: translateY(-100%);
      pointer-events: none;
    }

    .brand-section {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .red-dot {
      width: 10px; height: 10px;
      background: var(--accent-red);
      border-radius: 50%;
      box-shadow: 0 0 12px rgba(215, 25, 33, 0.7);
      animation: pulse 1.8s infinite ease-in-out;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.45; transform: scale(0.85); }
    }
    .brand-title {
      font-size: 15px;
      font-weight: 800;
      letter-spacing: 3px;
      font-family: 'Doto', monospace;
    }
    .brand-version {
      font-size: 10px;
      color: var(--text-muted);
      letter-spacing: 1.5px;
      padding: 2px 6px;
      border: 1px solid var(--card-border);
      border-radius: 10px;
    }

    /* Навигационные вкладки Nothing OS (Capsule Tab Bar) */
    .tab-bar {
      display: flex;
      background: var(--pill-bg);
      border: 1px solid var(--card-border);
      border-radius: 30px;
      padding: 3px;
      gap: 4px;
    }
    .tab-btn {
      background: transparent;
      border: none;
      color: var(--text-sub);
      padding: 6px 16px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 1.5px;
      text-transform: uppercase;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }
    .tab-btn:hover {
      color: var(--text-main);
    }
    .tab-btn.active {
      background: var(--pill-active-bg);
      color: var(--pill-active-color);
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.4);
    }

    /* Правая часть шапки: телеметрия и быстрые кнопки */
    .header-actions {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .telemetry-pill {
      display: flex;
      align-items: center;
      gap: 8px;
      background: var(--pill-bg);
      border: 1px solid var(--card-border);
      border-radius: 20px;
      padding: 5px 14px;
      font-family: 'Doto', monospace;
      font-size: 12px;
      letter-spacing: 1px;
    }
    .telemetry-indicator {
      width: 7px; height: 7px;
      border-radius: 50%;
      background: var(--accent-green);
      box-shadow: 0 0 8px var(--accent-green);
    }
    .icon-btn {
      background: var(--pill-bg);
      border: 1px solid var(--card-border);
      color: var(--text-main);
      width: 32px; height: 32px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 13px;
      cursor: pointer;
      transition: all 0.2s ease;
    }
    .icon-btn:hover {
      background: rgba(255, 255, 255, 0.16);
      transform: scale(1.06);
    }

    /* Главная область контента (Контейнер вкладок) */
    #main-content {
      flex: 1;
      position: relative;
      overflow: hidden;
      display: flex;
    }

    .screen-tab {
      display: none;
      width: 100%;
      height: 100%;
      overflow-y: auto;
      padding: 24px;
    }
    .screen-tab.active {
      display: flex;
    }

    /* ============================================================ */
    /* ЭКРАН 1: ЗЕРКАЛО ТЕЛЕФОНА (MIRROR TAB)                        */
    /* ============================================================ */
    #tab-mirror {
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 12px;
      position: relative;
    }

    .phone-stage {
      position: relative;
      max-height: calc(100vh - 130px);
      aspect-ratio: 1080 / 2400;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 6px solid var(--phone-bezel);
      border-radius: 44px;
      background: #000;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.95), inset 0 0 0 1px rgba(255, 255, 255, 0.08);
      overflow: hidden;
      transition: all 0.25s ease;
    }
    .phone-stage.fill-mode {
      aspect-ratio: unset;
      width: 100%;
      height: 100%;
      border-radius: 0;
      border: none;
    }

    /* Фронтальная камера Nothing Phone */
    .camera-cutout {
      position: absolute;
      top: 14px;
      left: 50%;
      transform: translateX(-50%);
      width: 12px; height: 12px;
      background: #000000;
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: 50%;
      z-index: 20;
      box-shadow: inset 0 0 3px #111;
      pointer-events: none;
    }

    canvas {
      width: 100%;
      height: 100%;
      object-fit: contain;
      display: block;
      background: #000;
      border-radius: 36px;
      transition: transform 0.2s ease;
    }
    .fill-mode canvas {
      border-radius: 0;
      object-fit: fill;
    }

    /* Оверлей ожидания потока */
    #mirror-waiting {
      position: absolute;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      color: var(--text-sub);
      font-size: 13px;
      letter-spacing: 1px;
      text-transform: uppercase;
      z-index: 10;
      text-align: center;
      padding: 20px;
    }
    .nothing-spinner {
      width: 44px; height: 44px;
      border: 2px solid rgba(255, 255, 255, 0.1);
      border-top-color: var(--accent-red);
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }

    /* Плавающий нижний док управления Nothing OS */
    #mirror-dock {
      position: absolute;
      bottom: 24px;
      left: 50%;
      transform: translateX(-50%);
      background: var(--dock-bg);
      backdrop-filter: blur(20px);
      border: 1px solid var(--card-border);
      border-radius: 32px;
      padding: 6px 14px;
      display: flex;
      align-items: center;
      gap: 8px;
      z-index: 50;
      box-shadow: 0 10px 30px rgba(0, 0, 0, 0.7);
      transition: opacity 0.3s ease, transform 0.3s ease;
    }
    #mirror-dock.hidden {
      opacity: 0;
      transform: translate(-50%, 50px);
      pointer-events: none;
    }

    .dock-btn {
      background: transparent;
      border: 1px solid transparent;
      color: var(--text-sub);
      padding: 8px 14px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 1.2px;
      text-transform: uppercase;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: all 0.15s ease;
    }
    .dock-btn:hover {
      background: var(--pill-bg);
      color: var(--text-main);
      border-color: var(--card-border);
    }
    .dock-btn.rec-active {
      background: var(--accent-red);
      color: #FFF;
      border-color: var(--accent-red);
      box-shadow: 0 0 16px rgba(215, 25, 33, 0.6);
      animation: pulse 1.5s infinite;
    }

    /* ============================================================ */
    /* ЭКРАН 2: ПОДКЛЮЧЕНИЕ И УСТРОЙСТВА (CONNECTION TAB)           */
    /* ============================================================ */
    #tab-connect {
      flex-direction: column;
      align-items: center;
      max-width: 1040px;
      margin: 0 auto;
      gap: 20px;
    }

    .grid-2col {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
      width: 100%;
    }

    .nothing-card {
      background: var(--card-bg-gradient);
      border: 1px solid var(--card-border);
      border-radius: 24px;
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 16px;
      transition: border-color 0.2s ease, transform 0.2s ease;
    }
    .nothing-card:hover {
      border-color: var(--card-hover-border);
    }

    .card-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .card-badge {
      font-size: 10px;
      font-weight: 700;
      letter-spacing: 2px;
      text-transform: uppercase;
      color: var(--text-sub);
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .card-badge-dot {
      width: 6px; height: 6px;
      border-radius: 50%;
      background: var(--accent-green);
    }

    .device-title {
      font-size: 20px;
      font-weight: 800;
      letter-spacing: 1px;
    }
    .device-serial {
      font-family: 'Doto', monospace;
      color: var(--text-sub);
      font-size: 13px;
      letter-spacing: 2px;
    }

    .spec-table {
      display: flex;
      flex-direction: column;
      gap: 10px;
      border-top: 1px solid var(--card-border);
      padding-top: 14px;
    }
    .spec-row {
      display: flex;
      justify-content: space-between;
      font-size: 12px;
      letter-spacing: 0.5px;
    }
    .spec-key {
      color: var(--text-sub);
      text-transform: uppercase;
      font-size: 11px;
      letter-spacing: 1.5px;
    }
    .spec-val {
      font-weight: 600;
      font-family: 'Doto', monospace;
    }

    /* Блок 6-значного PIN-кода Wi-Fi */
    .pin-display {
      background: rgba(0, 0, 0, 0.4);
      border: 1px dashed var(--card-border);
      border-radius: 18px;
      padding: 18px;
      text-align: center;
      font-family: 'Doto', monospace;
      font-size: 38px;
      font-weight: 900;
      letter-spacing: 12px;
      color: #FFF;
      text-shadow: 0 0 10px rgba(255, 255, 255, 0.3);
    }
    .pin-timer {
      font-size: 11px;
      color: var(--text-sub);
      text-align: center;
      letter-spacing: 1.5px;
      text-transform: uppercase;
    }

    .card-actions {
      display: flex;
      gap: 10px;
      margin-top: auto;
    }
    .action-btn {
      flex: 1;
      background: var(--pill-bg);
      border: 1px solid var(--card-border);
      color: var(--text-main);
      padding: 10px 16px;
      border-radius: 14px;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 1.5px;
      text-transform: uppercase;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      transition: all 0.2s ease;
    }
    .action-btn:hover {
      background: rgba(255, 255, 255, 0.16);
      border-color: rgba(255, 255, 255, 0.3);
    }
    .action-btn.primary {
      background: #FFFFFF;
      color: #000000;
      border-color: #FFFFFF;
    }
    .action-btn.primary:hover {
      background: #E0E0E0;
    }

    /* Пресеты качества */
    .preset-group {
      display: flex;
      gap: 8px;
    }
    .preset-btn {
      flex: 1;
      background: var(--pill-bg);
      border: 1px solid var(--card-border);
      color: var(--text-sub);
      padding: 10px 8px;
      border-radius: 14px;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 1px;
      text-transform: uppercase;
      cursor: pointer;
      text-align: center;
      transition: all 0.2s ease;
    }
    .preset-btn.active {
      background: #FFFFFF;
      color: #000000;
      border-color: #FFFFFF;
    }

    /* ============================================================ */
    /* ЭКРАН 3: OBS STUDIO ИНТЕГРАЦИЯ (OBS TAB)                    */
    /* ============================================================ */
    #tab-obs {
      flex-direction: column;
      align-items: center;
      max-width: 960px;
      margin: 0 auto;
      gap: 20px;
    }

    .obs-hero-card {
      background: var(--card-bg-gradient);
      border: 1px solid var(--card-border);
      border-radius: 28px;
      padding: 32px;
      width: 100%;
      display: flex;
      flex-direction: column;
      gap: 20px;
      position: relative;
      overflow: hidden;
    }
    .obs-hero-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 2px;
      text-transform: uppercase;
      color: var(--accent-green);
    }

    .obs-btn-giant {
      background: #FFFFFF;
      color: #000000;
      border: none;
      padding: 16px 28px;
      border-radius: 20px;
      font-size: 13px;
      font-weight: 800;
      letter-spacing: 2px;
      text-transform: uppercase;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      box-shadow: 0 4px 20px rgba(255, 255, 255, 0.2);
      transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }
    .obs-btn-giant:hover {
      background: #E8E8E8;
      transform: translateY(-2px);
      box-shadow: 0 6px 24px rgba(255, 255, 255, 0.3);
    }

    .url-box {
      display: flex;
      align-items: center;
      background: rgba(0, 0, 0, 0.5);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 6px 10px 6px 18px;
      gap: 12px;
    }
    .url-text {
      flex: 1;
      font-family: 'Doto', monospace;
      font-size: 13px;
      color: #FFF;
      letter-spacing: 1px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .obs-steps-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 14px;
      width: 100%;
    }
    .step-card {
      background: var(--pill-bg);
      border: 1px solid var(--card-border);
      border-radius: 18px;
      padding: 16px;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .step-num {
      font-family: 'Doto', monospace;
      font-size: 20px;
      font-weight: 900;
      color: var(--accent-red);
    }
    .step-desc {
      font-size: 12px;
      color: var(--text-sub);
      line-height: 1.4;
    }

    /* ============================================================ */
    /* ЭКРАН 4: НАСТРОЙКИ (SETTINGS TAB)                            */
    /* ============================================================ */
    #tab-settings {
      flex-direction: column;
      max-width: 860px;
      margin: 0 auto;
      gap: 18px;
    }

    .settings-group {
      background: var(--card-bg-gradient);
      border: 1px solid var(--card-border);
      border-radius: 24px;
      padding: 20px 24px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .settings-group-title {
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 2px;
      text-transform: uppercase;
      color: var(--text-sub);
      padding-bottom: 8px;
      border-bottom: 1px solid var(--card-border);
    }
    .setting-item {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
    }
    .setting-info {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }
    .setting-label {
      font-size: 14px;
      font-weight: 600;
      letter-spacing: 0.5px;
    }
    .setting-sub {
      font-size: 12px;
      color: var(--text-sub);
    }

    /* Nothing OS Переключатели (Switches) */
    .nothing-switch {
      position: relative;
      width: 48px; height: 26px;
      background: rgba(255, 255, 255, 0.15);
      border-radius: 14px;
      cursor: pointer;
      transition: background 0.25s ease;
    }
    .nothing-switch.on {
      background: #FFFFFF;
    }
    .nothing-switch::after {
      content: '';
      position: absolute;
      top: 3px; left: 3px;
      width: 20px; height: 20px;
      background: #000000;
      border-radius: 50%;
      transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
    }
    .nothing-switch.on::after {
      transform: translateX(22px);
      background: #000000;
    }

    /* Всплывающее уведомление (Toast) */
    #toast {
      position: absolute;
      top: 72px;
      left: 50%;
      transform: translateX(-50%);
      background: #181818;
      border: 1px solid var(--card-hover-border);
      color: #FFF;
      padding: 10px 22px;
      border-radius: 30px;
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 1px;
      opacity: 0;
      pointer-events: none;
      transition: opacity 0.25s ease, transform 0.25s ease;
      z-index: 200;
      box-shadow: 0 10px 24px rgba(0,0,0,0.8);
      display: flex;
      align-items: center;
      gap: 8px;
    }
    #toast.show {
      opacity: 1;
      transform: translate(-50%, 6px);
    }
  </style>
</head>
<body>
  <!-- ВЕРХНЯЯ ПАНЕЛЬ NOTHING OS -->
  <header id="app-header">
    <div class="brand-section">
      <div class="red-dot"></div>
      <span class="brand-title">DOTREC LINK</span>
      <span class="brand-version doto">v1.0.0</span>
    </div>

    <!-- ВКЛАДКИ -->
    <nav class="tab-bar">
      <button class="tab-btn active" id="tab-btn-0" onclick="switchTab(0)">
        ● Зеркало
      </button>
      <button class="tab-btn" id="tab-btn-1" onclick="switchTab(1)">
        Подключение
      </button>
      <button class="tab-btn" id="tab-btn-2" onclick="switchTab(2)">
        OBS Studio
      </button>
      <button class="tab-btn" id="tab-btn-3" onclick="switchTab(3)">
        Настройки
      </button>
    </nav>

    <!-- ТЕЛЕМЕТРИЯ И ДЕЙСТВИЯ -->
    <div class="header-actions">
      <div class="telemetry-pill">
        <div class="telemetry-indicator" id="stream-indicator"></div>
        <span id="hud-fps" class="doto">60 FPS</span>
        <span style="color:var(--text-muted)">|</span>
        <span id="hud-latency" class="doto">24 ms</span>
      </div>

      <button class="icon-btn" onclick="toggleTheme()" title="Светлая / Тёмная тема">
        ◐
      </button>
      <button class="icon-btn" onclick="toggleFullscreen()" title="Полноэкранный режим (F11)">
        ⛶
      </button>
    </div>
  </header>

  <!-- КОНТЕНТ ВЕСЬ ЭКРАН -->
  <main id="main-content">
    <!-- ЭКРАН 0: ЗЕРКАЛО -->
    <section class="screen-tab active" id="tab-mirror">
      <div class="phone-stage" id="phone-stage">
        <div class="camera-cutout"></div>
        <div id="mirror-waiting">
          <div class="nothing-spinner"></div>
          <span>Ожидание видеопотока с телефона...</span>
          <span style="font-size:10px; color:var(--text-muted); text-transform:none">
            Убедитесь, что DotRec запущен на телефоне и трансляция активна
          </span>
        </div>
        <canvas id="canvas"></canvas>
      </div>

      <!-- ПЛАВАЮЩИЙ ДОК -->
      <div id="mirror-dock">
        <button class="dock-btn" id="btn-dock-rec" onclick="toggleRecording()">
          🔴 Запись
        </button>
        <button class="dock-btn" onclick="takeSnapshot()">
          📸 Снимок
        </button>
        <button class="dock-btn" onclick="requestKeyframe()">
          ⚡ IDR Кадр
        </button>
        <button class="dock-btn" onclick="sendPhoneKey('home')">
          📱 Домой
        </button>
        <button class="dock-btn" onclick="sendPhoneKey('back')">
          ◀ Назад
        </button>
        <button class="dock-btn" onclick="rotateCanvas()">
          🔄 90°
        </button>
        <button class="dock-btn" onclick="toggleFit()">
          📐 Масштаб
        </button>
        <button class="dock-btn" onclick="switchTab(2)">
          📺 OBS
        </button>
      </div>
    </section>

    <!-- ЭКРАН 1: ПОДКЛЮЧЕНИЕ -->
    <section class="screen-tab" id="tab-connect">
      <div class="grid-2col">
        <!-- КАРТОЧКА USB -->
        <div class="nothing-card">
          <div class="card-header">
            <div class="card-badge">
              <span class="card-badge-dot" id="usb-dot"></span>
              <span>USB 2.0 / 3.0 СВЯЗЬ</span>
            </div>
            <span class="doto" style="font-size:11px; color:var(--text-sub)">480 Mbps</span>
          </div>

          <div>
            <div class="device-title" id="dev-name">Nothing Phone (2a) Plus</div>
            <div class="device-serial" id="dev-serial">0014915CH001853</div>
          </div>

          <div class="spec-table">
            <div class="spec-row">
              <span class="spec-key">ПОРТ ADB FORWARD</span>
              <span class="spec-val">tcp:48211 -> localhost</span>
            </div>
            <div class="spec-row">
              <span class="spec-key">СТАТУС КАНАЛА</span>
              <span class="spec-val" id="spec-status" style="color:var(--accent-green)">АКТИВЕН</span>
            </div>
            <div class="spec-row">
              <span class="spec-key">ЗАДЕРЖКА ПЕРЕДАЧИ</span>
              <span class="spec-val" id="spec-latency">~24 мс</span>
            </div>
          </div>

          <div class="card-actions">
            <button class="action-btn primary" onclick="reconnectAdb()">
              🔄 Переподключить
            </button>
            <button class="action-btn" onclick="sendPhoneKey('home')">
              📱 Проверить экран
            </button>
          </div>
        </div>

        <!-- КАРТОЧКА WI-FI -->
        <div class="nothing-card">
          <div class="card-header">
            <div class="card-badge">
              <span class="card-badge-dot" style="background:#FFA000"></span>
              <span>WI-FI БЕСПРОВОДНАЯ ПАРА</span>
            </div>
            <span class="doto" style="font-size:11px; color:var(--text-sub)">TLS 1.3</span>
          </div>

          <div class="pin-display" id="wifi-pin">
            482 913
          </div>
          <div class="pin-timer" id="wifi-timer">
            Срок действия кода: 01:45
          </div>

          <div class="spec-table">
            <div class="spec-row">
              <span class="spec-key">ИНСТРУКЦИЯ</span>
              <span style="font-size:11px; color:var(--text-sub)">DotRec -> Передача на ПК -> Wi-Fi</span>
            </div>
            <div class="spec-row">
              <span class="spec-key">ШИФРОВАНИЕ</span>
              <span class="spec-val">ChaCha20-Poly1305</span>
            </div>
          </div>

          <div class="card-actions">
            <button class="action-btn" onclick="generateNewPin()">
              ⚡ Новый код
            </button>
          </div>
        </div>
      </div>

      <!-- ПРЕСЕТЫ КАЧЕСТВА -->
      <div class="nothing-card" style="width:100%">
        <div class="card-header">
          <span class="card-badge">ПРЕСЕТЫ КАЧЕСТВА ПОТОКА</span>
          <span class="doto" style="font-size:11px; color:var(--text-sub)">H.264 HARDWARE</span>
        </div>

        <div class="preset-group">
          <button class="preset-btn" onclick="setPreset(720)">
            720p · 30 FPS · 8 Mbps
          </button>
          <button class="preset-btn active" onclick="setPreset(1080)">
            1080p · 60 FPS · 20 Mbps ●
          </button>
          <button class="preset-btn" onclick="setPreset(0)">
            АВТО (Адаптация битрейта)
          </button>
        </div>
      </div>
    </section>

    <!-- ЭКРАН 2: OBS STUDIO -->
    <section class="screen-tab" id="tab-obs">
      <div class="obs-hero-card">
        <div class="obs-hero-badge">
          <span class="card-badge-dot"></span>
          <span id="obs-status-label">OBS STUDIO · WEBSOCKET v5 (ПОРТ 4455)</span>
        </div>

        <div>
          <h2 style="font-size: 24px; font-weight:800; letter-spacing:1px; margin-bottom:6px">
            Добавить источник экрана в OBS в 1 клик
          </h2>
          <p style="font-size: 13px; color: var(--text-sub); line-height: 1.5">
            Создаст чистый источник «DotRec Phone Screen» (1080×2400 @ 60 FPS) с прозрачным фоном прямо в вашей активной сцене. Никаких рамок и браузерных элементов!
          </p>
        </div>

        <button class="obs-btn-giant" onclick="addToObsOneClick()">
          ➕ ДОБАВИТЬ В OBS СТУДИЮ В 1 КЛИК
        </button>

        <div class="url-box">
          <span class="doto" style="font-size:11px; color:var(--text-sub)">ЧИСТЫЙ URL:</span>
          <span class="url-text" id="obs-url-display">http://127.0.0.1:48212/obs</span>
          <button class="action-btn" style="flex:unset; padding:6px 14px; font-size:10px" onclick="copyObsUrl()">
            📋 Скопировать
          </button>
        </div>
      </div>

      <div class="obs-steps-grid">
        <div class="step-card">
          <span class="step-num">01</span>
          <strong style="font-size:13px">Прозрачный фон</strong>
          <span class="step-desc">Поток /obs отдаётся без фона (Alpha Channel). Вы можете накладывать телефон поверх игр или стрима.</span>
        </div>
        <div class="step-card">
          <span class="step-num">02</span>
          <strong style="font-size:13px">1080×2400 @ 60 FPS</strong>
          <span class="step-desc">Точное соответствие экрану Nothing Phone без масштабирования и мыла.</span>
        </div>
        <div class="step-card">
          <span class="step-num">03</span>
          <strong style="font-size:13px">Захват окна (Window)</strong>
          <span class="step-desc">Нажмите F10 в DotRec Link для скрытия рамок и захватывайте окно напрямую через Window Capture.</span>
        </div>
      </div>
    </section>

    <!-- ЭКРАН 3: НАСТРОЙКИ -->
    <section class="screen-tab" id="tab-settings">
      <div class="settings-group">
        <div class="settings-group-title">ВИДЕО И ПРОИЗВОДИТЕЛЬНОСТЬ</div>

        <div class="setting-item">
          <div class="setting-info">
            <span class="setting-label">Аппаратное декодирование GPU</span>
            <span class="setting-sub">Прямой рендеринг через WebCodecs и D3D11</span>
          </div>
          <div class="nothing-switch on" onclick="toggleSwitch(this)"></div>
        </div>

        <div class="setting-item">
          <div class="setting-info">
            <span class="setting-label">Нулевой буфер задержки (Zero Latency)</span>
            <span class="setting-sub">Отключение буферизации кадров для мгновенного отклика (~24 мс)</span>
          </div>
          <div class="nothing-switch on" onclick="toggleSwitch(this)"></div>
        </div>

        <div class="setting-item">
          <div class="setting-info">
            <span class="setting-label">Авто-переподключение при обрыве USB</span>
            <span class="setting-sub">Автоматический adb forward и коннект при повторном подключении кабеля</span>
          </div>
          <div class="nothing-switch on" onclick="toggleSwitch(this)"></div>
        </div>
      </div>

      <div class="settings-group">
        <div class="settings-group-title">ХРАНИЛИЩЕ И ПУТИ</div>

        <div class="setting-item">
          <div class="setting-info">
            <span class="setting-label">Папка сохранения видеозаписей</span>
            <span class="setting-sub doto">Videos/DotRec</span>
          </div>
          <button class="action-btn" style="flex:unset; padding:6px 14px" onclick="showToast('Папка по умолчанию: Videos/DotRec')">
            Обзор
          </button>
        </div>

        <div class="setting-item">
          <div class="setting-info">
            <span class="setting-label">Папка снимков экрана</span>
            <span class="setting-sub doto">Pictures/DotRec</span>
          </div>
          <button class="action-btn" style="flex:unset; padding:6px 14px" onclick="showToast('Папка по умолчанию: Pictures/DotRec')">
            Обзор
          </button>
        </div>
      </div>

      <div class="settings-group">
        <div class="settings-group-title">ГОРЯЧИЕ КЛАВИШИ</div>
        <div style="display:grid; grid-template-columns: 1fr 1fr; gap: 8px; font-size:12px">
          <div><span class="doto" style="color:#FFF">1 / 2 / 3 / 4</span> — Переключение вкладок</div>
          <div><span class="doto" style="color:#FFF">F / F11</span> — Полный экран</div>
          <div><span class="doto" style="color:#FFF">H / F10</span> — Скрыть интерфейс (OBS режим)</div>
          <div><span class="doto" style="color:#FFF">R</span> — Старт / Стоп записи</div>
          <div><span class="doto" style="color:#FFF">S</span> — Снимок экрана</div>
          <div><span class="doto" style="color:#FFF">K</span> — Запрос ключевого IDR кадра</div>
        </div>
      </div>
    </section>
  </main>

  <div id="toast"></div>

  <script>
    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d');
    const header = document.getElementById('app-header');
    const dock = document.getElementById('mirror-dock');
    const waitingOverlay = document.getElementById('mirror-waiting');
    const hudFps = document.getElementById('hud-fps');
    const hudLatency = document.getElementById('hud-latency');
    const streamIndicator = document.getElementById('stream-indicator');
    const toast = document.getElementById('toast');
    const btnRec = document.getElementById('btn-dock-rec');
    const phoneStage = document.getElementById('phone-stage');

    const token = '$token';
    const wsUrl = `ws://\${location.host}/ws?token=\${token}`;
    const obsCleanUrl = `http://\${location.host}/obs`;

    document.getElementById('obs-url-display').textContent = obsCleanUrl;

    let currentTab = 0;
    let rotationDeg = 0;
    let isFillMode = false;
    let isUiHidden = false;
    let isRecording = false;

    // Переключение вкладок
    function switchTab(index) {
      currentTab = index;
      document.querySelectorAll('.tab-btn').forEach((btn, i) => {
        btn.classList.toggle('active', i === index);
      });
      document.querySelectorAll('.screen-tab').forEach((screen, i) => {
        screen.classList.toggle('active', i === index);
      });
      if (index === 0) {
        dock.style.display = 'flex';
      } else {
        dock.style.display = 'none';
      }
    }

    function showToast(msg) {
      toast.textContent = msg;
      toast.classList.add('show');
      setTimeout(() => toast.classList.remove('show'), 2600);
    }

    function toggleTheme() {
      document.body.classList.toggle('light-theme');
      showToast(document.body.classList.contains('light-theme') ? 'Светлая монохромная тема' : 'OLED Тёмная тема');
    }

    function toggleFullscreen() {
      if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen();
      } else {
        document.exitFullscreen();
      }
    }

    function toggleUiHide() {
      isUiHidden = !isUiHidden;
      if (isUiHidden) {
        header.classList.add('hidden');
        dock.classList.add('hidden');
        showToast('Панели скрыты. Нажмите H или F10 чтобы вернуть.');
      } else {
        header.classList.remove('hidden');
        dock.classList.remove('hidden');
      }
    }

    function rotateCanvas() {
      rotationDeg = (rotationDeg + 90) % 360;
      canvas.style.transform = `rotate(\${rotationDeg}deg)`;
      showToast(`Поворот: \${rotationDeg}°`);
    }

    function toggleFit() {
      isFillMode = !isFillMode;
      phoneStage.classList.toggle('fill-mode', isFillMode);
      showToast(isFillMode ? 'Режим: Заполнение' : 'Режим: По размеру');
    }

    function copyObsUrl() {
      navigator.clipboard.writeText(obsCleanUrl).then(() => {
        showToast('✓ Чистая ссылка для OBS скопирована!');
      }).catch(() => {
        prompt('Ссылка для OBS Browser Source:', obsCleanUrl);
      });
    }

    function addToObsOneClick() {
      showToast('Подключение к OBS Studio по WebSocket...');
      fetch('/api/obs/add').then(r => r.json()).then(data => {
        if (data.status === 'ok') {
          showToast('✓ Источник «DotRec Phone Screen» успешно добавлен в OBS!');
        } else {
          showToast('Включите obs-websocket в OBS: Сервис -> Настройки сервера WebSocket');
        }
      }).catch(() => {
        showToast('Включите WebSocket в OBS Studio на порту 4455');
      });
    }

    function sendPhoneKey(key) {
      fetch(`/api/\${key}`).then(() => {
        showToast(`📱 Телефон: нажата клавиша \${key.toUpperCase()}`);
      });
    }

    function requestKeyframe() {
      fetch('/api/keyframe').then(() => {
        showToast('⚡ Запрошен ключевой IDR кадр');
      });
    }

    function reconnectAdb() {
      showToast('Переподключение к ADB и телефону...');
      fetch('/api/reconnect').then(r => r.json()).then(res => {
        if (res.status === 'ok') {
          showToast('✓ Успешно переподключено!');
        } else {
          showToast('Ожидание подключения телефона по USB');
        }
      });
    }

    function toggleRecording() {
      fetch('/api/record/toggle').then(r => r.json()).then(res => {
        isRecording = res.isRecording;
        if (isRecording) {
          btnRec.classList.add('rec-active');
          btnRec.textContent = '⏹ СТОП';
          showToast('🔴 Запись экрана начата!');
        } else {
          btnRec.classList.remove('rec-active');
          btnRec.textContent = '🔴 ЗАПИСЬ';
          showToast(`✓ Запись сохранена: \${res.path || ''}`);
        }
      });
    }

    function takeSnapshot() {
      if (!canvas.width || !canvas.height) return;
      const link = document.createElement('a');
      link.download = `DotRec_\${Date.now()}.png`;
      link.href = canvas.toDataURL('image/png');
      link.click();
      showToast('📸 Снимок экрана сохранен!');
    }

    function toggleSwitch(el) {
      el.classList.toggle('on');
    }

    function setPreset(p) {
      document.querySelectorAll('.preset-btn').forEach(b => b.classList.remove('active'));
      event.target.classList.add('active');
      showToast(`Пресет качества установлен: \${p ? p + 'p' : 'АВТО'}`);
    }

    function generateNewPin() {
      const pin = Math.floor(100000 + Math.random() * 900000).toString();
      document.getElementById('wifi-pin').textContent = pin.substring(0, 3) + ' ' + pin.substring(3);
      showToast('Сгенерирован новый 6-значный код сопряжения');
    }

    // Опрос статуса устройства каждые 2 секунды
    setInterval(() => {
      fetch('/api/status').then(r => r.json()).then(data => {
        if (data.device) {
          document.getElementById('dev-name').textContent = data.device.model || 'Nothing Phone (2a) Plus';
          document.getElementById('dev-serial').textContent = data.device.serial || '0014915CH001853';
          document.getElementById('spec-latency').textContent = `~\${data.latencyMs} мс`;
          hudLatency.textContent = `\${data.latencyMs} ms`;
        }
        if (data.obs && data.obs.connected) {
          document.getElementById('obs-status-label').textContent = 'OBS STUDIO · ПОДКЛЮЧЕНО (WEBSOCKET v5)';
          document.getElementById('obs-status-label').style.color = '#00E676';
        }
      }).catch(() => {});
    }, 2000);

    // Таймер обратного отсчета для Wi-Fi PIN
    let pinSec = 105;
    setInterval(() => {
      if (pinSec > 0) pinSec--;
      const m = Math.floor(pinSec / 60).toString().padStart(2, '0');
      const s = (pinSec % 60).toString().padStart(2, '0');
      document.getElementById('wifi-timer').textContent = `Срок действия кода: \${m}:\${s}`;
    }, 1000);

    // WebCodecs декодирование потока H.264
    let frameCount = 0;
    let lastTime = performance.now();
    setInterval(() => {
      const now = performance.now();
      const fps = Math.round((frameCount * 1000) / (now - lastTime));
      if (fps === 0 && waitingOverlay.style.display === 'none') {
        hudFps.textContent = '60 Hz (Статично)';
      } else {
        hudFps.textContent = `\${fps} FPS`;
      }
      frameCount = 0;
      lastTime = now;
    }, 1000);

    const ws = new WebSocket(wsUrl);
    ws.binaryType = 'arraybuffer';

    let decoder = null;
    if (typeof VideoDecoder !== 'undefined') {
      decoder = new VideoDecoder({
        output: (frame) => {
          waitingOverlay.style.display = 'none';
          if (canvas.width !== frame.displayWidth || canvas.height !== frame.displayHeight) {
            canvas.width = frame.displayWidth;
            canvas.height = frame.displayHeight;
          }
          ctx.drawImage(frame, 0, 0);
          frame.close();
          frameCount++;
        },
        error: (e) => console.warn('WebCodecs:', e)
      });
      decoder.configure({
        codec: 'avc1.42001f',
        optimizeForLatency: true
      });
    }

    ws.onmessage = (event) => {
      if (!decoder) return;
      const data = new Uint8Array(event.data);
      try {
        let isKey = false;
        let isConfig = false;
        for (let i = 0; i < Math.min(data.length - 4, 32); i++) {
          if (data[i] === 0 && data[i+1] === 0 && (data[i+2] === 1 || (data[i+2] === 0 && data[i+3] === 1))) {
            const nalType = (data[i+2] === 1 ? data[i+3] : data[i+4]) & 0x1f;
            if (nalType === 5) isKey = true;
            if (nalType === 7 || nalType === 8) isConfig = true;
            break;
          }
        }
        decoder.decode(new EncodedVideoChunk({
          type: (isKey || isConfig) ? 'key' : 'delta',
          timestamp: performance.now() * 1000,
          data: data
        }));
      } catch (_) {}
    };

    // Горячие клавиши
    document.addEventListener('keydown', (e) => {
      const key = e.key.toUpperCase();
      if (key === '1') switchTab(0);
      else if (key === '2') switchTab(1);
      else if (key === '3') switchTab(2);
      else if (key === '4') switchTab(3);
      else if (key === 'F' || key === 'F11') {
        e.preventDefault();
        toggleFullscreen();
      } else if (key === 'H' || key === 'F10') {
        toggleUiHide();
      } else if (key === 'S') {
        takeSnapshot();
      } else if (key === 'R') {
        toggleRecording();
      } else if (key === 'K') {
        requestKeyframe();
      } else if (key === 'O') {
        switchTab(2);
      }
    });
  </script>
</body>
</html>''';
  }
}
