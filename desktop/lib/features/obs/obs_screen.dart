import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_card.dart';

class ObsScreen extends ConsumerStatefulWidget {
  const ObsScreen({super.key});

  @override
  ConsumerState<ObsScreen> createState() => _ObsScreenState();
}

class _ObsScreenState extends ConsumerState<ObsScreen> {
  final String _browserSourceUrl = 'http://127.0.0.1:48212/?token=dotrec_sec_9941a';
  bool _isObsConnected = false;
  final TextEditingController _obsPortController =
      TextEditingController(text: '4455');
  final TextEditingController _obsPasswordController =
      TextEditingController(text: '••••••••');

  @override
  void dispose() {
    _obsPortController.dispose();
    _obsPasswordController.dispose();
    super.dispose();
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _browserSourceUrl));
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

  void _addSourceToObs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Источник «DotRec Screen» добавлен в текущую сцену OBS Studio',
          style: TextStyle(fontFamily: DotTokens.dotFamily),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                const Row(
                  children: [
                    Icon(Icons.language, size: 20),
                    SizedBox(width: DotTokens.sm),
                    Text(
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
                  'Вставьте данный адрес в источник «Браузер» в OBS Studio. Видео транслируется аппаратно через WebCodecs без потери качества и с задержкой до 35 мс.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.dot.fgMuted,
                  ),
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
                          _browserSourceUrl,
                          style: const TextStyle(
                            fontFamily: DotTokens.dotFamily,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Скопировать URL',
                        onPressed: _copyUrl,
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
                    const Row(
                      children: [
                        Icon(Icons.settings_input_component, size: 20),
                        SizedBox(width: DotTokens.sm),
                        Text(
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
                        color: _isObsConnected
                            ? const Color(0xFF00C853).withValues(alpha: 0.15)
                            : context.dot.surfaceRaised,
                        borderRadius:
                            BorderRadius.circular(DotTokens.radiusChip),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isObsConnected
                                  ? const Color(0xFF00C853)
                                  : context.dot.fgMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isObsConnected ? 'Подключено' : 'Отключено',
                            style: TextStyle(
                              fontFamily: DotTokens.dotFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isObsConnected
                                  ? const Color(0xFF00C853)
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
                  'Прямое управление OBS Studio: автоматическое добавление источника, переключение сцен и старт записи.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.dot.fgMuted,
                  ),
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
                            borderRadius:
                                BorderRadius.circular(DotTokens.radiusChip),
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
                          labelText: 'Пароль сервера OBS',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(DotTokens.radiusChip),
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
                        onPressed: () {
                          setState(() => _isObsConnected = !_isObsConnected);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: context.dot.fg,
                          side: BorderSide(color: context.dot.line),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(DotTokens.radiusButton),
                          ),
                        ),
                        child: Text(
                          _isObsConnected
                              ? 'Отключить OBS'
                              : 'Подключить OBS WebSocket',
                        ),
                      ),
                    ),
                    const SizedBox(width: DotTokens.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _addSourceToObs,
                        icon: const Icon(Icons.add_to_queue, size: 18),
                        label: const Text('Добавить в OBS в 1 клик'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: context.dot.fg,
                          foregroundColor: context.dot.bg,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(DotTokens.radiusButton),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
