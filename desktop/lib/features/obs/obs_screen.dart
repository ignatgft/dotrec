import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/dot_link_icons.dart';
import '../../core/providers/link_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_card.dart';
import '../../services/obs_service.dart';

class ObsScreen extends ConsumerStatefulWidget {
  const ObsScreen({super.key});

  @override
  ConsumerState<ObsScreen> createState() => _ObsScreenState();
}

class _ObsScreenState extends ConsumerState<ObsScreen> {
  final TextEditingController _obsPortController = TextEditingController(
    text: '4455',
  );
  final TextEditingController _obsPasswordController = TextEditingController(
    text: '',
  );
  bool _isConnecting = false;

  @override
  void dispose() {
    _obsPortController.dispose();
    _obsPasswordController.dispose();
    super.dispose();
  }

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'URL источника скопирован в буфер обмена',
          style: TextStyle(fontFamily: DotTokens.dotFamily),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleObsConnection() async {
    final obs = ref.read(obsServiceProvider);
    if (obs.status == ObsStatus.connected) {
      obs.disconnect();
      return;
    }

    setState(() => _isConnecting = true);
    final port = int.tryParse(_obsPortController.text.trim()) ?? 4455;
    final password = _obsPasswordController.text;

    final ok = await obs.connect(port: port, password: password);

    if (mounted) {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Успешное подключение к OBS Studio (v5 API)'
                : 'Не удалось подключиться к OBS (проверьте порт и пароль)',
            style: const TextStyle(fontFamily: DotTokens.dotFamily),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _addSourceToObs(String url) async {
    final obs = ref.read(obsServiceProvider);
    if (obs.status != ObsStatus.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Сначала подключитесь к OBS WebSocket',
            style: TextStyle(fontFamily: DotTokens.dotFamily),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final ok = await obs.addBrowserSource(url: url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Источник «DotRec Screen» добавлен в сцену «${obs.currentScene}»'
                : 'Не удалось создать источник в OBS Studio',
            style: const TextStyle(fontFamily: DotTokens.dotFamily),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _toggleObsRecord() async {
    final obs = ref.read(obsServiceProvider);
    if (obs.status != ObsStatus.connected) return;
    await obs.toggleRecord();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Запись в OBS Studio переключена',
            style: TextStyle(fontFamily: DotTokens.dotFamily),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final browserServer = ref.watch(browserSourceServerProvider);
    final obsStatusAsync = ref.watch(obsStatusProvider);
    final obs = ref.watch(obsServiceProvider);
    final obsStatus = obsStatusAsync.value ?? obs.status;
    final isConnected = obsStatus == ObsStatus.connected;

    final sourceUrl = browserServer.url.isNotEmpty
        ? browserServer.url
        : 'http://127.0.0.1:48212/?token=generating...';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DotTokens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Browser Source Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      DotLinkIcons.obs,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        context.dot.fg,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: DotTokens.sm),
                    const Text(
                      'Browser Source (Локальный сервер)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DotTokens.sm),
                Text(
                  'Вставьте данный адрес в источник «Браузер» в OBS Studio. Видео транслируется аппаратно через WebCodecs без потери качества и с минимальной задержкой (~30 мс).',
                  style: TextStyle(fontSize: 13, color: context.dot.fgMuted),
                ),
                const SizedBox(height: DotTokens.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.dot.surfaceRaised,
                    borderRadius: BorderRadius.circular(DotTokens.radiusChip),
                    border: Border.all(color: context.dot.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          sourceUrl,
                          style: const TextStyle(
                            fontFamily: DotTokens.dotFamily,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: SvgPicture.asset(
                          DotLinkIcons.copy,
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(
                            context.dot.fg,
                            BlendMode.srcIn,
                          ),
                        ),
                        tooltip: 'Скопировать URL',
                        onPressed: () => _copyUrl(sourceUrl),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: DotTokens.xl),

          // obs-websocket Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          DotLinkIcons.settings,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            context.dot.fg,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: DotTokens.sm),
                        const Text(
                          'obs-websocket (v5 API)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.dot.surfaceRaised,
                        borderRadius: BorderRadius.circular(
                          DotTokens.radiusChip,
                        ),
                        border: Border.all(color: context.dot.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: isConnected
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.dot.fg,
                                  )
                                : (obsStatus == ObsStatus.connecting
                                      ? BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: context.dot.fg,
                                            width: 1.5,
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
                          const SizedBox(width: 8),
                          Text(
                            isConnected
                                ? 'Подключено · ${obs.currentScene}'
                                : (obsStatus == ObsStatus.connecting
                                      ? 'Подключение...'
                                      : 'Отключено'),
                            style: TextStyle(
                              fontFamily: DotTokens.dotFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isConnected
                                  ? context.dot.fg
                                  : context.dot.fgMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DotTokens.sm),
                Text(
                  'Прямое управление OBS Studio: автоматическое добавление источника в активную сцену, переключение сцен и старт записи.',
                  style: TextStyle(fontSize: 13, color: context.dot.fgMuted),
                ),
                const SizedBox(height: DotTokens.lg),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _obsPortController,
                        decoration: InputDecoration(
                          labelText: 'Порт WebSocket',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DotTokens.radiusChip,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: DotTokens.md),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _obsPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Пароль сервера OBS (если задан)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DotTokens.radiusChip,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DotTokens.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isConnecting ? null : _toggleObsConnection,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: context.dot.fg,
                          side: BorderSide(color: context.dot.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DotTokens.radiusButton,
                            ),
                          ),
                        ),
                        child: _isConnecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isConnected
                                    ? 'Отключить OBS'
                                    : 'Подключить OBS WebSocket',
                              ),
                      ),
                    ),
                    const SizedBox(width: DotTokens.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _addSourceToObs(sourceUrl),
                        icon: SvgPicture.asset(
                          DotLinkIcons.open,
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(
                            context.dot.bg,
                            BlendMode.srcIn,
                          ),
                        ),
                        label: const Text('Добавить в OBS в 1 клик'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: context.dot.fg,
                          foregroundColor: context.dot.bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DotTokens.radiusButton,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (isConnected) ...[
                  const SizedBox(height: DotTokens.md),
                  OutlinedButton.icon(
                    onPressed: _toggleObsRecord,
                    icon: SvgPicture.asset(
                      DotLinkIcons.record,
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        DotTokens.accentRed,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: const Text('Переключить запись в OBS Studio'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: context.dot.fg,
                      side: BorderSide(color: context.dot.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DotTokens.radiusButton,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
