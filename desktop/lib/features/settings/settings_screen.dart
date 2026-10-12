import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/dot_link_icons.dart';
import '../../core/providers/link_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_card.dart';
import '../../core/widgets/dot_segmented.dart';
import '../../core/widgets/dot_switch.dart';
import '../../services/hotkey_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    final adb = ref.watch(adbServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DotTokens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Appearance & Mirror HUD Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Оформление и оверлей зеркала',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DotTokens.md),
                Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(
                        'Тема интерфейса',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.dot.fgMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: DotSegmented<ThemeMode>(
                        values: const [ThemeMode.dark, ThemeMode.light],
                        selected: settings.themeMode,
                        labelOf: (m) =>
                            m == ThemeMode.dark ? 'Тёмная' : 'Светлая',
                        onSelected: (m) {
                          settingsNotifier.setThemeMode(m);
                          ref.read(themeModeProvider.notifier).state = m;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DotTokens.md),
                Divider(color: context.dot.line),
                const SizedBox(height: DotTokens.sm),
                DotSwitch(
                  label: 'Отображать счетчик FPS',
                  subtitle: 'Показывать текущую частоту кадров в HUD зеркала',
                  value: settings.showFpsOverlay,
                  onChanged: (v) =>
                      settingsNotifier.setOverlayVisibility(fps: v),
                ),
                const SizedBox(height: DotTokens.sm),
                DotSwitch(
                  label: 'Отображать задержку (мс)',
                  subtitle: 'Расчет задержки от кадра на телефоне до рендера',
                  value: settings.showLatencyOverlay,
                  onChanged: (v) =>
                      settingsNotifier.setOverlayVisibility(latency: v),
                ),
                const SizedBox(height: DotTokens.sm),
                DotSwitch(
                  label: 'Отображать битрейт (Мбит/с)',
                  subtitle: 'Скорость входящего видеопотока в реальном времени',
                  value: settings.showBitrateOverlay,
                  onChanged: (v) =>
                      settingsNotifier.setOverlayVisibility(bitrate: v),
                ),
              ],
            ),
          ),

          const SizedBox(height: DotTokens.lg),

          // 2. System Tray & Startup Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Системный трей и автозапуск',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DotTokens.md),
                DotSwitch(
                  label: 'Сворачивать в трей при закрытии',
                  subtitle: 'При нажатии на крестик окно сворачивается в область уведомлений',
                  value: settings.minimizeToTray,
                  onChanged: settingsNotifier.setMinimizeToTray,
                ),
                const SizedBox(height: DotTokens.sm),
                DotSwitch(
                  label: 'Уведомления в трее',
                  subtitle:
                      'Оповещать о подключении, обрыве и сохранении файлов',
                  value: settings.trayNotifications,
                  onChanged: settingsNotifier.setTrayNotifications,
                ),
                const SizedBox(height: DotTokens.sm),
                DotSwitch(
                  label: 'Автозапуск при старте Windows',
                  subtitle: 'Запускать DotRec Link в фоновом режиме при входе в систему',
                  value: settings.launchOnStartup,
                  onChanged: settingsNotifier.setLaunchOnStartup,
                ),
              ],
            ),
          ),

          const SizedBox(height: DotTokens.lg),

          // 3. Streaming & Network Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Потоковая передача и сеть',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DotTokens.md),
                DotSwitch(
                  label: 'Режим минимальной задержки',
                  subtitle:
                      'Сброс очереди кадров для получения задержки менее 35 мс',
                  value: settings.lowLatencyBuffer,
                  onChanged: (v) {
                    settingsNotifier.update(
                      (s) => s.copyWith(lowLatencyBuffer: v),
                    );
                  },
                ),
                const SizedBox(height: DotTokens.sm),
                DotSwitch(
                  label: 'Аппаратное ускорение декодирования',
                  subtitle: 'Использовать GPU Direct3D11VA / внешнюю текстуру',
                  value: settings.hardwareAcceleration,
                  onChanged: (v) {
                    settingsNotifier.update(
                      (s) => s.copyWith(hardwareAcceleration: v),
                    );
                  },
                ),
                const SizedBox(height: DotTokens.sm),
                DotSwitch(
                  label: 'Автопереподключение к телефону',
                  subtitle: 'Автоматически восстанавливать связь при переподключении USB',
                  value: settings.autoReconnect,
                  onChanged: settingsNotifier.setAutoReconnect,
                ),
                const SizedBox(height: DotTokens.md),
                Divider(color: context.dot.line),
                const SizedBox(height: DotTokens.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Порт сервера DotRec Link (TCP):',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.dot.fgMuted,
                      ),
                    ),
                    Text(
                      '${settings.linkServerPort}',
                      style: const TextStyle(
                        fontFamily: DotTokens.dotFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DotTokens.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Порт сервера Browser Source (HTTP/WS):',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.dot.fgMuted,
                      ),
                    ),
                    Text(
                      '${settings.browserSourcePort}',
                      style: const TextStyle(
                        fontFamily: DotTokens.dotFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: DotTokens.lg),

          // 4. Recording & Storage Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Запись и хранение',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DotTokens.md),
                Text(
                  'Папка сохранения видео:',
                  style: TextStyle(fontSize: 13, color: context.dot.fgMuted),
                ),
                const SizedBox(height: DotTokens.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.dot.surfaceRaised,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.dot.line),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        DotLinkIcons.folder,
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          context.dot.fg,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        settings.recordingsPath,
                        style: const TextStyle(
                          fontFamily: DotTokens.dotFamily,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DotTokens.md),
                Text(
                  'Папка сохранения снимков экрана:',
                  style: TextStyle(fontSize: 13, color: context.dot.fgMuted),
                ),
                const SizedBox(height: DotTokens.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.dot.surfaceRaised,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.dot.line),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        DotLinkIcons.screenshot,
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          context.dot.fg,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        settings.screenshotsPath,
                        style: const TextStyle(
                          fontFamily: DotTokens.dotFamily,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: DotTokens.lg),

          // 5. Hotkeys Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Горячие клавиши',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DotTokens.md),
                ...HotkeyAction.values.map((action) {
                  return Column(
                    children: [
                      _buildHotkeyRow(
                        context,
                        keyCombination: action.defaultShortcut,
                        description: action.description,
                      ),
                      if (action != HotkeyAction.values.last)
                        Divider(color: context.dot.line, height: DotTokens.lg),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: DotTokens.lg),

          // 6. ADB & System Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Система и ADB',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        settingsNotifier.resetToDefaults();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Настройки сброшены по умолчанию'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text('Сбросить по умолчанию'),
                    ),
                  ],
                ),
                const SizedBox(height: DotTokens.md),
                Text(
                  'Путь к исполняемому файлу ADB:',
                  style: TextStyle(fontSize: 13, color: context.dot.fgMuted),
                ),
                const SizedBox(height: DotTokens.xs),
                Text(
                  adb.adbPath,
                  style: const TextStyle(
                    fontFamily: DotTokens.dotFamily,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotkeyRow(
    BuildContext context, {
    required String keyCombination,
    required String description,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(description, style: const TextStyle(fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: context.dot.surfaceRaised,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.dot.line),
          ),
          child: Text(
            keyCombination,
            style: const TextStyle(
              fontFamily: DotTokens.dotFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
