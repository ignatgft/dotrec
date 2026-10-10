import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/dot_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_segmented.dart';
import '../../core/widgets/dot_widgets.dart';
import '../../core/widgets/record_button.dart';
import '../../platform/models/device_caps.dart';
import '../../platform/models/record_settings.dart';
import '../../platform/models/recorder_state.dart';
import '../../providers.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';

RecordVisualState _visualOf(RecorderState s) => switch (s) {
  Idle() => RecordVisualState.ready,
  Countdown() => RecordVisualState.countdown,
  Starting() => RecordVisualState.recording,
  Recording() => RecordVisualState.recording,
  Paused() => RecordVisualState.paused,
  Saving() => RecordVisualState.saving,
  Failed() => RecordVisualState.failed,
  Saved() => RecordVisualState.ready,
};

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<RecorderState> st = ref.watch(recorderStateProvider);
    final AsyncValue<RecordSettings> settings = ref.watch(settingsProvider);
    final AsyncValue<DeviceCaps> caps = ref.watch(deviceCapsProvider);
    final RecorderState s = st.valueOrNull ?? const Idle();
    final RecordSettings cfg = settings.valueOrNull ?? const RecordSettings();
    final DeviceCaps dc = caps.valueOrNull ?? const DeviceCaps();
    final bool busy =
        s is Recording ||
        s is Paused ||
        s is Saving ||
        s is Starting ||
        s is Countdown;

    final String status = switch (s) {
      Idle() => 'READY',
      Countdown(secondsLeft: final n) => '00:0$n',
      Starting() => '···',
      Recording(elapsed: final e) => DotTimer.format(e),
      Paused() => 'PAUSED',
      Saving() => 'SAVING',
      Failed() => 'ERROR',
      Saved() => 'READY',
    };
    final String sub =
        '${cfg.resolution}p · ${cfg.fps} FPS · ${cfg.bitrateMbps} Мбит/с';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DotTokens.lg),
          children: [
            Row(
              children: [
                const Text(
                  '● REC',
                  style: TextStyle(
                    fontFamily: DotTokens.dotFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Записи',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LibraryScreen(),
                    ),
                  ),
                  icon: SvgPicture.asset(
                    DotIcons.library,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      context.dot.fg,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Настройки',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                  icon: SvgPicture.asset(
                    DotIcons.settings,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      context.dot.fg,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DotTokens.xl),
            Center(
              child: Text(
                status,
                style: const TextStyle(
                  fontFamily: DotTokens.dotFamily,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Center(
              child: Text(
                sub,
                style: TextStyle(fontSize: 13, color: context.dot.fgMuted),
              ),
            ),
            const SizedBox(height: DotTokens.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (s is Recording || s is Paused)
                  IconButton.filled(
                    tooltip: s is Paused ? 'Продолжить' : 'Пауза',
                    onPressed: () {
                      final RecorderChannelReader r = RecorderChannelReader(
                        ref,
                      );
                      if (s is Paused) {
                        r.resume();
                      } else {
                        r.pause();
                      }
                    },
                    icon: Icon(s is Paused ? Icons.play_arrow : Icons.pause),
                  ),
                if (s is Recording || s is Paused)
                  const SizedBox(width: DotTokens.lg),
                RecordButton(
                  visual: _visualOf(s),
                  countdownLeft: s is Countdown
                      ? s.secondsLeft
                      : cfg.countdownSec,
                  onTap: () {
                    final RecorderChannelReader r = RecorderChannelReader(ref);
                    if (s is Recording || s is Paused) {
                      r.stop();
                    } else if (s is Idle || s is Failed || s is Saved) {
                      r.start(cfg);
                    }
                  },
                ),
              ],
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: DotTokens.sm),
                child: Text(
                  s is Recording || s is Paused
                      ? 'Остановить'
                      : 'Начать запись',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            if (s is Failed)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: DotTokens.sm),
                  child: Text(
                    _errorText(s.code),
                    style: TextStyle(color: context.dot.fg),
                  ),
                ),
              ),
            const SizedBox(height: DotTokens.xl),
            const Text('Пресет', style: TextStyle(fontSize: 13)),
            const SizedBox(height: DotTokens.sm),
            DotSegmented<String>(
              values: const ['fast', 'balanced', 'quality', 'custom'],
              selected: cfg.preset,
              labelOf: (String p) => switch (p) {
                'fast' => 'Быстро',
                'balanced' => 'Баланс',
                'quality' => 'Качество',
                _ => 'Свой',
              },
              onSelected: busy
                  ? (_) {}
                  : (String p) => ref
                        .read(settingsProvider.notifier)
                        .save(RecordSettings.presetNamed(p)),
            ),
            const SizedBox(height: DotTokens.lg),
            const Text('Разрешение', style: TextStyle(fontSize: 13)),
            const SizedBox(height: DotTokens.sm),
            DotSegmented<int>(
              values: DotTokens.resolutions,
              selected: cfg.resolution,
              labelOf: (int v) => '$v',
              enabledOf: busy
                  ? (_) => false
                  : (int v) => dc.availableResolutions.contains(v),
              onSelected: (int v) => ref
                  .read(settingsProvider.notifier)
                  .save(cfg.withCustom(resolution: v)),
            ),
            const SizedBox(height: DotTokens.lg),
            const Text('FPS', style: TextStyle(fontSize: 13)),
            const SizedBox(height: DotTokens.sm),
            DotSegmented<int>(
              values: DotTokens.fpsOptions,
              selected: cfg.fps,
              labelOf: (int v) => '$v',
              enabledOf: busy ? (_) => false : (int v) => v <= dc.maxRefreshHz,
              onSelected: (int v) => ref
                  .read(settingsProvider.notifier)
                  .save(cfg.withCustom(fps: v)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: DotTokens.sm),
              child: Text(
                'Экран поддерживает до ${dc.maxRefreshHz} Гц',
                style: TextStyle(fontSize: 12, color: context.dot.fgMuted),
              ),
            ),
            const SizedBox(height: DotTokens.lg),
            Wrap(
              spacing: DotTokens.lg,
              children: [
                DotSwitch(
                  value: cfg.mic,
                  label: 'Микрофон',
                  onChanged: busy
                      ? null
                      : (bool v) => ref
                            .read(settingsProvider.notifier)
                            .save(cfg.copyWith(mic: v)),
                ),
                DotSwitch(
                  value: cfg.systemAudio,
                  label: 'Звук системы',
                  onChanged: busy
                      ? null
                      : (bool v) => ref
                            .read(settingsProvider.notifier)
                            .save(cfg.copyWith(systemAudio: v)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _errorText(String code) => switch (code) {
    'low_storage' => 'Мало места. Освободите хотя бы 200 МБ',
    'consent_denied' => 'Запись не началась. Доступ к экрану не выдан',
    'not_running' => 'Запись не идёт',
    _ => 'Ошибка записи: $code',
  };
}

/// Тонкая обёртка, чтобы UI не трогал MethodChannel напрямую.
class RecorderChannelReader {
  RecorderChannelReader(this.ref);
  final WidgetRef ref;

  void start(RecordSettings s) => ref.read(recorderChannelProvider).start(s);
  void stop() => ref.read(recorderChannelProvider).stop();
  void pause() => ref.read(recorderChannelProvider).pause();
  void resume() => ref.read(recorderChannelProvider).resume();
}
