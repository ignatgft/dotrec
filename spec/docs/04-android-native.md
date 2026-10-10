# 04. Android: нативное ядро (Kotlin)

Все API ниже проверь по официальной документации Android перед использованием. Где есть сомнение, оставь `TODO(verify)`.

## Манифест

Разрешения:
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_MEDIA_PROJECTION` (API 34+)
- `POST_NOTIFICATIONS` (API 33+, запрос в рантайме)
- `RECORD_AUDIO` (в рантайме, только при включении микрофона)
- `SYSTEM_ALERT_WINDOW` (только если включена плашка, запрос через системные настройки)
- `INTERNET` **отсутствует**

Компоненты:
```xml
<service android:name=".recorder.RecorderService"
         android:exported="false"
         android:foregroundServiceType="mediaProjection" />

<service android:name=".entry.RecordTileService"
         android:exported="true"
         android:icon="@drawable/ic_tile"
         android:label="@string/tile_label"
         android:permission="android.permission.BIND_QUICK_SETTINGS_TILE">
    <intent-filter>
        <action android:name="android.service.quicksettings.action.QS_TILE" />
    </intent-filter>
</service>

<activity android:name=".entry.ConsentActivity"
          android:theme="@style/Theme.Transparent"
          android:excludeFromRecents="true"
          android:taskAffinity=""
          android:exported="false" />

<receiver android:name=".entry.RecordWidgetProvider" android:exported="false">
    <intent-filter><action android:name="android.appwidget.action.APPWIDGET_UPDATE" /></intent-filter>
    <meta-data android:name="android.appwidget.provider" android:resource="@xml/record_widget_info" />
