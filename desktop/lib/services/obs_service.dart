import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

enum ObsStatus { disconnected, connecting, connected, error }

class ObsService {
  ObsService();

  WebSocket? _socket;
  ObsStatus _status = ObsStatus.disconnected;
  ObsStatus get status => _status;

  final _statusController = StreamController<ObsStatus>.broadcast();
  Stream<ObsStatus> get statusStream => _statusController.stream;

  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  int _requestIdCounter = 0;
  String _currentScene = '';
  String get currentScene => _currentScene;

  void _setStatus(ObsStatus s) {
    if (_status == s) return;
    _status = s;
    if (!_statusController.isClosed) {
      _statusController.add(s);
    }
  }

  Future<bool> connect({
    String host = '127.0.0.1',
    int port = 4455,
    String password = '',
    Duration timeout = const Duration(seconds: 4),
  }) async {
    disconnect();
    _setStatus(ObsStatus.connecting);

    try {
      final ws = await WebSocket.connect('ws://$host:$port').timeout(timeout);
      _socket = ws;

      final completer = Completer<bool>();

      ws.listen(
        (data) {
          _handleMessage(data.toString(), password, completer);
        },
        onError: (_) {
          _setStatus(ObsStatus.error);
          disconnect();
          if (!completer.isCompleted) completer.complete(false);
        },
        onDone: () {
          disconnect();
          if (!completer.isCompleted) completer.complete(false);
        },
        cancelOnError: true,
      );

      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          disconnect();
          return false;
        },
      );
    } catch (_) {
      _setStatus(ObsStatus.error);
      disconnect();
      return false;
    }
  }

  void _handleMessage(
    String msg,
    String password,
    Completer<bool> authCompleter,
  ) {
    try {
      final json = jsonDecode(msg) as Map<String, dynamic>;
      final op = json['op'] as int?;
      final d = json['d'] as Map<String, dynamic>? ?? {};

      switch (op) {
        case 0: // Hello
          _handleHello(d, password);
          break;
        case 2: // Identified
          _setStatus(ObsStatus.connected);
          if (!authCompleter.isCompleted) authCompleter.complete(true);
          _fetchCurrentScene();
          break;
        case 7: // RequestResponse
          final reqId = d['requestId'] as String?;
          if (reqId != null && _pendingRequests.containsKey(reqId)) {
            _pendingRequests.remove(reqId)!.complete(d);
          }
          break;
        case 9: // Event
          final eventType = d['eventType'] as String?;
          if (eventType == 'CurrentProgramSceneChanged') {
            final data = d['eventData'] as Map<String, dynamic>?;
            _currentScene = data?['sceneName'] as String? ?? '';
          }
          break;
      }
    } catch (_) {}
  }

  void _handleHello(Map<String, dynamic> d, String password) {
    final auth = d['authentication'] as Map<String, dynamic>?;
    String? authResponse;

    if (auth != null) {
      final challenge = auth['challenge'] as String;
      final salt = auth['salt'] as String;

      // obs-websocket v5 SHA256 auth
      final passSaltHash = base64Encode(
        sha256.convert(utf8.encode(password + salt)).bytes,
      );
      authResponse = base64Encode(
        sha256.convert(utf8.encode(passSaltHash + challenge)).bytes,
      );
    }

    final identify = {
      'op': 1,
      'd': {
        'rpcVersion': 1,
        'authentication': ?authResponse,
        'eventSubscriptions': 33, // General + Scenes
      },
    };

    _socket?.add(jsonEncode(identify));
  }

  Future<Map<String, dynamic>> sendRequest(
    String requestType, [
    Map<String, dynamic>? requestData,
  ]) {
    final ws = _socket;
    if (ws == null || _status != ObsStatus.connected) {
      return Future.error('Not connected to OBS');
    }

    final reqId = 'req_${++_requestIdCounter}';
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[reqId] = completer;

    final req = {
      'op': 6,
      'd': {
        'requestType': requestType,
        'requestId': reqId,
        'requestData': ?requestData,
      },
    };

    ws.add(jsonEncode(req));
    return completer.future.timeout(const Duration(seconds: 4));
  }

  Future<String> _fetchCurrentScene() async {
    try {
      final res = await sendRequest('GetCurrentProgramScene');
      final data = res['responseData'] as Map<String, dynamic>?;
      _currentScene = data?['sceneName'] as String? ?? '';
      return _currentScene;
    } catch (_) {
      return '';
    }
  }

  Future<bool> addBrowserSource({
    required String url,
    String? sceneName,
    String inputName = 'DotRec Screen',
    int width = 1080,
    int height = 2400,
  }) async {
    try {
      final targetScene =
          sceneName ??
          (_currentScene.isNotEmpty
              ? _currentScene
              : await _fetchCurrentScene());
      if (targetScene.isEmpty) return false;

      final settings = {
        'url': url,
        'width': width,
        'height': height,
        'fps': 60,
        'reroute_audio': true,
        'css': 'body { background-color: rgba(0, 0, 0, 0); margin: 0px auto; overflow: hidden; }',
        'web_page_render_factor': 1.0,
      };

      try {
        final res = await sendRequest('CreateInput', {
          'sceneName': targetScene,
          'inputName': inputName,
          'inputKind': 'browser_source',
          'inputSettings': settings,
        });

        final status = res['requestStatus'] as Map<String, dynamic>?;
        if (status?['result'] == true) return true;
      } catch (_) {}

      // Если источник уже существует в OBS — обновляем его параметры
      try {
        final updateRes = await sendRequest('SetInputSettings', {
          'inputName': inputName,
          'inputSettings': settings,
        });
        final updateStatus =
            updateRes['requestStatus'] as Map<String, dynamic>?;
        return updateStatus?['result'] == true;
      } catch (_) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleRecord() async {
    try {
      final res = await sendRequest('ToggleRecord');
      final status = res['requestStatus'] as Map<String, dynamic>?;
      return status?['result'] == true;
    } catch (_) {
      return false;
    }
  }

  void disconnect() {
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError('OBS connection closed');
      }
    }
    _pendingRequests.clear();
    if (_status != ObsStatus.disconnected) {
      _setStatus(ObsStatus.disconnected);
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }
}
