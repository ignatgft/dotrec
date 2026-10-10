import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_segmented.dart';
import '../../core/widgets/dot_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/models/device_caps.dart';
import '../../platform/models/record_settings.dart';
import '../../providers.dart';
import '../guides/guides_screen.dart';

const List<String> _localeCodes = [
  'system',
  'en',
  'ru',
  'es',
  'de',
  'fr',
  'pt',
  'uk',
];

const Map<String, String> _localeNames = {
  'en': 'English',
  'ru': 'Русский',
  'es': 'Español',
  'de': 'Deutsch',
  'fr': 'Français',
  'pt': 'Português',
  'uk': 'Українська',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecordSettings cfg =
        ref.watch(settingsProvider).valueOrNull ?? const RecordSettings();
    final DeviceCaps dc =
        ref.watch(deviceCapsProvider).valueOrNull ?? const DeviceCaps();
    final String localeCode =
        ref.watch(appLocaleProvider).valueOrNull ?? 'system';
    final AppLocalizations t = AppLocalizations.of(context)!;

    Future<void> upd(RecordSettings n) =>
        ref.read(settingsProvider.notifier).save(n);

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: const EdgeInsets.all(DotTokens.lg),
        children: [
          Text(t.videoLabel, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: DotTokens.sm),
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.resolutionLabel),
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
                Text(t.bitrateLabel(cfg.bitrateMbps)),
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
                Text(t.codecLabel),
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
                      t.hevcMissing,
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
          Text(t.audioLabel, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: DotTokens.sm),
          DotCard(
            child: Column(
              children: [
                DotSwitch(
                  value: cfg.mic,
                  label: t.micLabel,
                  onChanged: (bool v) => upd(cfg.copyWith(mic: v)),
                ),
                const SizedBox(height: DotTokens.sm),
                DotSwitch(
                  value: cfg.systemAudio,
                  label: t.sysAudioV11,
                  onChanged: (bool v) => upd(cfg.copyWith(systemAudio: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: DotTokens.lg),
          Text(t.recordingLabel, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: DotTokens.sm),
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.countdownLabel),
                const SizedBox(height: DotTokens.sm),
                DotSegmented<int>(
                  values: DotTokens.countdownOptions,
                  selected: cfg.countdownSec,
                  labelOf: (int v) => v == 0 ? t.noneLabel : t.countdownSec(v),
                  onSelected: (int v) => upd(cfg.copyWith(countdownSec: v)),
                ),
                const SizedBox(height: DotTokens.sm),
                DotSwitch(
                  value: cfg.overlayPill,
                  label: t.guideOverlayTitle,
                  onChanged: (bool v) => upd(cfg.copyWith(overlayPill: v)),
                ),
                if (cfg.overlayPill) ...[
                  const SizedBox(height: DotTokens.sm),
                  Text(
                    t.overlayNeedPermission,
                    style: TextStyle(fontSize: 12, color: context.dot.fgMuted),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(recorderChannelProvider).openOverlaySettings(),
                    child: Text(t.openPermission),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: DotTokens.lg),
          Text(t.quickAccess, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: DotTokens.sm),
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.quickAccessBody,
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
                          content: Text(ok ? t.tileAdded : t.tileUnavailable),
                        ),
                      );
                    }
                  },
                  child: Text(t.addTileBtn),
                ),
              ],
            ),
          ),
          const SizedBox(height: DotTokens.lg),
          Text(t.appearanceLabel, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: DotTokens.sm),
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DotSegmented<String>(
                  values: const ['system', 'light', 'dark'],
                  selected: cfg.themeMode,
                  labelOf: (String v) => switch (v) {
                    'light' => t.themeLight,
                    'dark' => t.themeDark,
                    _ => t.langSystem,
                  },
                  onSelected: (String v) => upd(cfg.copyWith(themeMode: v)),
                ),
                const SizedBox(height: DotTokens.lg),
                Text(t.language),
                const SizedBox(height: DotTokens.sm),
                DotSegmented<String>(
                  values: _localeCodes,
                  selected: localeCode,
                  labelOf: (String v) =>
                      v == 'system' ? t.langSystem : _localeNames[v]!,
                  onSelected: (String v) =>
                      ref.read(appLocaleProvider.notifier).set(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: DotTokens.lg),
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.aboutLine} 0.4.0-beta.',
                  style: TextStyle(fontSize: 12, color: context.dot.fgMuted),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GuidesScreen(),
                    ),
                  ),
                  child: Text(t.guidesTitle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
