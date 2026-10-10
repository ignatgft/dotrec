import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'platform/library_channel.dart';
import 'platform/models/device_caps.dart';
import 'platform/models/record_settings.dart';
import 'platform/models/recorder_state.dart';
import 'platform/models/recording_item.dart';
import 'platform/recorder_channel.dart';

final Provider<RecorderChannel> recorderChannelProvider =
    Provider<RecorderChannel>((Ref ref) => RecorderChannel());

final Provider<LibraryChannel> libraryChannelProvider =
    Provider<LibraryChannel>((Ref ref) => LibraryChannel());

/// Состояние записи из EventChannel (текущее при подписке).
final StreamProvider<RecorderState> recorderStateProvider =
    StreamProvider<RecorderState>((Ref ref) {
      return ref.watch(recorderChannelProvider).state;
    });

/// Настройки: источник правды — Kotlin SettingsStore, Dart читает/пишет через канал.
class SettingsNotifier extends AsyncNotifier<RecordSettings> {
  @override
  Future<RecordSettings> build() async {
    try {
      return await ref.watch(recorderChannelProvider).getSettings();
    } on Exception {
      return const RecordSettings();
    }
  }

  Future<void> save(RecordSettings next) async {
    state = AsyncData(next);
    try {
      await ref.read(recorderChannelProvider).saveSettings(next);
    } on Exception {
      // Локально уже обновлено; нативная сторона подтянет при следующем чтении.
    }
  }
}

final AsyncNotifierProvider<SettingsNotifier, RecordSettings> settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, RecordSettings>(
      SettingsNotifier.new,
    );

final FutureProvider<DeviceCaps> deviceCapsProvider =
    FutureProvider<DeviceCaps>((Ref ref) async {
      try {
        return await ref.watch(recorderChannelProvider).getDeviceCaps();
      } on Exception {
        return const DeviceCaps();
      }
    });

class LibraryNotifier extends AsyncNotifier<List<RecordingItem>> {
  @override
  Future<List<RecordingItem>> build() async {
    try {
      return await ref.watch(libraryChannelProvider).list();
    } on Exception {
      return const [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(libraryChannelProvider).list(),
    );
  }
}

final AsyncNotifierProvider<LibraryNotifier, List<RecordingItem>>
libraryProvider = AsyncNotifierProvider<LibraryNotifier, List<RecordingItem>>(
  LibraryNotifier.new,
);
