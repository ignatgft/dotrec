# Промпт: нативное ядро записи (этап M1)

Реализуй `RecorderService` по `docs/04-android-native.md`.
Требования: FR-REC-01…FR-REC-08, NFR-PERF-01…03.
Обязательно: foreground service типа mediaProjection, `MediaProjection.Callback` до `createVirtualDisplay`, запись в MediaStore с `IS_PENDING`, корректное освобождение ресурсов при ошибке.
Напиши юнит-тесты на чистую логику (расчёт битрейта, выбор размеров, имя файла) и инструкцию ручной проверки на устройстве.
Не трогай Flutter-слой, кроме контракта каналов.
