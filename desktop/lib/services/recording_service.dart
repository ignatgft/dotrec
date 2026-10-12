import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import 'link_client.dart';

class RecordingResult {
  const RecordingResult({
    required this.filePath,
    required this.duration,
    required this.bytesWritten,
  });

  final String filePath;
  final Duration duration;
  final int bytesWritten;
}

class RecordingService {
  RecordingService();

  IOSink? _fileSink;
  File? _currentFile;
  DateTime? _startTime;
  int _bytesWritten = 0;
  bool _hasWrittenConfig = false;

  bool get isRecording => _fileSink != null;
  String? get currentFilePath => _currentFile?.path;
  int get bytesWritten => _bytesWritten;

  static const List<int> annexBStartCode = [0x00, 0x00, 0x00, 0x01];

  Directory getSaveDirectory([String? customPath]) {
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return dir;
    }
    final home =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '.';
    final sep = Platform.pathSeparator;
    final dir = Directory('$home${sep}Videos${sep}DotRec');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<String> startRecording(
    Uint8List? initialSpsPps, [
    String? customDir,
  ]) async {
    await stopRecording();

    final dir = getSaveDirectory(customDir);
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final sep = Platform.pathSeparator;
    final file = File('${dir.path}${sep}DotRec_Stream_$timestamp.mp4');
    file.createSync(recursive: true);

    _currentFile = file;
    _fileSink = file.openWrite();
    _startTime = now;
    _bytesWritten = 0;
    _hasWrittenConfig = false;

    if (initialSpsPps != null && initialSpsPps.isNotEmpty) {
      writeConfig(initialSpsPps);
    }

    return file.path;
  }

  void writeConfig(Uint8List spsPps) {
    final sink = _fileSink;
    if (sink == null) return;

    if (!hasStartCode(spsPps)) {
      sink.add(annexBStartCode);
      _bytesWritten += 4;
    }
    sink.add(spsPps);
    _bytesWritten += spsPps.length;
    _hasWrittenConfig = true;
  }

  void writeVideoFrame(LinkVideoFrame frame, Uint8List? spsPps) {
    final sink = _fileSink;
    if (sink == null) return;

    if (frame.isKeyframe && !_hasWrittenConfig && spsPps != null) {
      writeConfig(spsPps);
    }

    if (!hasStartCode(frame.data)) {
      sink.add(annexBStartCode);
      _bytesWritten += 4;
    }
    sink.add(frame.data);
    _bytesWritten += frame.data.length;
  }

  void writeAudioFrame(Uint8List audioData) {
    final sink = _fileSink;
    if (sink == null || audioData.isEmpty) return;
    sink.add(audioData);
    _bytesWritten += audioData.length;
  }

  static bool hasStartCode(Uint8List data) {
    if (data.length < 3) {
      return false;
    }
    if (data[0] == 0 && data[1] == 0 && data[2] == 1) {
      return true;
    }
    if (data.length >= 4 &&
        data[0] == 0 &&
        data[1] == 0 &&
        data[2] == 0 &&
        data[3] == 1) {
      return true;
    }
    return false;
  }

  Future<RecordingResult?> stopRecording() async {
    final sink = _fileSink;
    final file = _currentFile;
    final start = _startTime;

    if (sink == null || file == null || start == null) {
      return null;
    }

    try {
      await sink.flush();
      await sink.close();
    } catch (_) {}

    final duration = DateTime.now().difference(start);
    final result = RecordingResult(
      filePath: file.path,
      duration: duration,
      bytesWritten: _bytesWritten,
    );

    _fileSink = null;
    _currentFile = null;
    _startTime = null;
    _bytesWritten = 0;
    _hasWrittenConfig = false;

    return result;
  }

  Directory getScreenshotDirectory([String? customPath]) {
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return dir;
    }
    final home =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '.';
    final sep = Platform.pathSeparator;
    final dir = Directory('$home${sep}Pictures${sep}DotRec');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<String> saveScreenshot(Uint8List pngBytes, [String? customDir]) async {
    final dir = getScreenshotDirectory(customDir);
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final sep = Platform.pathSeparator;
    final file = File('${dir.path}${sep}DotRec_Screenshot_$timestamp.png');
    await file.writeAsBytes(pngBytes, flush: true);
    return file.path;
  }
}
