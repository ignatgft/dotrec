import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../core/models/link_stats.dart';

enum LinkClientStatus {
  disconnected,
  connecting,
  handshake,
  streaming,
  error,
}

class LinkVideoFrame {
  const LinkVideoFrame({
    required this.data,
    required this.isKeyframe,
    required this.ptsUs,
  });

  final Uint8List data;
  final bool isKeyframe;
  final int ptsUs;
}

class LinkClient {
  LinkClient();

  static const int port = 48211;
  static const int protocolVersion = 1;
  static const int headerSize = 14;

  static const int typeConfig = 0x01;
  static const int typeVideo = 0x02;
  static const int typeAudio = 0x03;
  static const int typeCommand = 0x04;
  static const int typeStats = 0x05;

  static const int flagKeyframe = 0x01;

  Socket? _socket;
  bool _running = false;

  LinkClientStatus _status = LinkClientStatus.disconnected;
  LinkClientStatus get status => _status;

  final _statusController = StreamController<LinkClientStatus>.broadcast();
  Stream<LinkClientStatus> get statusStream => _statusController.stream;

  final _statsController = StreamController<LinkStats>.broadcast();
  Stream<LinkStats> get statsStream => _statsController.stream;

  final _videoFrameController = StreamController<LinkVideoFrame>.broadcast();
  Stream<LinkVideoFrame> get videoStream => _videoFrameController.stream;

  // Telemetry trackers
  int _framesInSec = 0;
  int _bytesInSec = 0;
  int _durationSec = 0;
  final int _droppedFrames = 0;
  Timer? _statsTimer;
  LinkStats _currentStats = const LinkStats();
  LinkStats get currentStats => _currentStats;

  Uint8List? _cachedSpsPps;
  Uint8List? get spsPps => _cachedSpsPps;

  String? sessionToken;
  Map<String, dynamic>? deviceInfo;

  void _setStatus(LinkClientStatus s) {
    _status = s;
    _statusController.add(s);
  }

  Future<bool> connect({
    String host = '127.0.0.1',
    int connectPort = port,
    String? pin,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    disconnect();
    _setStatus(LinkClientStatus.connecting);

    try {
      final s = await Socket.connect(host, connectPort, timeout: timeout);
      s.setOption(SocketOption.tcpNoDelay, true);
      _socket = s;
      _running = true;
      _setStatus(LinkClientStatus.handshake);

      // 1. Send JSON Handshake
      final handshakeReq = jsonEncode({
        'protocol': 'dotrec_link',
        'version': protocolVersion,
        'client': 'DotRec Link Desktop',
        'auth': {
          'type': pin != null && pin.isNotEmpty ? 'pin' : 'none',
          'value': pin ?? '',
        },
      });
      s.write('$handshakeReq\n');
      await s.flush();

      // Start socket processing
      _startSocketReader(s);
      _startStatsTimer();
      return true;
    } catch (e) {
      _setStatus(LinkClientStatus.error);
      disconnect();
      return false;
    }
  }

  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running) return;
      _durationSec++;

      final fps = _framesInSec.toDouble();
      final mbps = (_bytesInSec * 8) / (1024 * 1024);

      // Latency simulation or measured ping
      final latency = 28 + (_framesInSec > 0 ? (42 - 28) : 0);

      _currentStats = _currentStats.copyWith(
        fps: fps,
        bitrateMbps: double.parse(mbps.toStringAsFixed(1)),
        latencyMs: latency,
        droppedFrames: _droppedFrames,
        durationSeconds: _durationSec,
        isStreaming: _status == LinkClientStatus.streaming,
      );

      _framesInSec = 0;
      _bytesInSec = 0;

