import 'dart:async';

import 'package:flutter/foundation.dart';

/// Статус состояния в системном трее.
enum TrayStatus {
  idle('DotRec Link — готов к подключению', 'tray_idle.ico'),
  streaming('DotRec Link — трансляция активна', 'tray_live.ico'),
  recording('DotRec Link — запись на ПК', 'tray_rec.ico'),
  error('DotRec Link — ошибка подключения', 'tray_idle.ico');

  const TrayStatus(this.tooltip, this.iconFileName);
  final String tooltip;
  final String iconFileName;

  String getIconPath({bool isDarkTaskbar = true}) {
    final folder = isDarkTaskbar ? 'for-dark-taskbar' : 'for-light-taskbar';
    return 'assets/tray/$folder/$iconFileName';
  }
}

/// Действия из контекстного меню системного трея.
enum TrayAction {
  showWindow,
  hideWindow,
  toggleRecording,
  requestKeyframe,
  openSettings,
  exitApp,
}

/// Уведомление в трее.
class TrayNotification {
  const TrayNotification({
    required this.title,
    required this.message,
    this.timestamp,
  });

  final String title;
  final String message;
  final DateTime? timestamp;
}

/// Сервис управления системным треем и жизненным циклом окна на десктопе.
class TrayService {
  TrayService() {
    _status = TrayStatus.idle;
    _isWindowVisible = true;
    _isTrayActive = true;
  }

  TrayStatus _status = TrayStatus.idle;
  bool _isWindowVisible = true;
  bool _isTrayActive = true;

  final _actionController = StreamController<TrayAction>.broadcast();
  final _notificationController =
      StreamController<TrayNotification>.broadcast();
  final _statusController = StreamController<TrayStatus>.broadcast();

  TrayStatus get status => _status;
  bool get isWindowVisible => _isWindowVisible;
  bool get isTrayActive => _isTrayActive;

  Stream<TrayAction> get actionStream => _actionController.stream;
  Stream<TrayNotification> get notificationStream =>
      _notificationController.stream;
  Stream<TrayStatus> get statusStream => _statusController.stream;

  void setStatus(TrayStatus status) {
    if (_status == status) return;
    _status = status;
    _statusController.add(status);
  }

  void setWindowVisible(bool visible) {
    _isWindowVisible = visible;
    if (visible) {
      _actionController.add(TrayAction.showWindow);
    } else {
      _actionController.add(TrayAction.hideWindow);
    }
  }

  void toggleWindow() {
    setWindowVisible(!_isWindowVisible);
  }

  void dispatchAction(TrayAction action) {
    switch (action) {
      case TrayAction.showWindow:
        _isWindowVisible = true;
        break;
      case TrayAction.hideWindow:
        _isWindowVisible = false;
        break;
      default:
        break;
    }
    _actionController.add(action);
  }

  void notify(String title, String message) {
    final notif = TrayNotification(
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    _notificationController.add(notif);
    debugPrint('[Tray] $title: $message');
  }

  void dispose() {
    _actionController.close();
    _notificationController.close();
    _statusController.close();
  }
}
