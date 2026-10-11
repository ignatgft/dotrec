import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/link_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_card.dart';
import '../../core/widgets/dot_segmented.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final adb = ref.watch(adbServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DotTokens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Appearance Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Оформление',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DotTokens.md),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
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
                        selected: themeMode,
                        labelOf: (m) =>
                            m == ThemeMode.dark ? 'Тёмная' : 'Светлая',
                        onSelected: (m) {
                          ref.read(themeModeProvider.notifier).state = m;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: DotTokens.lg),

          // ADB & System Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Система и ADB',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DotTokens.md),
                Text(
                  'Путь к исполняемому файлу ADB:',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.dot.fgMuted,
                  ),
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

          const SizedBox(height: DotTokens.lg),

          // Hotkeys reference Card
          DotCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Горячие клавиши',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: DotTokens.md),
                _buildHotkeyRow(
                  context,
                  keyCombination: 'Ctrl + Shift + M',
                  description: 'Открыть окно зеркалирования',
                ),
                Divider(color: context.dot.line, height: DotTokens.lg),
                _buildHotkeyRow(
                  context,
                  keyCombination: 'Ctrl + Shift + S',
                  description: 'Сохранить снимок экрана',
                ),
                Divider(color: context.dot.line, height: DotTokens.lg),
                _buildHotkeyRow(
                  context,
                  keyCombination: 'Ctrl + Shift + R',
                  description: 'Старт/стоп записи потока на ПК',
                ),
                Divider(color: context.dot.line, height: DotTokens.lg),
                _buildHotkeyRow(
                  context,
                  keyCombination: 'Ctrl + K',
                  description: 'Принудительный запрос ключевого кадра (IDR)',
                ),
                Divider(color: context.dot.line, height: DotTokens.lg),
                _buildHotkeyRow(
                  context,
                  keyCombination: 'F10 / Esc',
                  description: 'Безрамочный режим / Выход из зеркала',
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
        Text(
          description,
          style: const TextStyle(fontSize: 13),
        ),
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
