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

  bool get isRunning => _server != null;
  int get port => _port;
  String get token => _token;
  String get url =>
      isRunning ? 'http://127.0.0.1:$_port/?token=$_token' : '';

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
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
      shared: false,
    );
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
    // Security check: loopback only
    if (request.connectionInfo?.remoteAddress.isLoopback != true) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }

    final reqToken = request.uri.queryParameters['token'];
    if (reqToken != _token) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.contentType = ContentType.text;
      request.response.write('Unauthorized DotRec Link token');
      await request.response.close();
      return;
    }

    final path = request.uri.path;
    if (path == '/ws') {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _wsClients.add(socket);

        // Send cached SPS/PPS config immediately upon connection
        if (_cachedSpsPps != null) {
          socket.add(_cachedSpsPps!);
        }

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

    if (path == '/' || path == '/index.html') {
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
  }

  String _buildPlayerHtml(String token) {
    return '''<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <title>DotRec Link OBS Source</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 100%; height: 100%;
      background: transparent;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    canvas {
      width: 100%; height: 100%;
      object-fit: contain;
    }
    #status {
      position: absolute;
      top: 10px; left: 10px;
      color: #fff;
      font-family: monospace;
      font-size: 11px;
      background: rgba(0,0,0,0.6);
      padding: 4px 8px;
      border-radius: 4px;
      display: none;
    }
  </style>
</head>
<body>
  <div id="status">Connecting...</div>
  <canvas id="canvas"></canvas>
  <script>
    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d');
    const statusEl = document.getElementById('status');
    const token = '$token';
    const wsUrl = `ws://\${location.host}/ws?token=\${token}`;

    const ws = new WebSocket(wsUrl);
    ws.binaryType = 'arraybuffer';

    let decoder = null;
    let isWebCodecsSupported = typeof VideoDecoder !== 'undefined';

    if (isWebCodecsSupported) {
      decoder = new VideoDecoder({
        output: (frame) => {
          if (canvas.width !== frame.displayWidth || canvas.height !== frame.displayHeight) {
            canvas.width = frame.displayWidth;
            canvas.height = frame.displayHeight;
          }
          ctx.drawImage(frame, 0, 0);
          frame.close();
        },
        error: (e) => {
          console.error('WebCodecs Error:', e);
        }
      });

      // Default H.264 AVC Baseline profile
      try {
        decoder.configure({
          codec: 'avc1.42001f',
          optimizeForLatency: true
        });
      } catch (e) {
        console.warn('Decoder config fallback:', e);
      }
    }

    ws.onopen = () => {
      statusEl.textContent = '● Live';
    };

    ws.onmessage = (event) => {
      if (!isWebCodecsSupported || !decoder) return;
      const data = new Uint8Array(event.data);
      try {
        const chunk = new EncodedVideoChunk({
          type: (data[4] & 0x1f) === 5 || (data[0] & 0x1f) === 5 ? 'key' : 'delta',
          timestamp: performance.now() * 1000,
          data: data
        });
        decoder.decode(chunk);
      } catch (err) {
        // Continue streaming next frames
      }
    };

    ws.onclose = () => {
      statusEl.textContent = 'Disconnected';
      statusEl.style.display = 'block';
    };
  </script>
</body>
</html>''';
  }
}
