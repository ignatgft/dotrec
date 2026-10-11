import 'package:flutter/services.dart';

import 'models/recording_item.dart';

/// Канал библиотеки (контракт v1).
class LibraryChannel {
  LibraryChannel({BinaryMessenger? messenger})
    : _method = MethodChannel(
        'app.dotrec/library',
        const StandardMethodCodec(),
        messenger,
      );

  final MethodChannel _method;

  Future<List<RecordingItem>> list() async {
    final List<Object?>? raw = await _method.invokeMethod<List<Object?>>(
      'list',
    );
    if (raw == null) return const [];
    return [
      for (final e in raw)
        RecordingItem.fromMap(Map<Object?, Object?>.from(e as Map)),
    ];
  }

  Future<bool> delete(String uri) async {
    final bool? v = await _method.invokeMethod<bool>('delete', {'uri': uri});
    return v ?? false;
  }

  Future<void> share(String uri) =>
      _method.invokeMethod<void>('share', {'uri': uri});

  Future<void> open(String uri) =>
      _method.invokeMethod<void>('open', {'uri': uri});

  Future<String?> trim({
    required String uri,
    required int startMs,
    required int endMs,
  }) =>
      _method.invokeMethod<String>('trim', {
        'uri': uri,
        'startMs': startMs,
        'endMs': endMs,
      });
}
