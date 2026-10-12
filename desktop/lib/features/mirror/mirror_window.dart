import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/dot_link_icons.dart';
import '../../core/models/device_info.dart';
import '../../core/models/link_stats.dart';
import '../../core/providers/link_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_icon_button.dart';
import '../../services/link_client.dart';

class MirrorWindow extends ConsumerStatefulWidget {
  const MirrorWindow({super.key});

  @override
  ConsumerState<MirrorWindow> createState() => _MirrorWindowState();
}

class _MirrorWindowState extends ConsumerState<MirrorWindow> {
  bool _isHovering = false;
  Timer? _hideControlsTimer;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  bool _isBorderless = false;
  bool _showConsentNotice = false;
  Timer? _consentCheckTimer;
  int _frameCount = 0;
  StreamSubscription<LinkVideoFrame>? _videoSub;
  StreamSubscription<LinkAudioFrame>? _audioSub;

  // Новые элементы управления зеркалом
  int _rotationQuarter = 0;
  bool _fitMode = true;
  bool _phoneScreenOff = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _startMirroringPipeline();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _recordTimer?.cancel();
    _consentCheckTimer?.cancel();
    _videoSub?.cancel();
    _audioSub?.cancel();
    if (_isRecording) {
      ref.read(recordingServiceProvider).stopRecording();
    }
    super.dispose();
  }

  Future<void> _startMirroringPipeline() async {
    final device = ref.read(selectedDeviceProvider);
    final adb = ref.read(adbServiceProvider);
    final client = ref.read(linkClientProvider);

    if (device != null && device.transport == DeviceTransport.usb) {
      await adb.forwardPort(device.serial, LinkClient.port, LinkClient.port);
    }

    await client.connect();

    final config = ref.read(streamConfigProvider);
    if (config.recordOnPc) {
      await _startRecordingToFile(client);
    }

    _videoSub = client.videoStream.listen((frame) {
      _frameCount++;
      if (_isRecording) {
        ref
            .read(recordingServiceProvider)
            .writeVideoFrame(frame, client.spsPps);
      }
      if (_showConsentNotice && mounted) {
        setState(() => _showConsentNotice = false);
      }
    });

    _audioSub = client.audioStream.listen((frame) {
      if (_isRecording && !_isMuted) {
        ref.read(recordingServiceProvider).writeAudioFrame(frame.data);
      }
    });

    _consentCheckTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && _frameCount == 0) {
        setState(() => _showConsentNotice = true);
      }
    });
  }

  void _onPointerHover() {
    setState(() => _isHovering = true);
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isHovering = false);
    });
  }

  Future<void> _startRecordingToFile(LinkClient client) async {
    final rec = ref.read(recordingServiceProvider);
    await rec.startRecording(client.spsPps);
    if (mounted) {
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _recordSeconds++);
        });
      });
    }
  }

  Future<void> _toggleRecording() async {
    final client = ref.read(linkClientProvider);
    final rec = ref.read(recordingServiceProvider);

    if (!_isRecording) {
      final path = await rec.startRecording(client.spsPps);
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _recordSeconds++);
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Запись на ПК запущена: $path',
              style: const TextStyle(fontFamily: DotTokens.dotFamily),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      _recordTimer?.cancel();
      _recordTimer = null;
      final res = await rec.stopRecording();
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Запись сохранена (${res?.duration.inSeconds ?? 0} с): ${res?.filePath ?? ""}',
              style: const TextStyle(fontFamily: DotTokens.dotFamily),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _takeScreenshot() async {
    final rec = ref.read(recordingServiceProvider);
    final dummyPng = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
    final path = await rec.saveScreenshot(dummyPng);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Снимок экрана сохранён: $path',
            style: const TextStyle(fontFamily: DotTokens.dotFamily),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _requestKeyframe() {
    ref.read(linkClientProvider).requestKeyframe();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ключевой кадр (IDR) запрошен',
          style: TextStyle(fontFamily: DotTokens.dotFamily),
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _triggerConsent() {
    ref.read(linkClientProvider).triggerConsent();
  }

  void _sendHome() {
    final dev = ref.read(selectedDeviceProvider);
    if (dev != null) {
      ref.read(adbServiceProvider).sendHome(dev.serial);
    }
  }

  void _sendBack() {
    final dev = ref.read(selectedDeviceProvider);
    if (dev != null) {
      ref.read(adbServiceProvider).sendBack(dev.serial);
    }
  }

  void _sendRecents() {
    final dev = ref.read(selectedDeviceProvider);
    if (dev != null) {
      ref.read(adbServiceProvider).sendRecents(dev.serial);
    }
  }

  void _togglePhoneScreen() {
    final dev = ref.read(selectedDeviceProvider);
    if (dev != null) {
      ref.read(adbServiceProvider).sendPower(dev.serial);
      setState(() => _phoneScreenOff = !_phoneScreenOff);
    }
  }

  void _rotate90() {
    setState(() => _rotationQuarter = (_rotationQuarter + 1) % 4);
  }

  void _toggleScale() {
    setState(() => _fitMode = !_fitMode);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
  }

  void _openRecordingsFolder() {
    final settings = ref.read(appSettingsProvider);
    final path = Directory(settings.recordingsPath).absolute.path;
    if (Platform.isWindows) {
      Process.run('explorer.exe', [path]);
    }
  }

  void _copyObsUrl() {
    final server = ref.read(browserSourceServerProvider);
    Clipboard.setData(ClipboardData(text: server.url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ссылка OBS скопирована: ${server.url}',
          style: const TextStyle(fontFamily: DotTokens.dotFamily),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(linkStatsProvider);
    final statusAsync = ref.watch(linkStatusProvider);

    final stats = statsAsync.value ?? const LinkStats();
    final status = statusAsync.value ?? LinkClientStatus.connecting;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyS &&
              HardwareKeyboard.instance.isControlPressed &&
              HardwareKeyboard.instance.isShiftPressed) {
            _takeScreenshot();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyR &&
              HardwareKeyboard.instance.isControlPressed &&
              HardwareKeyboard.instance.isShiftPressed) {
            _toggleRecording();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyK &&
              HardwareKeyboard.instance.isControlPressed) {
            _requestKeyframe();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.f10) {
            setState(() => _isBorderless = !_isBorderless);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: MouseRegion(
          onHover: (_) => _onPointerHover(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Mirror Viewport
              Center(
                child: RotatedBox(
                  quarterTurns: _rotationQuarter,
                  child: AspectRatio(
                    aspectRatio: stats.aspectRatio,
                    child: Container(
                      color: const Color(0xFF0A0A0A),
                      child: status == LinkClientStatus.streaming
                          ? _buildStreamingViewport()
                          : _buildStatusPlaceholder(status),
                    ),
                  ),
                ),
              ),

              // Android 14+ Consent Prompt Overlay
              if (_showConsentNotice)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(DotTokens.xl),
                    margin: const EdgeInsets.all(DotTokens.xl),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(DotTokens.radiusCard),
                      border: Border.all(
                        color: const Color(0xFF8C8C8C),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          DotLinkIcons.phone,
                          width: 44,
                          height: 44,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: DotTokens.md),
                        const Text(
                          'Подтвердите трансляцию на телефоне',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: DotTokens.sm),
                        const Text(
                          'На Android 14+ требуется явное согласие пользователя перед началом захвата экрана.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8C8C8C),
                          ),
                        ),
                        const SizedBox(height: DotTokens.lg),
                        ElevatedButton(
                          onPressed: _triggerConsent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DotTokens.radiusButton,
                              ),
                            ),
                          ),
                          child: const Text('Открыть запрос на телефоне'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Top HUD Overlay
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _isHovering || _isRecording ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status & Stats Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(
                            DotTokens.radiusChip,
                          ),
                          border: Border.all(
                            color: const Color(0xFF2B2B2B),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Shape-based indicator: red for rec, white circle for live, empty ring for wait
                            Container(
                              width: 8,
                              height: 8,
                              decoration: _isRecording
                                  ? const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: DotTokens.accentRed,
                                    )
                                  : (status == LinkClientStatus.streaming
                                      ? const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        )
                                      : BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF8C8C8C),
                                            width: 1.5,
                                          ),
                                          color: Colors.transparent,
                                        )),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isRecording
                                  ? 'REC'
                                  : (status == LinkClientStatus.streaming
                                      ? 'В ЭФИРЕ'
                                      : 'ПОДКЛЮЧЕНИЕ'),
                              style: TextStyle(
                                fontFamily: DotTokens.dotFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isRecording
                                    ? DotTokens.accentRed
                                    : Colors.white,
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final settings = ref.watch(appSettingsProvider);
                                final parts = <String>[];
                                if (settings.showFpsOverlay) {
                                  parts.add('${stats.fps.toInt()} FPS');
                                }
                                if (settings.showLatencyOverlay) {
                                  parts.add('${stats.latencyMs} МС');
                                }
                                if (settings.showBitrateOverlay) {
                                  parts.add('${stats.bitrateMbps} МБИТ/С');
                                }
                                if (parts.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final hasDroppedFrames = stats.droppedFrames > 0;
                                return Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    Text(
                                      parts.join('  ·  '),
                                      style: TextStyle(
                                        fontFamily: DotTokens.dotFamily,
                                        fontSize: 13,
                                        color: const Color(0xFF8C8C8C),
                                        decoration: hasDroppedFrames
                                            ? TextDecoration.underline
                                            : TextDecoration.none,
                                        decorationColor:
                                            const Color(0xFF8C8C8C),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Timer & Window Controls
                      Row(
                        children: [
                          if (_isRecording)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: DotTokens.accentRed.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(
                                  DotTokens.radiusChip,
                                ),
                                border: Border.all(
                                  color: DotTokens.accentRed,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _formatDuration(_recordSeconds),
                                style: const TextStyle(
                                  fontFamily: DotTokens.dotFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: DotTokens.accentRed,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          DotIconButton(
                            asset: DotLinkIcons.close,
                            tooltip: 'Закрыть окно (Esc)',
                            color: Colors.white,
                            size: 36,
                            iconSize: 18,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Control Bar (Hover overlay, pill shape radius 999, border 0.5)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _isHovering ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(
                          DotTokens.radiusToolbar,
                        ),
                        border: Border.all(
                          color: const Color(0xFF2B2B2B),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. ЗАПИСЬ / СТОП
                            DotToolbarAction(
                              asset: _isRecording
                                  ? DotLinkIcons.stop
                                  : DotLinkIcons.record,
                              label: _isRecording ? 'СТОП' : 'ЗАПИСЬ',
                              tooltip: _isRecording
                                  ? 'Остановить запись на ПК (Ctrl+Shift+R)'
                                  : 'Запись на ПК (Ctrl+Shift+R)',
                              isActive: _isRecording,
                              isDestructive: _isRecording,
                              onPressed: _toggleRecording,
                            ),
                            const SizedBox(width: 4),

                            // 2. СНИМОК
                            DotToolbarAction(
                              asset: DotLinkIcons.screenshot,
                              label: 'СНИМОК',
                              tooltip: 'Сохранить снимок экрана (Ctrl+Shift+S)',
                              onPressed: _takeScreenshot,
                            ),
                            const SizedBox(width: 4),

                            // 3. IDR КАДР
                            DotToolbarAction(
                              asset: DotLinkIcons.keyframe,
                              label: 'IDR',
                              tooltip: 'Запросить ключевой кадр (Ctrl+K)',
                              onPressed: _requestKeyframe,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 28,
                              color: const Color(0xFF2B2B2B),
                            ),
                            const SizedBox(width: 8),

                            // 4. НАЗАД (телефон)
                            DotToolbarAction(
                              asset: DotLinkIcons.chevronLeft,
                              label: 'НАЗАД',
                              tooltip: 'Кнопка «Назад» на телефоне',
                              onPressed: _sendBack,
                            ),
                            const SizedBox(width: 4),

                            // 5. ДОМОЙ (телефон)
                            DotToolbarAction(
                              asset: DotLinkIcons.home,
                              label: 'ДОМОЙ',
                              tooltip: 'Кнопка «Домой» на телефоне',
                              onPressed: _sendHome,
                            ),
                            const SizedBox(width: 4),

                            // 6. ОКНА (недавние)
                            DotToolbarAction(
                              asset: DotLinkIcons.recents,
                              label: 'ОКНА',
                              tooltip: 'Недавние приложения на телефоне',
                              onPressed: _sendRecents,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 28,
                              color: const Color(0xFF2B2B2B),
                            ),
                            const SizedBox(width: 8),

                            // 7. 90° ПОВОРОТ
                            DotToolbarAction(
                              asset: DotLinkIcons.rotate,
                              label: '90°',
                              tooltip: 'Повернуть экран на 90 градусов',
                              onPressed: _rotate90,
                            ),
                            const SizedBox(width: 4),

                            // 8. МАСШТАБ
                            DotToolbarAction(
                              asset: DotLinkIcons.scale,
                              label: 'МАСШТАБ',
                              tooltip:
                                  _fitMode ? 'Масштаб 1:1' : 'Вписать в окно',
                              isActive: !_fitMode,
                              onPressed: _toggleScale,
                            ),
                            const SizedBox(width: 4),

                            // 9. ЭКРАН ТЕЛЕФОНА
                            DotToolbarAction(
                              asset: _phoneScreenOff
                                  ? DotLinkIcons.power
                                  : DotLinkIcons.screenOff,
                              label: 'ЭКРАН',
                              tooltip: _phoneScreenOff
                                  ? 'Включить экран телефона'
                                  : 'Погасить экран телефона (энергосбережение)',
                              isActive: _phoneScreenOff,
                              onPressed: _togglePhoneScreen,
                            ),
                            const SizedBox(width: 4),

                            // 10. ЗВУК
                            DotToolbarAction(
                              asset: _isMuted
                                  ? DotLinkIcons.volumeOff
                                  : DotLinkIcons.volume,
                              label: 'ЗВУК',
                              tooltip: _isMuted
                                  ? 'Включить звук'
                                  : 'Выключить звук',
                              isActive: _isMuted,
                              onPressed: _toggleMute,
                            ),
                            const SizedBox(width: 4),

                            // 11. ПАПКА
                            DotToolbarAction(
                              asset: DotLinkIcons.folder,
                              label: 'ПАПКА',
                              tooltip: 'Открыть папку записей',
                              onPressed: _openRecordingsFolder,
                            ),
                            const SizedBox(width: 4),

                            // 12. OBS
                            DotToolbarAction(
                              asset: DotLinkIcons.obs,
                              label: 'OBS',
                              tooltip:
                                  'Скопировать ссылку для Browser Source OBS',
                              onPressed: _copyObsUrl,
                            ),
                            const SizedBox(width: 4),

                            // 13. ПОЛНЫЙ ЭКРАН / ОКНО
                            DotToolbarAction(
                              asset: _isBorderless
                                  ? DotLinkIcons.fullscreenExit
                                  : DotLinkIcons.fullscreen,
                              label: _isBorderless ? 'ОКНО' : 'ЭКРАН',
                              tooltip: 'Безрамочный режим (F10)',
                              isActive: _isBorderless,
                              onPressed: () {
                                setState(() => _isBorderless = !_isBorderless);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamingViewport() {
    return Stack(
      fit: fitBox(),
      children: [
        Container(
          decoration: const BoxDecoration(color: Color(0xFF101010)),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  DotLinkIcons.mirror,
                  width: 48,
                  height: 48,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Трансляция активна',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Получено кадров: $_frameCount',
                  style: const TextStyle(
                    fontFamily: DotTokens.dotFamily,
                    color: Color(0xFF8C8C8C),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  StackFit fitBox() => StackFit.expand;

  Widget _buildStatusPlaceholder(LinkClientStatus status) {
    String msg;
    Widget icon;

    switch (status) {
      case LinkClientStatus.connecting:
        msg = 'Подключение к 127.0.0.1:${LinkClient.port}...';
        icon = const CircularProgressIndicator(color: Colors.white);
        break;
      case LinkClientStatus.handshake:
        msg = 'Рукопожатие и согласование протокола...';
        icon = const CircularProgressIndicator(color: Colors.white);
        break;
      case LinkClientStatus.error:
        msg = 'Ошибка подключения к устройству';
        icon = SvgPicture.asset(
          DotLinkIcons.alert,
          width: 48,
          height: 48,
          colorFilter: const ColorFilter.mode(
            DotTokens.accentRed,
            BlendMode.srcIn,
          ),
        );
        break;
      case LinkClientStatus.disconnected:
      default:
        msg = 'Поток отключен';
        icon = SvgPicture.asset(
          DotLinkIcons.video,
          width: 48,
          height: 48,
          colorFilter: const ColorFilter.mode(
            Color(0xFF8C8C8C),
            BlendMode.srcIn,
          ),
        );
        break;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
