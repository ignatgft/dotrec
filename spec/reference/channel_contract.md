# Контракт каналов Flutter ↔ Kotlin

Версия контракта: **1**. Любое изменение требует обновления этого файла, Dart и Kotlin.

## MethodChannel `app.dotrec/recorder`

| Метод | Аргументы | Результат | Ошибки (`PlatformException.code`) |
|---|---|---|---|
| `start` | `RecordSettings` (Map) | `null` | `consent_denied`, `low_storage`, `already_running`, `unsupported_params` |
| `stop` | нет | `null` | `not_running` |
| `pause` | нет | `null` | `not_running` |
| `resume` | нет | `null` | `not_paused` |
| `getDeviceCaps` | нет | `DeviceCaps` (Map) | нет |
| `getSettings` | нет | `RecordSettings` (Map) | нет |
| `saveSettings` | `RecordSettings` (Map) | `null` | `invalid_settings` |
| `openAppSettings` | нет | `null` | нет |
| `requestAddTile` | нет (Android 13+) | `bool` | нет |

## MethodChannel `app.dotrec/library`

| Метод | Аргументы | Результат |
|---|---|---|
| `list` | нет | `List<RecordingItem>` (Map) |
| `delete` | `{uri: String}` | `bool` |
| `share` | `{uri: String}` | `null` |
| `open` | `{uri: String}` | `null` |

## EventChannel `app.dotrec/recorder_state`
При подписке сразу отдаёт текущее состояние, затем каждое изменение.

```json
{ "type": "idle" }
{ "type": "countdown", "secondsLeft": 3 }
{ "type": "starting" }
{ "type": "recording", "elapsedMs": 42000 }
{ "type": "paused", "elapsedMs": 42000 }
{ "type": "saving" }
{ "type": "failed", "code": "encoder_error", "message": "..." }
{ "type": "saved", "uri": "content://media/external/video/media/123", "durationMs": 61000, "sizeBytes": 31457280 }
```
`saved` одноразовое событие, после него приходит `idle`.
`elapsedMs` обновляется раз в 1 с (не чаще).

## Модели

**RecordSettings**
```json
{
  "resolution": 1080,
  "fps": 60,
  "bitrateMbps": 20,
  "codec": "h264",
  "mic": false,
  "systemAudio": false,
  "countdownSec": 3,
  "preset": "balanced",
  "overlayPill": false,
  "themeMode": "system"
}
```
Допустимые значения: `resolution` ∈ {720, 1080, 1440}; `fps` ∈ {30, 60, 90}; `bitrateMbps` ∈ {4, 8, 12, 20, 40}; `codec` ∈ {"h264", "hevc"}; `countdownSec` ∈ {0, 3, 5}; `preset` ∈ {"fast", "balanced", "quality", "custom"}; `themeMode` ∈ {"system", "light", "dark"}.

**DeviceCaps**
```json
{
  "screenWidth": 1080,
  "screenHeight": 2400,
  "supportedRefreshHz": [60, 90],
  "maxRefreshHz": 90,
  "hevcSupported": true,
  "availableResolutions": [720, 1080],
  "freeBytes": 53687091200
}
```

**RecordingItem**
```json
{ "uri": "content://...", "name": "DotRec_20261009_171500.mp4", "durationMs": 61000, "sizeBytes": 31457280, "createdAtMs": 1791566100000 }
```

## Коды ошибок состояния `failed`
`consent_denied`, `low_storage`, `encoder_error`, `projection_stopped`, `audio_error`, `io_error`, `unknown`.
