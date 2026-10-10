# DotRec — бесплатный рекордер экрана (Android)

Бесплатно, без рекламы, без водяных знаков, полностью офлайн.
Free screen recorder: no ads, no watermark, offline.

Flutter (интерфейс) + Kotlin (нативное ядро записи). Стиль в духе Nothing OS:
монохром, один красный акцент, точечный шрифт Doto, круглые формы. Светлая и
тёмная темы с первого дня. Полностью офлайн, без `INTERNET`.
Языки интерфейса: English, Русский, Español, Deutsch, Français, Português,
Українська (авто по системе + ручной выбор).

Исходная спецификация агента лежит в `spec/` (`AGENTS.md` — главный файл).

## Статус: v0.5.0-beta (всё по плану, кроме матрицы устройств)

- [x] T-23…T-25 (M4, v1.1). Пайплайн MediaCodec + MediaMuxer, звук системы
  (AudioPlaybackCapture) + микс с микрофоном, HEVC с откатом. FR-AUD-04:
  пометка о возможном запрете захвата в итоговом уведомлении
- [x] T-26/T-27 (M5). Пульс кнопки, хаптик, `disableAnimations`, TalkBack
  раз в 10 с
- [x] T-29 (M5). Сплэш Android 12+ с точечным логотипом
- [x] T-30 (M5). Сплиты APK по ABI + AAB
- [ ] T-28. Матрица устройств — pending, нет устройств

- [x] T-01. Проект: `app.dotrec`, minSdk 29, targetSdk 35, Kotlin 2.x
- [x] T-02. Тема `DotTheme.light/dark` из токенов, шрифт Doto, Система/Светлая/Тёмная
- [x] T-03. Виджеты: `RecordButton` (6 состояний), `DotSegmented`, `DotSwitch`,
  `DotCard`, `DotTimer`
- [x] T-04. Локализация ARB `ru`/`en`
- [x] T-05. Контракт каналов v1: Dart-модели + тесты сериализации
- [x] T-06. Чистая логика: `BitrateCalc`, `SizeCalc`, `FileNamer` + тесты
- [x] T-07. `RecorderStateStore` (StateFlow), `SettingsStore`
- [x] T-08. `ConsentActivity` + `RecorderService`: реальный пайплайн
  MediaProjection + MediaRecorder + VirtualDisplay, foreground service,
  MediaStore `Movies/DotRec/`, одноразовый токен согласия
- [x] T-09. Чек-лист освобождения, `onStop` колбэк, resize при повороте
- [x] T-10. Пауза/продолжение, отсчёт 3-2-1 (Нет/3с/5с)
- [x] T-11. Уведомление записи (хронометр, Пауза/Стоп) + «Запись сохранена»
  (Открыть/Поделиться/Удалить)
- [x] T-12. Микрофон: запрос в момент включения, `setAudioSource(MIC)`
- [x] T-13. Проверка места: блок старта <200 МБ, автостоп при <100 МБ
- [x] T-14. Мост каналов `ChannelBridge` + `EventChannel` с текущим состоянием
  и одноразовым событием `saved`
- [x] T-15…T-19 (M2). Главный экран, `DeviceCaps`, настройки, онбординг,
  библиотека (pull-to-refresh), снекбар с кнопкой «Настройки» при отказе
- [x] T-20…T-22 (M3). Плитка шторки с таймером + кнопка «Добавить плитку»,
  виджет 2×1 (обе темы), плавающая плашка (`FLAG_SECURE`, перетаскивание,
  прилипание к краю, выключена по умолчанию)
- [x] T-19 (частично). Библиотека: список/открыть/поделиться/удалить через MediaStore

Отклонения от спеки (честно):
- `compileSdk 36` вместо 35 — требует `shared_preferences_android`
  (targetSdk остаётся 35 по спеке).
- `applicationId app.dotrec` вместо `app.dotrec.dotrec` (чище, совпадает с
  пакетами `app.dotrec.*` из `reference/`).
- Пример из docs/04 «1080×2400·60 даёт около 20 Мбит/с» не сходится с формулой
  `w*h*fps*0.07` (даёт 10.9 → шаг 12). Тесты фиксируют формулу, вопрос
  записан в `docs/10` ниже.
- Размер релизного APK больше целевых 25 МБ (см. релиз) — оптимизация в M5.

## Проверки

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

Kotlin: `cd android && ./gradlew :app:testDebugUnitTest` (17 тестов зелёные).
Ручной тест-план из `spec/docs/09-testing-qa.md` на устройстве — pending
(нет подключённого устройства): запись 30 с 1080p·60, паузы, поворот,
отказ в согласии, мало места, 20 циклов старт/стоп.

## Подпись релиза

Релиз подписывается ключом `android/app/dotrec-release.jks` (не в git).
Скопируй `android/key.properties.example` в `android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=dotrec
storeFile=dotrec-release.jks
```

## Открытые вопросы (docs/10)

1. Формула битрейта vs пример 20 Мбит/с — уточнить `k` или шаги.
2. Показ касаний (FR-SET-05): делаем через adb-грант или убираем из v1?
3. Публикация: Google Play или только APK?
