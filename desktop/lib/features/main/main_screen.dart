import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/dot_link_icons.dart';
import '../../core/models/stream_preset.dart';
import '../../core/providers/link_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_card.dart';
import '../../core/widgets/dot_segmented.dart';
import '../../core/widgets/dot_switch.dart';
import '../mirror/mirror_window.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  void _startMirroring(BuildContext context, WidgetRef ref) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const MirrorWindow()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(selectedDeviceProvider);
    final config = ref.watch(streamConfigProvider);
    final isDeviceReady = device?.isReady ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DotTokens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Device status banner
          DotCard(
            padding: const EdgeInsets.symmetric(
              horizontal: DotTokens.lg,
              vertical: DotTokens.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: isDeviceReady
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.dot.fg,
                        )
                      : (device != null
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.dot.fg,
                                width: 2,
                              ),
                              color: Colors.transparent,
                            )
                          : BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.dot.fgMuted,
                                width: 1.5,
                              ),
                              color: Colors.transparent,
                            )),
                ),
                const SizedBox(width: DotTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device != null
                            ? device.summary
                            : 'Устройство не подключено',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: DotTokens.dotFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device != null
                            ? (isDeviceReady
                                  ? 'Готов к зеркалированию через USB'
                                  : 'Требуется авторизация или настройка')
                            : 'Подключите телефон по USB-кабелю или перейдите во вкладку «Подключение»',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.dot.fgMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (device == null)
                  OutlinedButton(
                    onPressed: () {
                      ref.read(activeTabProvider.notifier).state =
                          DesktopTab.connection;
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.dot.fg,
                      side: BorderSide(color: context.dot.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DotTokens.radiusButton,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          DotLinkIcons.usb,
                          width: 16,
                          height: 16,
                          colorFilter: ColorFilter.mode(
                            context.dot.fg,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Подключить'),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: DotTokens.xl),

          // Stream Parameters Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Параметры потока',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DotTokens.lg),

                // Resolution
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Разрешение',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.dot.fgMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: DotSegmented<VideoResolution>(
                        values: VideoResolution.values,
                        selected: config.resolution,
                        labelOf: (r) => r.label,
                        onSelected: (r) {
                          ref.read(streamConfigProvider.notifier).state = config
                              .copyWith(resolution: r);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DotTokens.md),

                // FPS
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Кадров/с',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.dot.fgMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: DotSegmented<VideoFps>(
                        values: VideoFps.values,
                        selected: config.fps,
                        labelOf: (f) => f.label,
                        onSelected: (f) {
                          ref.read(streamConfigProvider.notifier).state = config
                              .copyWith(fps: f);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DotTokens.md),

                // Bitrate
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Битрейт',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.dot.fgMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: DotSegmented<VideoBitrate>(
                        values: VideoBitrate.values,
                        selected: config.bitrate,
                        labelOf: (b) => b.label,
                        onSelected: (b) {
                          ref.read(streamConfigProvider.notifier).state = config
                              .copyWith(bitrate: b);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: DotTokens.lg),

          // Stream Options Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Опции трансляции',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DotTokens.md),
                DotSwitch(
                  value: config.recordOnPc,
                  label: 'Запись на ПК параллельно',
                  subtitle:
                      'Автоматически сохранять поток в файл MP4 на компьютере',
                  onChanged: (val) {
                    ref.read(streamConfigProvider.notifier).state = config
                        .copyWith(recordOnPc: val);
                  },
                ),
                Divider(color: context.dot.line, height: DotTokens.lg),
                DotSwitch(
                  value: config.phoneAudio,
                  label: 'Звук с телефона',
                  subtitle: 'Передавать системный звук и микрофон на ПК',
                  onChanged: (val) {
                    ref.read(streamConfigProvider.notifier).state = config
                        .copyWith(phoneAudio: val);
                  },
                ),
                Divider(color: context.dot.line, height: DotTokens.lg),
                DotSwitch(
                  value: config.blankScreen,
                  label: 'Гасить экран телефона',
                  subtitle:
                      'Экономит батарею и предотвращает нагрев устройства',
                  onChanged: (val) {
                    ref.read(streamConfigProvider.notifier).state = config
                        .copyWith(blankScreen: val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: DotTokens.xl),

          // Primary Launch Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => _startMirroring(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.dot.fg,
                foregroundColor: context.dot.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DotTokens.radiusButton),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    DotLinkIcons.mirror,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      context.dot.bg,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Зеркалировать',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: DotTokens.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.dot.bg.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Ctrl+Shift+M',
                      style: TextStyle(
                        fontFamily: DotTokens.dotFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.dot.bg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
