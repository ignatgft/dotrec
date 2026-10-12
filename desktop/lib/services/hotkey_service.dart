import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Действия горячих клавиш в десктоп-клиенте.
enum HotkeyAction {
  toggleMirror('Открыть/закрыть окно зеркала', 'Ctrl + Shift + M'),
  toggleRecording('Старт/стоп записи потока на ПК', 'Ctrl + Shift + R'),
  captureScreenshot('Сохранить снимок экрана', 'Ctrl + Shift + S'),
  requestKeyframe('Запрос ключевого кадра (IDR)', 'Ctrl + K'),
  openSettings('Перейти в настройки', 'Ctrl + ,'),
  toggleFrameless('Безрамочный режим зеркала', 'F10'),
  closeWindow('Закрыть окно / Esc', 'Esc'),
  quitApp('Выход из приложения', 'Ctrl + Q');

  const HotkeyAction(this.description, this.defaultShortcut);
  final String description;
  final String defaultShortcut;
}

/// Сервис централизованной обработки горячих клавиш на десктопе.
class HotkeyService {
  HotkeyService();

  final _actionController = StreamController<HotkeyAction>.broadcast();
  Stream<HotkeyAction> get actionStream => _actionController.stream;

  final Map<SingleActivator, HotkeyAction> _bindings = {
    const SingleActivator(LogicalKeyboardKey.keyM, control: true, shift: true):
        HotkeyAction.toggleMirror,
    const SingleActivator(LogicalKeyboardKey.keyR, control: true, shift: true):
        HotkeyAction.toggleRecording,
    const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true):
        HotkeyAction.captureScreenshot,
    const SingleActivator(LogicalKeyboardKey.keyK, control: true):
        HotkeyAction.requestKeyframe,
    const SingleActivator(LogicalKeyboardKey.comma, control: true):
        HotkeyAction.openSettings,
    const SingleActivator(LogicalKeyboardKey.f10): HotkeyAction.toggleFrameless,
    const SingleActivator(LogicalKeyboardKey.escape): HotkeyAction.closeWindow,
    const SingleActivator(LogicalKeyboardKey.keyQ, control: true):
        HotkeyAction.quitApp,
  };

  Map<SingleActivator, HotkeyAction> get bindings =>
      Map.unmodifiable(_bindings);

  void trigger(HotkeyAction action) {
    _actionController.add(action);
  }

  void dispose() {
    _actionController.close();
  }
}
