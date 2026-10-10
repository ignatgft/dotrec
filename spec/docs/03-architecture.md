# 03. Архитектура

## Общая схема

```
┌─────────────────────────── Flutter (Dart) ───────────────────────────┐
│  UI (screens, widgets)                                               │
│    ↓ читает/пишет                                                    │
│  Riverpod providers (settings, recorder state, library)              │
│    ↓                                                                 │
│  platform/ (RecorderChannel, LibraryChannel) ← единственный мост     │
└───────────────┬──────────────────────────────────────▲───────────────┘
        MethodChannel (команды)                 EventChannel (состояние)
┌───────────────▼──────────────────────────────────────┴───────────────┐
│ Kotlin                                                               │
│  MainActivity ── FlutterEngine ── ChannelBridge                      │
│  RecorderService (foreground, mediaProjection)                       │
│     ├─ ProjectionController   (MediaProjection + VirtualDisplay)     │
│     ├─ EncoderPipeline        (MediaRecorder в v1, MediaCodec в v1.1)│
│     ├─ AudioCapture           (микрофон, playback capture)           │
│     └─ OutputWriter           (MediaStore, IS_PENDING)               │
│  RecorderStateStore (StateFlow) ◄── единый источник правды           │
│     ▲        ▲          ▲            ▲                               │
│  Tile    Widget   Notification   ChannelBridge                       │
│  ConsentActivity (прозрачная, запрос MediaProjection)                │
└──────────────────────────────────────────────────────────────────────┘
```

## Ключевые решения

| Решение | Почему |
|---|---|
| Запись в нативном сервисе | Видеопоток нельзя гнать через Dart; сервис живёт независимо от UI и Flutter-движка |
| `RecorderStateStore` как singleton с `StateFlow` | Плитка, виджет и уведомление могут работать, пока Flutter-движок не запущен |
| Flutter-движок не обязателен для плитки и виджета | Старт записи из шторки не должен ждать загрузки Dart |
| Прозрачная `ConsentActivity` | MediaProjection требует `startActivityForResult`; плитка и виджет не могут запросить согласие сами |
| MediaRecorder в v1, MediaCodec в v1.1 | MediaRecorder проще и надёжнее для видео+микрофон; микс со звуком системы требует своего пайплайна |
| Настройки в `shared_preferences` на стороне Dart, дубль в SharedPreferences на стороне Kotlin | Плитке нужны настройки без Flutter. Источник правды: Kotlin `SettingsStore`, Dart читает и пишет через канал |

## Состояния записи

```
Idle ──start()──► Countdown(n) ──► Starting ──► Recording ◄──► Paused
  ▲                    │              │            │             │
  │                    └──cancel──────┘            └──stop()─────┤
  └──────────────── Saving ◄───────────────────────────────────────┘
                      │
                      └──► Idle (с результатом: Saved(uri) | Failed(reason))
```

Состояния: `Idle`, `Countdown(secondsLeft)`, `Starting`, `Recording(elapsedMs)`, `Paused(elapsedMs)`, `Saving`, `Failed(code)`.
Каждое состояние сериализуется в Map для канала (см. `reference/channel_contract.md`).

## Структура репозитория

```
dotrec/
├─ lib/
│  ├─ main.dart
│  ├─ app.dart                    # MaterialApp, тема, локали
│  ├─ core/
│  │  ├─ theme/                   # DotTheme, токены, текстовые стили
│  │  ├─ widgets/                 # DotButton, DotChip, RecordButton, DotSwitch
│  │  └─ l10n/                    # ARB-файлы
│  ├─ platform/
│  │  ├─ recorder_channel.dart    # MethodChannel + EventChannel
│  │  ├─ library_channel.dart
│  │  └─ models/                  # RecorderState, RecordSettings, ...
│  ├─ features/
│  │  ├─ home/                    # главный экран
│  │  ├─ settings/
│  │  ├─ library/
│  │  └─ onboarding/
│  └─ providers.dart
├─ android/app/src/main/kotlin/app/dotrec/
│  ├─ MainActivity.kt
│  ├─ bridge/ChannelBridge.kt
│  ├─ recorder/
│  │  ├─ RecorderService.kt
│  │  ├─ ProjectionController.kt
│  │  ├─ EncoderPipeline.kt
│  │  ├─ AudioCapture.kt
│  │  ├─ OutputWriter.kt
│  │  └─ RecorderStateStore.kt
│  ├─ entry/
│  │  ├─ RecordTileService.kt
│  │  ├─ RecordWidgetProvider.kt
│  │  ├─ ConsentActivity.kt
│  │  ├─ OverlayPill.kt
│  │  └─ NotificationFactory.kt
│  ├─ settings/SettingsStore.kt
│  └─ util/ (BitrateCalc, SizeCalc, FileNamer, DeviceCaps)
├─ assets/fonts/Doto-*.ttf
├─ test/ (юнит + golden)
└─ docs/ (эта спецификация)
```

## Потоки

**Старт из приложения**
1. UI → `RecorderChannel.start(settings)`.
2. Kotlin: если нет токена проекции, открывает `ConsentActivity`, получает результат.
3. `RecorderService` стартует как foreground service, затем получает `MediaProjection`.
4. `Countdown` → `Starting` → `Recording`, состояние летит в `RecorderStateStore` → все подписчики.

**Старт из плитки**
1. `TileService.onClick` → читает `SettingsStore`.
2. Нужна проекция: запускает `ConsentActivity` (через `startActivityAndCollapse`, на API 34+ с `PendingIntent`).
3. Дальше как выше. Flutter-движок не создаётся.

**Остановка**
1. Любой вход → `RecorderService.stop()`.
2. Остановка энкодера, `Saving`, финализация MediaStore (`IS_PENDING = 0`).
3. Состояние `Idle` + одноразовый результат `Saved(uri)`; уведомление «Запись сохранена».

## Обработка ошибок

| Ошибка | Реакция |
|---|---|
| Пользователь отклонил согласие | `Idle`, мягкий тост «Запись не началась» |
| Нет места | Не стартовать / остановить и сохранить |
| Кодек не поддерживает параметры | Откат на ближайший поддерживаемый, показать в итоге |
| Проекция остановлена системой (`onStop` колбэк) | Корректно завершить запись, сохранить файл |
| Исключение в пайплайне | `Failed(code)`, освободить ресурсы, оставить файл, если он валиден |
