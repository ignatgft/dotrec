# 05. Flutter-приложение

## Зависимости (минимум)
- `flutter_riverpod`
- `google_fonts` не нужен: шрифт лежит в `assets/fonts/`
- `url_launcher` или нативный вызов для «Открыть системные настройки» (можно через канал)
- `flutter_localizations`, `intl`
- dev: `flutter_lints`, `flutter_test`, `golden_toolkit` или встроенные golden-тесты

Не добавляй пакетов для записи экрана. Всё нативное.

## Слои

```
UI (features/*)  →  providers  →  platform/ (каналы)  →  Kotlin
```

### `platform/recorder_channel.dart`
```dart
class RecorderChannel {
  static const _method = MethodChannel('app.dotrec/recorder');
  static const _events = EventChannel('app.dotrec/recorder_state');

  Future<void> start(RecordSettings s);
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<DeviceCaps> getDeviceCaps();      // размеры, частоты, кодеки
  Future<RecordSettings> getSettings();
  Future<void> saveSettings(RecordSettings s);
  Stream<RecorderState> get state;         // из EventChannel
}
```
Полный контракт с форматами сообщений: `reference/channel_contract.md`.

### Модели (`platform/models/`)
- `RecordSettings` (immutable, `copyWith`, `==`): `resolution`, `fps`, `bitrateMbps`, `codec`, `mic`, `systemAudio`, `countdownSec`, `preset`, `overlayPill`, `themeMode`.
- `RecorderState` (sealed class): `Idle`, `Countdown`, `Starting`, `Recording`, `Paused`, `Saving`, `Failed`.
- `DeviceCaps`: `screenWidth`, `screenHeight`, `maxRefreshHz`, `supportedRefreshHz`, `hevcSupported`, `maxBitrate`.

### Провайдеры (`providers.dart`)
- `recorderChannelProvider`: `Provider<RecorderChannel>`.
- `recorderStateProvider`: `StreamProvider<RecorderState>`.
- `settingsProvider`: `AsyncNotifier<RecordSettings>`: читает с нативной стороны, пишет через канал.
- `deviceCapsProvider`: `FutureProvider<DeviceCaps>`.
- `libraryProvider`: `AsyncNotifier<List<RecordingItem>>`.

## Экраны

| Экран | Путь | Содержимое |
|---|---|---|
| Онбординг | `features/onboarding` | Один экран: логотип-точки, 3 строки смысла, кнопка «Начать» |
| Главная | `features/home` | Статус, большая кнопка записи, выбор пресета, быстрые чипы разрешения и FPS, переключатели звука |
| Настройки | `features/settings` | Разрешение, FPS, битрейт, кодек, отсчёт, плашка, тема, язык, «О приложении» |
| Записи | `features/library` | Сетка/список записей, пустое состояние, действия |

Навигация: `Navigator 2.0` не нужен, достаточно `go_router` или обычного `Navigator.push`. Нижней навигации нет: главный экран, из него настройки и записи (иконки в шапке).

## Тема (`core/theme`)
- `DotTheme.light()` и `DotTheme.dark()` из `design/tokens.json`.
- Material 3 включён, но все компоненты переопределены: кнопки, чипы, переключатели, карточки.
- `ColorScheme.fromSeed` не использовать. Схема собирается вручную из токенов.
- Точечный шрифт `Doto` только для: таймера, статуса («READY»), числовых значений (1080, 60), заголовков экранов. Основной текст системным шрифтом (Roboto/Google Sans).

## Кастомные виджеты (`core/widgets`)
- `RecordButton`: круг с кольцом, внутри красный круг (готов) или красный квадрат (идёт запись). Анимация: морфинг круг→квадрат 220 мс, пульс кольца раз в 2 с во время записи. Размер 120 dp, тач-цель с запасом.
- `DotChip` и `DotSegmented`: сегменты разрешения и FPS, выбранный залит основным цветом.
- `DotSwitch`: круглый ползунок, активное состояние красное только для записи, иначе контрастное.
- `DotCard`: поверхность с тонкой рамкой 0,5 dp, радиус 20.
- `DotTimer`: таймер в точечном шрифте, `tabular figures`, без дёргания ширины.
- `DotDivider`: точечная линия (повторяющиеся точки), используется экономно.

## Поведение главного экрана
- Кнопка записи: `Idle` → старт, `Recording`/`Paused` → стоп (долгое нажатие не нужно).
- Во время записи чипы разрешения и FPS заблокированы (визуально приглушены), доступны пауза и стоп.
- При `Failed` показывается строка причины под кнопкой и кнопка «Повторить».
- При возврате в приложение во время записи состояние восстанавливается из потока (`EventChannel` отдаёт текущее при подписке).

## Тесты Flutter
- Юнит: сериализация `RecordSettings`/`RecorderState`, логика пресетов, форматирование таймера.
- Виджет: `HomeScreen` в состояниях Idle, Recording, Paused, Failed (с подменой канала моком).
- Golden: главный экран, настройки, пустая библиотека, в светлой и тёмной теме, масштаб шрифта 1,0 и 1,3.
