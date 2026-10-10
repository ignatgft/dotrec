# DotRec — быстрый и красивый рекордер экрана (Android)

Flutter (интерфейс) + Kotlin (нативное ядро записи). Стиль в духе Nothing OS:
монохром, один красный акцент, точечный шрифт Doto, круглые формы. Светлая и
тёмная темы с первого дня. Полностью офлайн, без `INTERNET`.

Исходная спецификация агента лежит в `spec/` (`AGENTS.md` — главный файл).

## Статус: v0.1.0-beta (M0 + каркас M1)

- [x] T-01. Проект: `app.dotrec`, minSdk 29, targetSdk 35, Kotlin 2.x
- [x] T-02. Тема `DotTheme.light/dark` из токенов, шрифт Doto, Система/Светлая/Тёмная
- [x] T-03. Виджеты: `RecordButton` (6 состояний), `DotSegmented`, `DotSwitch`,
  `DotCard`, `DotTimer`
- [x] T-04. Локализация ARB `ru`/`en`
- [x] T-05. Контракт каналов v1: Dart-модели + тесты сериализации
- [x] T-06. Чистая логика: `BitrateCalc`, `SizeCalc`, `FileNamer` + тесты
- [x] T-07. `RecorderStateStore` (StateFlow), `SettingsStore`
- [~] T-08. `ConsentActivity` + `RecorderService`: **каркас с симуляцией состояний**.
  Реальный пайплайн MediaProjection + MediaRecorder — задача M1
- [x] T-14. Мост каналов `ChannelBridge` + `EventChannel` с текущим состоянием
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

Kotlin: `cd android && ./gradlew testDebugUnitTest lintDebug` (после M1).

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
