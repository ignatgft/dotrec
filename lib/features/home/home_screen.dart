import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/dot_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_segmented.dart';
import '../../core/widgets/dot_widgets.dart';
import '../../core/widgets/record_button.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/models/device_caps.dart';
import '../../platform/models/record_settings.dart';
import '../../platform/models/recorder_state.dart';
import '../../providers.dart';
import '../guides/guides_screen.dart';
import '../library/library_screen.dart';
import '../link/phone_link_screen.dart';
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
    // FR-ONB-03: при отказе в разрешении объясняем и ведём в настройки.
    ref.listen<AsyncValue<RecorderState>>(recorderStateProvider, (
      _,
      AsyncValue<RecorderState> next,
    ) {
      final RecorderState? s = next.valueOrNull;
      if (s is Failed &&
          (s.code == 'audio_error' || s.code == 'consent_denied')) {
        final AppLocalizations lt = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorText(lt, s.code)),
            action: SnackBarAction(
              label: lt.settings,
              onPressed: () =>
                  ref.read(recorderChannelProvider).openAppSettings(),
            ),
          ),
        );
      }
    });
    final AsyncValue<RecorderState> st = ref.watch(recorderStateProvider);
    final AsyncValue<RecordSettings> settings = ref.watch(settingsProvider);
    final AsyncValue<DeviceCaps> caps = ref.watch(deviceCapsProvider);
    final RecorderState s = st.valueOrNull ?? const Idle();
    final RecordSettings cfg = settings.valueOrNull ?? const RecordSettings();
    final DeviceCaps dc = caps.valueOrNull ?? const DeviceCaps();
    final AppLocalizations t = AppLocalizations.of(context)!;
    final bool busy =
        s is Recording ||
        s is Paused ||
        s is Saving ||
        s is Starting ||
        s is Countdown;

    final String status = switch (s) {
      Idle() => t.ready,
      Countdown(secondsLeft: final n) => '00:0$n',
      Starting() => '···',
      Recording(elapsed: final e) => DotTimer.format(e),
      Paused() => t.paused,
      Saving() => t.saving,
      Failed() => 'ERROR',
      Saved() => t.ready,
    };
    final String sub =
        '${cfg.resolution}p · ${cfg.fps} FPS · ${cfg.bitrateMbps} Mbps';

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
                  tooltip: t.linkTitle,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PhoneLinkScreen(),
                    ),
                  ),
                  icon: SvgPicture.asset(
                    DotIcons.mirror,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      context.dot.fg,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t.guides,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GuidesScreen(),
                    ),
                  ),
                  icon: SvgPicture.asset(
                    DotIcons.info,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      context.dot.fg,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t.library,
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
                  tooltip: t.settings,
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
              // T-27: TalkBack объявляет таймер раз в 10 с, а не каждую секунду.
              child: s is Recording
                  ? Semantics(
                      liveRegion: true,
                      excludeSemantics: true,
                      label: DotTimer.format(
                        Duration(seconds: s.elapsed.inSeconds ~/ 10 * 10),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontFamily: DotTokens.dotFamily,
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Text(
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
                    tooltip: s is Paused ? t.resume : t.pause,
                    onPressed: () {
                      final actions = ref.read(recorderActionsProvider);
                      if (s is Paused) {
                        actions.resume();
                      } else {
                        actions.pause();
                      }
                    },
                    icon: SvgPicture.asset(
                      s is Paused ? DotIcons.play : DotIcons.pause,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        context.dot.fg,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                if (s is Recording || s is Paused)
                  const SizedBox(width: DotTokens.lg),
                RecordButton(
                  visual: _visualOf(s),
                  countdownLeft: s is Countdown
                      ? s.secondsLeft
                      : cfg.countdownSec,
                  onTap: () {
                    final actions = ref.read(recorderActionsProvider);
                    if (s is Recording || s is Paused) {
                      actions.stop();
                    } else if (s is Idle || s is Failed || s is Saved) {
                      actions.start(cfg);
                    }
                  },
                ),
              ],
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: DotTokens.sm),
                child: Text(
                  s is Recording || s is Paused ? t.stop : t.start,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            if (s is Failed)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: DotTokens.sm),
                  child: Text(
                    _errorText(t, s.code),
                    style: TextStyle(color: context.dot.fg),
                  ),
                ),
              ),
            const SizedBox(height: DotTokens.xl),
            Text(t.presetLabel, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: DotTokens.sm),
            DotSegmented<String>(
              values: const ['fast', 'balanced', 'quality', 'custom'],
              selected: cfg.preset,
              labelOf: (String p) => switch (p) {
                'fast' => t.presetFast,
                'balanced' => t.presetBalanced,
                'quality' => t.presetQuality,
                _ => t.presetCustom,
              },
              onSelected: busy
                  ? (_) {}
                  : (String p) => ref
                        .read(settingsProvider.notifier)
                        .save(RecordSettings.presetNamed(p)),
            ),
            const SizedBox(height: DotTokens.lg),
            Text(t.resolutionLabel, style: const TextStyle(fontSize: 13)),
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
                t.fps_cap(dc.maxRefreshHz),
                style: TextStyle(fontSize: 12, color: context.dot.fgMuted),
              ),
            ),
            const SizedBox(height: DotTokens.lg),
            Wrap(
              spacing: DotTokens.lg,
              children: [
                DotSwitch(
                  value: cfg.mic,
                  label: t.micLabel,
                  onChanged: busy
                      ? null
                      : (bool v) => ref
                            .read(settingsProvider.notifier)
                            .save(cfg.copyWith(mic: v)),
                ),
                DotSwitch(
                  value: cfg.systemAudio,
                  label: t.sysAudioLabel,
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

  String _errorText(AppLocalizations t, String code) => switch (code) {
    'low_storage' => t.err_space,
    'consent_denied' => t.err_consent,
    'audio_error' => t.err_mic,
    'projection_stopped' => t.audio_blocked,
    'encoder_error' => t.errorLabel,
    'io_error' => t.errorLabel,
    'not_running' => t.errorLabel,
    _ => '${t.errorLabel}: $code',
  };
}