</receiver>
```

## Поток запуска MediaProjection

1. `ConsentActivity` вызывает `MediaProjectionManager.createScreenCaptureIntent()` и ждёт результат.
2. Результат (`resultCode`, `data`) передаётся в `RecorderService` через `Intent` (сервис не хранит токен между сессиями).
3. Сервис **сначала** вызывает `startForeground(id, notification, FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)`.
4. Только потом `mediaProjectionManager.getMediaProjection(resultCode, data)`.
5. На Android 14+ **до** `createVirtualDisplay` обязательно `projection.registerCallback(callback, handler)`. Без этого выбрасывается исключение.
6. Токен на Android 14+ одноразовый: для каждой новой записи согласие запрашивается заново. Не пытайся кешировать `data`.
7. Android 15 может предложить пользователю запись одного приложения вместо всего экрана. Обрабатывай размеры, пришедшие из `MediaProjection.Callback.onCapturedContentResize`.

Callback `MediaProjection.Callback`:
- `onStop()`: система или пользователь остановили проекцию. Корректно завершить запись.
- `onCapturedContentResize(w, h)`: пересоздать размеры VirtualDisplay (`resize`).
- `onCapturedContentVisibilityChanged(visible)`: можно показать подсказку, если захваченное окно скрыто.

## Конвейер кодирования

### v1: MediaRecorder (микрофон)
Порядок настройки (порядок вызовов важен):
1. `setVideoSource(SURFACE)`, при микрофоне `setAudioSource(MIC)` до `setOutputFormat`.
2. `setOutputFormat(MPEG_4)`.
3. `setVideoEncoder(H264 | HEVC)`, `setAudioEncoder(AAC)` если есть звук.
4. `setVideoSize(w, h)`, `setVideoFrameRate(fps)`, `setVideoEncodingBitRate(bitrate)`.
5. `setOutputFile(FileDescriptor)` из MediaStore (`ParcelFileDescriptor`).
6. `prepare()`, затем `createVirtualDisplay(..., recorder.surface, ...)`, затем `start()`.
Пауза и продолжение: `recorder.pause()`, `recorder.resume()`.

### v1.1: MediaCodec + MediaMuxer (звук системы и микс)
MediaRecorder не принимает `AudioRecord` с playback capture. Для FR-AUD-02/03 нужен свой пайплайн:
- Видео: `MediaCodec` encoder с `createInputSurface()`, VirtualDisplay рисует в эту поверхность.
- Аудио: `AudioRecord` с `AudioPlaybackCaptureConfiguration` (захват `USAGE_MEDIA`, `USAGE_GAME`, `USAGE_UNKNOWN`) и, при необходимости, второй `AudioRecord` с микрофона, микс PCM на лету, кодирование в AAC через `MediaCodec`.
- Мультиплексор: `MediaMuxer` (MPEG_4), синхронизация по `presentationTimeUs` из общего монотонного источника времени.
- Пауза: накапливать смещение, чтобы метки времени не имели разрыва.
- Ограничение: приложения могут запретить захват своего звука (`allowAudioPlaybackCapture=false`), это нужно показать пользователю (FR-AUD-04).

## Выбор размеров, FPS, битрейта

**Размеры (`SizeCalc`)**
- Вход: размеры экрана в пикселях, целевая «высота» (720, 1080, 1440 по короткой стороне).
- Масштабируем с сохранением пропорций, обе стороны чётные (кратные 2; лучше кратные 16 для максимальной совместимости энкодеров, но не ломая пропорции больше чем на 1%).
- Если экран меньше целевого, пункт скрывается.
- Проверка по `MediaCodecInfo.VideoCapabilities`: `isSizeSupported`, `getSupportedFrameRatesFor`, `getBitrateRange`. При несоответствии откат на ближайшее поддерживаемое.

**FPS**
- Максимум = высшая частота обновления из `Display.getSupportedModes()` для текущего разрешения.
- 90 и 120 показываем, только если устройство их поддерживает. Иначе пункт отключён, подпись «Экран поддерживает до N Гц».
- Помни: VirtualDisplay выдаёт кадры по мере обновления экрана, фактический FPS записи не может превышать то, что рисует экран. Для статичного содержимого кадров может быть меньше. Это нормально.

**Битрейт (`BitrateCalc`)**: значение по умолчанию.
Формула: `bitrate = w * h * fps * k`, где `k = 0.07` для H.264 и `0.045` для HEVC, затем округление до ближайшего значения из списка (4, 8, 12, 20, 40 Мбит/с). Примеры: 1080×2400·60 даёт около 20 Мбит/с, 720p·30 даёт около 4–6 Мбит/с. Формулу вынеси в чистую функцию и покрой тестами.

## Хранение: MediaStore

- Создать запись: `ContentValues` с `DISPLAY_NAME`, `MIME_TYPE = video/mp4`, `RELATIVE_PATH = Movies/DotRec`, `IS_PENDING = 1`.
- Открыть дескриптор: `contentResolver.openFileDescriptor(uri, "w")` и отдать MediaRecorder/Muxer.
- После успешной остановки: `IS_PENDING = 0`.
- При ошибке без валидного файла: удалить запись.
- Широкие права на хранилище **не запрашиваем**.
- Проверка свободного места: `StatFs` перед стартом (порог 200 МБ) и раз в 5 секунд во время записи.

## Уведомление записи

- Канал `recording` (важность LOW, без звука).
- Содержимое: заголовок «Идёт запись», хронометр (`setUsesChronometer(true)`), действия «Пауза/Продолжить», «Стоп».
- Действия идут в `RecorderService` через `PendingIntent.getService`.
- После сохранения: отдельное уведомление в канале `results` с «Открыть», «Поделиться», «Удалить» (FileProvider/URI из MediaStore + `FLAG_GRANT_READ_URI_PERMISSION`).

## Плитка шторки (`RecordTileService`)

- `onStartListening`: подписаться на `RecorderStateStore`, обновлять `qsTile.state` (`STATE_INACTIVE`/`STATE_ACTIVE`), `label`, `subtitle` (таймер, API 29+).
- `onClick`: если записи нет, запустить `ConsentActivity` через `startActivityAndCollapse` (на API 34+ используется перегрузка с `PendingIntent`); если запись идёт, отправить `stop`.
- Плитка не должна ждать Flutter. Всё нативное.
- Подсказка пользователю, как добавить плитку: Android 13+ `StatusBarManager.requestAddTileService` (показать кнопку «Добавить плитку» в настройках приложения).

## Виджет 2×1 (`RecordWidgetProvider`)

- `RemoteViews`: круглая кнопка, подпись пресета («1080·60»), состояние записи.
- Клик: `PendingIntent` на `ConsentActivity` (старт) или `RecorderService` (стоп).
- Обновление: при каждом изменении `RecorderStateStore` вызывать `AppWidgetManager.updateAppWidget`. Таймер на виджете не секундный (ограничение частоты обновления), вместо него индикатор «REC».
- Две темы: ресурсы `values/` и `values-night/` для цветов виджета.

## Плавающая плашка (`OverlayPill`, P1)

- `WindowManager` + `TYPE_APPLICATION_OVERLAY`, размер по содержимому, перетаскивание, прилипание к краю.
- `FLAG_SECURE` в `LayoutParams`, чтобы плашка не попадала в запись (**проверить на устройствах**, поведение может отличаться, задокументировать результат в `docs/10`).
- Отключена по умолчанию. Включение ведёт на системный экран разрешения «Поверх других окон».

## Показ касаний (P2, экспериментально)
Системная настройка `show_touches` меняется только при наличии `WRITE_SECURE_SETTINGS` (выдаётся вручную через `adb shell pm grant`). Реализация: если разрешение есть, переключатель работает, иначе показывается инструкция. В v1 можно не делать.

## Освобождение ресурсов (чек-лист остановки)
1. `recorder.stop()` в try/catch (может выбросить, если запись длилась слишком мало).
2. `virtualDisplay.release()`.
3. `projection.unregisterCallback`, `projection.stop()`.
4. Закрыть `ParcelFileDescriptor`, снять `IS_PENDING`.
5. `stopForeground(STOP_FOREGROUND_REMOVE)`, `stopSelf()`.
6. Обновить `RecorderStateStore`.
Все шаги в `finally`, каждый в своём try/catch.
