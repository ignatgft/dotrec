import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'link_client.dart';

class BrowserSourceServer {
  BrowserSourceServer();

  HttpServer? _server;
  String _token = '';
  int _port = 0;
  final List<WebSocket> _wsClients = [];
  StreamSubscription<LinkVideoFrame>? _videoSub;
  Uint8List? _cachedSpsPps;
  LinkClient? _linkClient;

  bool get isRunning => _server != null;
  int get port => _port;
  String get token => _token;
  String get url =>
      isRunning ? 'http://127.0.0.1:$_port/?token=$_token' : '';
  String get obsUrl =>
      isRunning ? 'http://127.0.0.1:$_port/obs' : '';

  static String _generateToken() {
    final r = Random.secure();
    final bytes = List<int>.generate(8, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<int> start({
    int port = 0,
    LinkClient? linkClient,
  }) async {
    await stop();

    _token = 'dotrec_${_generateToken()}';
    _linkClient = linkClient;
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

    // API для управления
    if (path == '/api/keyframe') {
      _linkClient?.requestKeyframe();
      request.response.statusCode = HttpStatus.ok;
      request.response.write('{"status":"ok"}');
      await request.response.close();
      return;
    }

    if (path == '/api/home') {
      const adbCandidates = [
        r'D:\andoidsdk\platform-tools\adb.exe',
        r'C:\Users\ignatgift\AppData\Local\Android\Sdk\platform-tools\adb.exe',
        'adb',
      ];
      for (final a in adbCandidates) {
        if (File(a).existsSync() || a == 'adb') {
          try {
            Process.runSync(a, ['shell', 'input', 'keyevent', 'KEYCODE_HOME']);
          } catch (_) {}
          break;
        }
      }
      request.response.statusCode = HttpStatus.ok;
      request.response.write('{"status":"ok"}');
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
    final isObs = path == '/obs' ||
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
      // Режим интерактивного студийного плеера для ПК
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.html;
      request.response.write(_buildPlayerHtml(_token));
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
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

  /// ИНТЕРАКТИВНЫЙ СТУДИЙНЫЙ ПЛЕЕР ДЛЯ ПК (Nothing OS Monochrome Aesthetic)
  String _buildPlayerHtml(String token) {
    return '''<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <title>DotRec Link — Desktop Studio</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 100%; height: 100%;
      background: #080808;
      background-image: radial-gradient(#1A1A1A 1px, transparent 1px);
      background-size: 24px 24px;
      color: #E6E6E6;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      user-select: none;
    }

    /* Верхняя панель Nothing OS */
    #header {
      height: 52px;
      background: rgba(18, 18, 18, 0.88);
      backdrop-filter: blur(12px);
      border-bottom: 1px solid rgba(255, 255, 255, 0.08);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 20px;
      z-index: 50;
      transition: opacity 0.3s ease, transform 0.3s ease;
    }
    #header.hidden {
      opacity: 0;
      transform: translateY(-100%);
      pointer-events: none;
    }

    .brand {
      display: flex;
      align-items: center;
      gap: 10px;
      font-weight: 800;
      letter-spacing: 2px;
      font-size: 14px;
    }
    .brand-dot {
      width: 9px; height: 9px;
      background: #D71921;
      border-radius: 50%;
      box-shadow: 0 0 10px rgba(215, 25, 33, 0.6);
      animation: pulse 2s infinite ease-in-out;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.5; transform: scale(0.85); }
    }

    .telemetry-bar {
      display: flex;
      align-items: center;
      gap: 10px;
      background: rgba(25, 25, 25, 0.7);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 20px;
      padding: 4px 14px;
      font-family: monospace;
      font-size: 12px;
    }
    .status-indicator {
      width: 7px; height: 7px;
      border-radius: 50%;
      background: #00E676;
      box-shadow: 0 0 8px #00E676;
    }

    .top-actions {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .btn {
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid rgba(255, 255, 255, 0.12);
      color: #EDEDED;
      padding: 6px 14px;
      border-radius: 8px;
      font-size: 12px;
      font-weight: 600;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.15s ease;
    }
    .btn:hover {
      background: rgba(255, 255, 255, 0.14);
      border-color: rgba(255, 255, 255, 0.3);
      transform: translateY(-1px);
    }
    .btn.active {
      background: #D71921;
      border-color: #D71921;
      color: #FFF;
      box-shadow: 0 0 12px rgba(215, 25, 33, 0.5);
    }
    .btn-obs {
      background: #FFF;
      color: #000;
      border-color: #FFF;
    }
    .btn-obs:hover {
      background: #E0E0E0;
    }

    /* Основная рабочая область */
    #viewport {
      flex: 1;
      position: relative;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
      padding: 12px;
    }
    canvas {
      max-width: 100%;
      max-height: 100%;
      object-fit: contain;
      box-shadow: 0 8px 36px rgba(0, 0, 0, 0.95);
      border-radius: 4px;
      transition: transform 0.2s ease;
    }
    canvas.fill-mode {
      width: 100%; height: 100%;
      object-fit: fill;
    }

    /* Оверлей ожидания */
    #waiting-overlay {
      position: absolute;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      color: #888;
      font-size: 14px;
      letter-spacing: 0.5px;
    }
    .spinner {
      width: 38px; height: 38px;
      border: 3px solid #222;
      border-top-color: #D71921;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }

    /* Плавающий нижний док Nothing OS */
    #dock {
      position: absolute;
      bottom: 24px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(18, 18, 18, 0.9);
      backdrop-filter: blur(16px);
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: 30px;
      padding: 6px 12px;
      display: flex;
      align-items: center;
      gap: 8px;
      z-index: 50;
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.6);
      transition: opacity 0.3s ease, transform 0.3s ease;
    }
    #dock.hidden {
      opacity: 0;
      transform: translate(-50%, 40px);
      pointer-events: none;
    }
    .dock-btn {
      background: transparent;
      border: none;
      color: #BBB;
      padding: 8px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 500;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: all 0.15s ease;
    }
    .dock-btn:hover {
      background: rgba(255, 255, 255, 0.08);
      color: #FFF;
    }
    .dock-btn.active {
      background: #D71921;
      color: #FFF;
    }

    /* Всплывающее уведомление (Toast) */
    #toast {
      position: absolute;
      top: 68px;
      left: 50%;
      transform: translateX(-50%);
      background: #1E1E1E;
      border: 1px solid #333;
      color: #FFF;
      padding: 10px 20px;
      border-radius: 20px;
      font-size: 13px;
      opacity: 0;
      pointer-events: none;
      transition: opacity 0.25s ease;
      z-index: 100;
      box-shadow: 0 4px 16px rgba(0,0,0,0.8);
    }
    #toast.show {
      opacity: 1;
    }
  </style>
</head>
<body>
  <div id="header">
    <div class="brand">
      <div class="brand-dot"></div>
      <span>DOTREC LINK</span>
    </div>

    <div class="telemetry-bar">
      <div class="status-indicator"></div>
      <span id="fps-label">60 FPS</span>
      <span style="color:#555">|</span>
      <span id="res-label">1080×2400</span>
      <span style="color:#555">|</span>
      <span id="latency-label">~34 мс</span>
    </div>

    <div class="top-actions">
      <button class="btn btn-obs" onclick="copyObsUrl()">
        📺 Скопировать для OBS
      </button>
      <button class="btn" onclick="toggleHeaderOnly()" title="Скрыть/показать панели (H)">
        👁️ Скрыть [H]
      </button>
      <button class="btn" onclick="toggleFullscreen()" title="Полный экран (F11)">
        ⛶ Экран [F]
      </button>
    </div>
  </div>

  <div id="viewport">
    <div id="waiting-overlay">
      <div class="spinner"></div>
      <span>Подключение к аппаратному потоку телефона...</span>
    </div>
    <canvas id="canvas"></canvas>
  </div>

  <div id="dock">
    <button class="dock-btn" id="btn-rec" onclick="toggleLocalRecord()">
      🔴 Запись
    </button>
    <button class="dock-btn" onclick="saveSnapshot()">
      📸 Снимок
    </button>
    <button class="dock-btn" onclick="requestKeyframe()">
      ⚡ Ключевой кадр
    </button>
    <button class="dock-btn" onclick="sendHomeKey()">
      📱 Домой
    </button>
    <button class="dock-btn" onclick="rotateCanvas()">
      🔄 Поворот
    </button>
    <button class="dock-btn" onclick="toggleAspect()">
      📐 Масштаб
    </button>
  </div>

  <div id="toast"></div>

  <script>
    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d');
    const header = document.getElementById('header');
    const dock = document.getElementById('dock');
    const waitingOverlay = document.getElementById('waiting-overlay');
    const fpsLabel = document.getElementById('fps-label');
    const resLabel = document.getElementById('res-label');
    const latencyLabel = document.getElementById('latency-label');
    const toast = document.getElementById('toast');
    const btnRec = document.getElementById('btn-rec');

    const token = '$token';
    const wsUrl = `ws://\${location.host}/ws?token=\${token}`;
    const obsCleanUrl = `http://\${location.host}/obs`;

    let rotationDeg = 0;
    let isFillMode = false;
    let uiVisible = true;
    let mediaRecorder = null;
    let recordedChunks = [];
    let isRecordingLocal = false;

    // Авто-скрытие панелей при бездействии мыши
    let idleTimer = null;
    function resetIdleTimer() {
      if (!uiVisible) return;
      header.classList.remove('hidden');
      dock.classList.remove('hidden');
      clearTimeout(idleTimer);
      idleTimer = setTimeout(() => {
        if (uiVisible && !isRecordingLocal) {
          header.classList.add('hidden');
          dock.classList.add('hidden');
        }
      }, 3500);
    }
    window.addEventListener('mousemove', resetIdleTimer);
    window.addEventListener('keydown', resetIdleTimer);

    function showToast(msg) {
      toast.textContent = msg;
      toast.classList.add('show');
      setTimeout(() => toast.classList.remove('show'), 2500);
    }

    function copyObsUrl() {
      navigator.clipboard.writeText(obsCleanUrl).then(() => {
        showToast('✓ Ссылка для OBS скопирована! Вставьте в Browser Source (1080×2400)');
      }).catch(() => {
        prompt('Скопируйте ссылку для OBS Browser Source:', obsCleanUrl);
      });
    }

    function toggleHeaderOnly() {
      uiVisible = !uiVisible;
      if (!uiVisible) {
        header.classList.add('hidden');
        dock.classList.add('hidden');
        showToast('Панели скрыты. Нажмите H чтобы вернуть.');
      } else {
        header.classList.remove('hidden');
        dock.classList.remove('hidden');
      }
    }

    function toggleFullscreen() {
      if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen();
      } else {
        document.exitFullscreen();
      }
    }

    function rotateCanvas() {
      rotationDeg = (rotationDeg + 90) % 360;
      canvas.style.transform = `rotate(\${rotationDeg}deg)`;
      showToast(`Поворот: \${rotationDeg}°`);
    }

    function toggleAspect() {
      isFillMode = !isFillMode;
      canvas.className = isFillMode ? 'fill-mode' : '';
      showToast(isFillMode ? 'Режим: Заполнение' : 'Режим: По размеру');
    }

    function requestKeyframe() {
      fetch('/api/keyframe').then(() => {
        showToast('⚡ Запрошен ключевой IDR кадр');
      });
    }

    function sendHomeKey() {
      fetch('/api/home').then(() => {
        showToast('📱 Телефон: переход на домашний экран');
      });
    }

    function saveSnapshot() {
      if (!canvas.width || !canvas.height) return;
      const link = document.createElement('a');
      link.download = `DotRec_\${Date.now()}.png`;
      link.href = canvas.toDataURL('image/png');
      link.click();
      showToast('📸 Снимок экрана сохранен!');
    }

    function toggleLocalRecord() {
      if (!isRecordingLocal) {
        try {
          const stream = canvas.captureStream(60);
          mediaRecorder = new MediaRecorder(stream, { mimeType: 'video/webm;codecs=vp9' });
        } catch (_) {
          const stream = canvas.captureStream(60);
          mediaRecorder = new MediaRecorder(stream);
        }
        recordedChunks = [];
        mediaRecorder.ondataavailable = (e) => {
          if (e.data.size > 0) recordedChunks.push(e.data);
        };
        mediaRecorder.onstop = () => {
          const blob = new Blob(recordedChunks, { type: 'video/webm' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = `DotRec_Stream_\${Date.now()}.webm`;
          a.click();
          showToast('✓ Локальная видеозапись сохранена!');
        };
        mediaRecorder.start();
        isRecordingLocal = true;
        btnRec.classList.add('active');
        btnRec.textContent = '⏹ Стоп';
        showToast('🔴 Начата локальная запись потока в браузере');
      } else {
        mediaRecorder.stop();
        isRecordingLocal = false;
        btnRec.classList.remove('active');
        btnRec.textContent = '🔴 Запись';
      }
    }

    // Телеметрия FPS
    let frameCount = 0;
    let lastTime = performance.now();
    setInterval(() => {
      const now = performance.now();
      const fps = Math.round((frameCount * 1000) / (now - lastTime));
      if (fps === 0 && waitingOverlay.style.display === 'none') {
        fpsLabel.textContent = '60 Hz (Статично)';
      } else {
        fpsLabel.textContent = `\${fps} FPS`;
      }
      frameCount = 0;
      lastTime = now;
    }, 1000);

    // Подключение к WebSocket WebCodecs
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
            resLabel.textContent = `\${frame.displayWidth}×\${frame.displayHeight}`;
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

    document.addEventListener('keydown', (e) => {
      const key = e.key.toUpperCase();
      if (key === 'F' || key === 'F11') {
        e.preventDefault();
        toggleFullscreen();
      } else if (key === 'H') {
        toggleHeaderOnly();
      } else if (key === 'S') {
        saveSnapshot();
      } else if (key === 'R') {
        toggleLocalRecord();
      } else if (key === 'K') {
        requestKeyframe();
      } else if (key === 'O') {
        copyObsUrl();
      }
    });

    resetIdleTimer();
  </script>
</body>
</html>''';
  }
}