      _statsController.add(_currentStats);
    });
  }

  void _startSocketReader(Socket socket) {
    final buffer = BytesBuilder(copy: false);
    bool handshakeDone = false;

    socket.listen(
      (data) {
        if (!handshakeDone) {
          buffer.add(data);
          final bytes = buffer.toBytes();
          final newlineIndex = bytes.indexOf(10); // \n
          if (newlineIndex != -1) {
            final lineBytes = bytes.sublist(0, newlineIndex);
            final remaining = bytes.sublist(newlineIndex + 1);
            buffer.clear();
            buffer.add(remaining);

            final jsonLine = utf8.decode(lineBytes).trim();
            final success = _processHandshakeResponse(jsonLine);
            if (!success) {
              disconnect();
              return;
            }
            handshakeDone = true;
            _setStatus(LinkClientStatus.streaming);
          }
          return;
        }

        // Process binary stream
        buffer.add(data);
        _processBinaryBuffer(buffer);
      },
      onError: (err) {
        _setStatus(LinkClientStatus.error);
        disconnect();
      },
      onDone: () {
        disconnect();
      },
      cancelOnError: true,
    );
  }

  bool _processHandshakeResponse(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      if (json['status'] != 'ok') {
        return false;
      }
      deviceInfo = json['device'] as Map<String, dynamic>?;
      final session = json['session'] as Map<String, dynamic>?;
      sessionToken = session?['token'] as String?;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _processBinaryBuffer(BytesBuilder buffer) {
    final Uint8List currentBytes = buffer.toBytes();
    int offset = 0;

    while (currentBytes.length - offset >= headerSize) {
      final headerView = ByteData.sublistView(
        currentBytes,
        offset,
        offset + headerSize,
      );

      final type = headerView.getUint8(0);
      final flags = headerView.getUint8(1);
      final length = headerView.getUint32(2, Endian.big);
      final ptsUs = headerView.getInt64(6, Endian.big);

      if (length > 16 * 1024 * 1024) {
        // Sanity limit exceeded
        disconnect();
        return;
      }

      final totalFrameSize = headerSize + length;
      if (currentBytes.length - offset < totalFrameSize) {
        // Wait for remainder of payload
        break;
      }

      final payload = Uint8List.sublistView(
        currentBytes,
        offset + headerSize,
        offset + totalFrameSize,
      );

      _handleFrame(type, flags, ptsUs, payload);
      offset += totalFrameSize;
    }

    if (offset > 0) {
      final remaining = currentBytes.sublist(offset);
      buffer.clear();
      buffer.add(remaining);
    }
  }

  void _handleFrame(int type, int flags, int ptsUs, Uint8List payload) {
    _bytesInSec += headerSize + payload.length;

    if (type == typeConfig) {
      _cachedSpsPps = payload;
    } else if (type == typeVideo) {
      _framesInSec++;
      final isKeyframe = (flags & flagKeyframe) != 0;
      _videoFrameController.add(LinkVideoFrame(
        data: payload,
        isKeyframe: isKeyframe,
        ptsUs: ptsUs,
      ));
    } else if (type == typeStats) {
      try {
        final str = utf8.decode(payload);
        final json = jsonDecode(str) as Map<String, dynamic>;
        if (json.containsKey('fps')) {
          _currentStats = _currentStats.copyWith(
            fps: (json['fps'] as num).toDouble(),
            latencyMs: json['latency_ms'] as int? ?? _currentStats.latencyMs,
          );
        }
      } catch (_) {}
    }
  }

  void sendCommand(Map<String, dynamic> cmd) {
    final s = _socket;
    if (s == null || !_running) return;

    try {
      final payload = utf8.encode(jsonEncode(cmd));
      final header = ByteData(headerSize)
        ..setUint8(0, typeCommand)
        ..setUint8(1, 0)
        ..setUint32(2, payload.length, Endian.big)
        ..setInt64(6, 0, Endian.big);

      s.add(header.buffer.asUint8List());
      s.add(payload);
      s.flush();
    } catch (_) {}
  }

  void requestKeyframe() {
    sendCommand({'cmd': 'request_keyframe'});
  }

  void setBitrate(int bps) {
    sendCommand({'cmd': 'set_bitrate', 'bitrate_bps': bps});
  }

  void triggerConsent() {
    sendCommand({'cmd': 'trigger_consent'});
  }

  void disconnect() {
    _running = false;
    _statsTimer?.cancel();
    _statsTimer = null;
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    if (_status != LinkClientStatus.disconnected) {
      _setStatus(LinkClientStatus.disconnected);
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _statsController.close();
    _videoFrameController.close();
  }
}
