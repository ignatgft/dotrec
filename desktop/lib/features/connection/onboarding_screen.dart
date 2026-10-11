import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/device_info.dart';
import '../../core/providers/link_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_card.dart';
import '../../core/widgets/dot_segmented.dart';

enum ConnectionMode {
  usb('USB-кабель'),
  wifi('Wi-Fi сеть');

  const ConnectionMode(this.label);
  final String label;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  ConnectionMode _mode = ConnectionMode.usb;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _ipController =
      TextEditingController(text: '192.168.1.');
  bool _isConnectingWifi = false;
  String? _wifiError;

  @override
  void dispose() {
    _pinController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _refreshAdb() async {
    final adb = ref.read(adbServiceProvider);
    await adb.getDevices();
  }

  Future<void> _launchAppOnPhone(String serial) async {
    final adb = ref.read(adbServiceProvider);
    await adb.launchDotRec(serial);
  }

  Future<void> _connectWifi() async {
    final pin = _pinController.text.trim();
    final ip = _ipController.text.trim();
    if (pin.length != 6) {
      setState(() => _wifiError = 'Введите 6-значный PIN-код с экрана телефона');
      return;
    }
    setState(() {
      _isConnectingWifi = true;
      _wifiError = null;
    });

    final client = ref.read(linkClientProvider);
    final ok = await client.connect(
      host: ip,
      pin: pin,
    );

    if (mounted) {
      setState(() {
        _isConnectingWifi = false;
        if (!ok) {
          _wifiError = 'Не удалось подключиться к $ip:$pin. Проверьте сеть и PIN.';
        }
      });
      if (ok) {
        ref.read(activeTabProvider.notifier).state = DesktopTab.mirror;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(selectedDeviceProvider);
    final isDeviceReady = device?.isReady ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DotTokens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode switch
          DotSegmented<ConnectionMode>(
            values: ConnectionMode.values,
            selected: _mode,
            labelOf: (m) => m.label,
            onSelected: (m) => setState(() => _mode = m),
          ),

          const SizedBox(height: DotTokens.xl),

          if (_mode == ConnectionMode.usb) ...[
            // Status Grid
            Row(
              children: [
                Expanded(
                  child: DotCard(
                    padding: const EdgeInsets.all(DotTokens.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Кабель',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.dot.fgMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              device != null
                                  ? Icons.check_circle_outline
                                  : Icons.highlight_off,
                              size: 16,
                              color: device != null
                                  ? const Color(0xFF00C853)
                                  : context.dot.fgMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              device != null ? 'Подключен' : 'Не найден',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: DotTokens.md),
                Expanded(
                  child: DotCard(
                    padding: const EdgeInsets.all(DotTokens.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Статус ADB',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.dot.fgMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isDeviceReady
                                  ? Icons.verified_user_outlined
                                  : (device != null
                                      ? Icons.warning_amber_outlined
                                      : Icons.remove_circle_outline),
                              size: 16,
                              color: isDeviceReady
                                  ? const Color(0xFF00C853)
                                  : (device != null
                                      ? const Color(0xFFFFB300)
                                      : context.dot.fgMuted),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              device != null
                                  ? (device.state == AdbState.ready
                                      ? 'Авторизован'
                                      : (device.state == AdbState.unauthorized
                                          ? 'Unauthorized'
                                          : 'Offline'))
                                  : 'Ожидание',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: DotTokens.md),
                Expanded(
                  child: DotCard(
                    padding: const EdgeInsets.all(DotTokens.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DotRec на телефоне',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.dot.fgMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isDeviceReady
                                  ? Icons.smartphone
                                  : Icons.phonelink_erase,
                              size: 16,
                              color: isDeviceReady
                                  ? const Color(0xFF00C853)
                                  : context.dot.fgMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isDeviceReady ? 'Готов к передаче' : 'Ожидание',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: DotTokens.xl),

            // Step 1
            _buildStepCard(
              context,
              step: '1',
              title: 'Включите отладку по USB на телефоне',
              body:
                  'Настройки → О телефоне → нажимайте на «Номер сборки» 7 раз. Затем перейдите в Настройки → Для разработчиков и включите переключатель «Отладка по USB».',
              done: isDeviceReady,
            ),

            const SizedBox(height: DotTokens.md),

            // Step 2
            _buildStepCard(
              context,
              step: '2',
              title: 'Подключите телефон кабелем USB-C',
              body:
                  'Используйте качественный кабель передачи данных. В появившейся шторке на телефоне выберите режим подключения «Передача файлов» (MTP) вместо «Только зарядка».',
              done: device != null,
            ),

            const SizedBox(height: DotTokens.md),

            // Step 3
            _buildStepCard(
              context,
              step: '3',
              title: 'Разрешите отладку с этого компьютера',
              body:
                  'На телефоне появится системный запрос «Разрешить отладку по USB?». Обязательно отметьте флажок «Всегда разрешать с этого компьютера» и нажмите «ОК».',
              done: isDeviceReady,
              warning: device?.state == AdbState.unauthorized
                  ? 'Внимание: телефон подключен, но не авторизован! Подтвердите запрос на экране смартфона.'
                  : null,
            ),

            const SizedBox(height: DotTokens.xl),

            // Action row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _refreshAdb,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Обновить список устройств'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: context.dot.fg,
                      side: BorderSide(color: context.dot.line),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DotTokens.radiusButton),
                      ),
                    ),
                  ),
                ),
                if (device != null && isDeviceReady) ...[
                  const SizedBox(width: DotTokens.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchAppOnPhone(device.serial),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Запустить DotRec на телефоне'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
              ],
            ),
          ] else ...[
            // Wi-Fi Connection Card
            DotCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Сопряжение по Wi-Fi (PIN-код)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: DotTokens.sm),
                  Text(
                    'Убедитесь, что ПК и смартфон подключены к одной локальной Wi-Fi сети. В приложении DotRec на телефоне выберите «Передача на ПК» → «Wi-Fi» и введите отображаемый 6-значный код.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.dot.fgMuted,
                    ),
                  ),
                  const SizedBox(height: DotTokens.lg),

                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'IP-адрес телефона в локальной сети',
                      hintText: '192.168.1.100',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DotTokens.radiusChip),
                      ),
                    ),
                  ),

                  const SizedBox(height: DotTokens.md),

                  TextField(
                    controller: _pinController,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: DotTokens.dotFamily,
                      fontSize: 24,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      labelText: '6-значный PIN-код сопряжения (живёт 2 мин)',
                      hintText: '123456',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DotTokens.radiusChip),
                      ),
                    ),
                  ),

                  if (_wifiError != null) ...[
                    const SizedBox(height: DotTokens.sm),
                    Text(
                      _wifiError!,
                      style: const TextStyle(
                        color: DotTokens.accentRed,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  const SizedBox(height: DotTokens.lg),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isConnectingWifi ? null : _connectWifi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.dot.fg,
                        foregroundColor: context.dot.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DotTokens.radiusButton),
                        ),
                      ),
                      child: _isConnectingWifi
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Подключиться по Wi-Fi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String step,
    required String title,
    required String body,
    required bool done,
    String? warning,
  }) {
    return DotCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? const Color(0xFF00C853)
                      : context.dot.surfaceRaised,
                ),
                alignment: Alignment.center,
                child: Text(
                  done ? '✓' : step,
                  style: TextStyle(
                    fontFamily: DotTokens.dotFamily,
                    fontWeight: FontWeight.bold,
                    color: done ? Colors.white : context.dot.fg,
                  ),
                ),
              ),
              const SizedBox(width: DotTokens.md),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DotTokens.sm),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.dot.fgMuted,
                    height: 1.4,
                  ),
                ),
                if (warning != null) ...[
                  const SizedBox(height: DotTokens.sm),
                  Container(
                    padding: const EdgeInsets.all(DotTokens.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(DotTokens.radiusChip),
                      border: Border.all(
                        color: const Color(0xFFFFB300),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      warning,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFFB300),
                        fontWeight: FontWeight.w600,
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
