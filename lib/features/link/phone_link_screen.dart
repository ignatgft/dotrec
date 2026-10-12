import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/dot_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_segmented.dart';
import '../../core/widgets/dot_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/models/link_state.dart';
import '../../platform/models/record_settings.dart';
import '../../platform/models/recorder_state.dart';
import '../../providers.dart';
import '../settings/settings_screen.dart';

class PhoneLinkScreen extends ConsumerStatefulWidget {
  const PhoneLinkScreen({super.key});

  @override
  ConsumerState<PhoneLinkScreen> createState() => _PhoneLinkScreenState();
}

class _PhoneLinkScreenState extends ConsumerState<PhoneLinkScreen> {
  String _mode = 'usb';
  String _quality = '1080·60';
  bool _audioToPc = true;
  bool _blankScreen = false;
  bool _parallelRecord = false;

  @override
  void initState() {
    super.initState();
    // Запускаем сервер Link по умолчанию в режиме USB
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recorderChannelProvider).startLinkServer(mode: _mode);
    });
  }

  void _onModeChanged(String mode) {
    setState(() => _mode = mode);
    ref.read(recorderChannelProvider).startLinkServer(mode: mode);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    final AsyncValue<LinkState> linkAsync = ref.watch(linkStateProvider);
    final LinkState link = linkAsync.valueOrNull ?? const LinkState();
    final AsyncValue<RecorderState> recAsync = ref.watch(recorderStateProvider);
    final RecorderState rec = recAsync.valueOrNull ?? const Idle();
    final AsyncValue<RecordSettings> cfgAsync = ref.watch(settingsProvider);
    final RecordSettings cfg = cfgAsync.valueOrNull ?? const RecordSettings();

    final bool isConnected =
        link.status == 'connected' || link.status == 'streaming';
    final bool isStreaming = rec is Recording || rec is Starting;

    final String clientLabel = link.clientName.isNotEmpty
        ? link.clientName
        : 'DESKTOP-4K2';
    final String statusSubtitle = isConnected
        ? '${t.linkConnected} · ${_mode.toUpperCase()} ${link.latencyMs} мс'
        : t.linkWaiting;

    final String formattedPin = link.pin.length == 6
        ? '${link.pin.substring(0, 3)} ${link.pin.substring(3)}'
        : '482 913';

    return Scaffold(
      appBar: AppBar(
        title: Row(
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
              tooltip: t.settings,
              icon: SvgPicture.asset(
                DotIcons.settings,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  context.dot.fg,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DotTokens.lg),
          children: [
            Text(
              t.linkTitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DotTokens.md),
            // Карточка статуса подключения
            DotCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected
                              ? const Color(0xFF2ECC71)
                              : context.dot.record,
                        ),
                      ),
                      const SizedBox(width: DotTokens.sm),
                      Text(
                        clientLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DotTokens.xs),
                  Text(
                    statusSubtitle,
                    style: TextStyle(fontSize: 13, color: context.dot.fgMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DotTokens.lg),
            Text(t.linkMethod, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: DotTokens.sm),
            DotSegmented<String>(
              values: const ['usb', 'wifi'],
              selected: _mode,
              labelOf: (String v) => v == 'usb' ? 'USB' : 'Wi‑Fi',
              onSelected: _onModeChanged,
            ),
            if (_mode == 'wifi') ...[
              const SizedBox(height: DotTokens.lg),
              DotCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.linkWifiPin, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: DotTokens.sm),
                    Center(
                      child: Text(
                        formattedPin,
                        style: const TextStyle(
                          fontFamily: DotTokens.dotFamily,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: DotTokens.xs),
                    Center(
                      child: Text(
                        t.linkPinHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.dot.fgMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: DotTokens.lg),
            Text(t.linkStreamQuality, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: DotTokens.sm),
            DotSegmented<String>(
              values: const ['720·30', '1080·60', 'auto'],
              selected: _quality,
              labelOf: (String v) => switch (v) {
                '720·30' => '720·30',
                '1080·60' => '1080·60',
                _ => 'Авто',
              },
              onSelected: (String v) => setState(() => _quality = v),
            ),
            const SizedBox(height: DotTokens.lg),
            DotCard(
              child: Column(
                children: [
                  DotSwitch(
                    value: _audioToPc,
                    label: t.linkAudioToPc,
                    onChanged: (bool v) => setState(() => _audioToPc = v),
                  ),
                  const SizedBox(height: DotTokens.sm),
                  DotSwitch(
                    value: _blankScreen,
                    label: t.linkBlankScreen,
                    onChanged: (bool v) => setState(() => _blankScreen = v),
                  ),
                  const SizedBox(height: DotTokens.sm),
                  DotSwitch(
                    value: _parallelRecord,
                    label: t.linkParallelRecord,
                    onChanged: (bool v) => setState(() => _parallelRecord = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DotTokens.xl),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: isStreaming
                    ? context.dot.record
                    : context.dot.fg,
                foregroundColor: context.dot.bg,
              ),
              onPressed: () {
                final ch = ref.read(recorderChannelProvider);
                if (isStreaming) {
                  ch.stop();
                } else {
                  // Начать трансляцию экрана
                  final targetFps = _quality == '720·30' ? 30 : 60;
                  final targetRes = _quality == '720·30' ? 720 : 1080;
                  ch.start(
                    cfg.copyWith(
                      resolution: targetRes,
                      fps: targetFps,
                      systemAudio: _audioToPc,
                      codec: 'h264',
                    ),
                  );
                }
              },
              child: Text(
                isStreaming ? t.linkStopStream : t.linkStartStream,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
