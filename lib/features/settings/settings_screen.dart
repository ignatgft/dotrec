import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_segmented.dart';
import '../../core/widgets/dot_widgets.dart';
import '../../platform/models/device_caps.dart';
import '../../platform/models/record_settings.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecordSettings cfg =
        ref.watch(settingsProvider).valueOrNull ?? const RecordSettings();
    final DeviceCaps dc =
        ref.watch(deviceCapsProvider).valueOrNull ?? const DeviceCaps();

    Future<void> upd(RecordSettings n) =>
        ref.read(settingsProvider.notifier).save(n);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(DotTokens.lg),
        children: [
          const Text('Видео', style: TextStyle(fontSize: 13)),
          const SizedBox(height: DotTokens.sm),
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Разрешение'),
                const SizedBox(height: DotTokens.sm),
                DotSegmented<int>(
                  values: DotTokens.resolutions,
                  selected: cfg.resolution,
                  labelOf: (int v) => '$v',
                  enabledOf: (int v) => dc.availableResolutions.contains(v),
                  onSelected: (int v) => upd(cfg.withCustom(resolution: v)),
                ),
                const SizedBox(height: DotTokens.lg),
                const Text('FPS'),
                const SizedBox(height: DotTokens.sm),
                DotSegmented<int>(
                  values: DotTokens.fpsOptions,
                  selected: cfg.fps,
                  labelOf: (int v) => '$v',
                  enabledOf: (int v) => v <= dc.maxRefreshHz,
                  onSelected: (int v) => upd(cfg.withCustom(fps: v)),
                ),
                const SizedBox(height: DotTokens.lg),
                Text('Битрейт: ${cfg.bitrateMbps} Мбит/с'),
                Slider(
                  min: 0,
                  max: (DotTokens.bitrates.length - 1).toDouble(),
                  divisions: DotTokens.bitrates.length - 1,
                  value: DotTokens.bitrates
                      .indexOf(cfg.bitrateMbps)
                      .clamp(0, DotTokens.bitrates.length - 1)
                      .toDouble(),
                  onChanged: (double i) => upd(
                    cfg.copyWith(
                      bitrateMbps: DotTokens.bitrates[i.round()],
                      preset: 'custom',
                    ),
                  ),
                ),
                const SizedBox(height: DotTokens.sm),
                const Text('Кодек'),
                DotSegmented<String>(
                  values: const ['h264', 'hevc'],
                  selected: cfg.codec,
                  labelOf: (String c) => c == 'h264' ? 'H.264' : 'HEVC',
                  enabledOf: (String c) => c == 'h264' || dc.hevcSupported,
                  onSelected: (String c) =>
                      upd(cfg.copyWith(codec: c, preset: 'custom')),
                ),
                if (!dc.hevcSupported)
                  Padding(
                    padding: const EdgeInsets.only(top: DotTokens.sm),
                    child: Text(
                      'Устройство без аппаратного HEVC',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.dot.fgMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: DotTokens.lg),
          const Text('Звук', style: TextStyle(fontSize: 13)),
          const SizedBox(height: DotTokens.sm),
          DotCard(
            child: Column(
              children: [
                DotSwitch(
                  value: cfg.mic,
                  label: 'Микрофон',
                  onChanged: (bool v) => upd(cfg.copyWith(mic: v)),
                ),
                const SizedBox(height: DotTokens.sm),
                DotSwitch(
                  value: cfg.systemAudio,
                  label: 'Звук системы (v1.1)',
                  onChanged: (bool v) => upd(cfg.copyWith(systemAudio: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: DotTokens.lg),
          const Text('Запись', style: TextStyle(fontSize: 13)),
          const SizedBox(height: DotTokens.sm),
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Обратный отсчёт'),
                const SizedBox(height: DotTokens.sm),
                DotSegmented<int>(
                  values: DotTokens.countdownOptions,
                  selected: cfg.countdownSec,
                  labelOf: (int v) => v == 0 ? 'Нет' : '$v с',
                  onSelected: (int v) => upd(cfg.copyWith(countdownSec: v)),
                ),
                const SizedBox(height: DotTokens.sm),
                DotSwitch(
                  value: cfg.overlayPill,
                  label: 'Плавающая плашка',
                  onChanged: (bool v) => upd(cfg.copyWith(overlayPill: v)),
                ),
                if (cfg.overlayPill) ...[
                  const SizedBox(height: DotTokens.sm),
                  Text(
                    'Требуется разрешение «Поверх других окон».',
                    style: TextStyle(fontSize: 12, color: context.dot.fgMuted),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(recorderChannelProvider).openOverlaySettings(),
                    child: const Text('Открыть разрешение'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: DotTokens.lg),
          const Text('Быстрый доступ', style: TextStyle(fontSize: 13)),
          const SizedBox(height: DotTokens.sm),
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Плитка в шторке и виджет запускают запись без открытия приложения.',
                  style: TextStyle(fontSize: 12, color: context.dot.fgMuted),
                ),
                const SizedBox(height: DotTokens.sm),
                FilledButton.tonal(
                  onPressed: () async {
                    final bool ok = await ref
                        .read(recorderChannelProvider)
                        .requestAddTile();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Плитка добавлена'
                                : 'Недоступно: требуется Android 13+',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Добавить плитку в шторку'),
                ),
              ],
            ),
          ),
          const SizedBox(height: DotTokens.lg),
          const Text('Вид', style: TextStyle(fontSize: 13)),
          const SizedBox(height: DotTokens.sm),
          DotCard(
            child: DotSegmented<String>(
              values: const ['system', 'light', 'dark'],
              selected: cfg.themeMode,
              labelOf: (String v) => switch (v) {
                'light' => 'Светлая',
                'dark' => 'Тёмная',
                _ => 'Система',
              },
              onSelected: (String v) => upd(cfg.copyWith(themeMode: v)),
            ),
          ),
          const SizedBox(height: DotTokens.lg),
          DotCard(
            child: Text(
              'DotRec работает офлайн. Версия 0.3.0-beta.',
              style: TextStyle(fontSize: 12, color: context.dot.fgMuted),
            ),
          ),
        ],
      ),
    );
  }
}
