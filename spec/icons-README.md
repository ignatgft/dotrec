# DotRec — набор иконок

Знак приложения: кольцо из 16 точек (12 ярких, 4 приглушённых, как прогресс таймера) и красная точка записи в центре. Точечная матрица в духе Nothing OS, но без заимствования чужих знаков и шрифтов.

Палитра: чёрный `#000000`, белый `#FFFFFF`, ink `#101010`, paper `#F1F1F1`, красный `#D71921` (только для записи).

## Структура

| Путь | Что внутри |
|---|---|
| `android/res/` | Основной набор для Android (тёмная иконка): адаптивная иконка с monochrome-слоем, сплэш, уведомление, плитка, виджет, цвета, 24 UI-иконки в vector XML |
| `android/res-variant-light/` | Светлый вариант: подменяет foreground, splash и цвет фона |
| `android/legacy-png/` | PNG для mipmap-*dpi, необязательны (minSdk 29 использует адаптивную иконку) |
| `android/play-store/` | `ic_launcher_512_dark.png`, `ic_launcher_512_light.png` для Google Play |
| `flutter/assets/icons/` | 24 UI-иконки в SVG (24×24, stroke 1.8, `currentColor`) |
| `flutter/dot_icons.dart` | Константы путей к SVG (`DotIcons.record` и т. д.) |
| `flutter/launcher/` | Исходники для `flutter_launcher_icons`: foreground, monochrome, полная иконка (1024 px) |
| `svg/` | Все векторные исходники: `app/`, `logo/` (знак, вордмарк, лок-ап), `ui/` |
| `png/` | Растры: `app/`, `logo/`, `splash/`, `ui/black`, `ui/white` (96 px) |
| `previews/` | `launcher-preview.png` (4 варианта иконки), `ui-icons-sheet.png` (все UI-иконки) |
| `tools/generate_icons.py` | Генератор: единый источник геометрии, пересобирает всё одной командой |

## Подключение в Android (папка Flutter-проекта `android/app/src/main/res/`)

1. Скопируй содержимое `android/res/` в `res/` (с заменой). `mipmap-anydpi-v26/ic_launcher.xml` и `ic_launcher_round.xml` перекроют стандартные иконки шаблона Flutter.
2. Старые `mipmap-*dpi/ic_launcher.png` можно удалить: при minSdk 29 они не используются.
3. Для светлой иконки скопируй поверх `android/res-variant-light/`.
4. В манифесте уже должно быть `android:icon="@mipmap/ic_launcher"` и `android:roundIcon="@mipmap/ic_launcher_round"`.
5. Сплэш Android 12+: в теме `windowSplashScreenAnimatedIcon` = `@drawable/ic_splash`, `windowSplashScreenBackground` = `@color/ic_launcher_background`.
6. Уведомление: `setSmallIcon(R.drawable.ic_stat_rec)`. Плитка: `ic_tile_rec` в покое, `ic_tile_stop` при записи. Виджет: `widget_bg` фон, `widget_record_idle` / `widget_record_active` кнопка.
7. Цвета `dot_*` лежат в `values/` и `values-night/`, виджет сам меняет тему вместе с системой.
8. Иконка с monochrome-слоем включает «Тематические значки» Android 13+.

## Подключение во Flutter

Положи `flutter/assets/icons/` в `assets/icons/`, добавь в `pubspec.yaml`:

```yaml
dependencies:
  flutter_svg: ^2.0.0   # проверь актуальную версию
flutter:
  assets:
    - assets/icons/
```

```dart
SvgPicture.asset(DotIcons.record, width: 24, height: 24,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn));
```

Пакет `flutter_svg` не входит в список зависимостей из `docs/05-flutter-app.md`: если берёшь этот набор, добавь его туда. Альтернатива без пакета: использовать PNG из `png/ui/` (96 px, чёрные и белые), но тогда перекраска ограничена.

Генерация лаунчер-иконок через пакет (необязательно, вместо ручного копирования):

```yaml
flutter_launcher_icons:
  android: true
  image_path: "flutter/launcher/app_icon_dark_1024.png"
  adaptive_icon_background: "#000000"
  adaptive_icon_foreground: "flutter/launcher/foreground_dark_1024.png"
  adaptive_icon_monochrome: "flutter/launcher/monochrome_1024.png"
  min_sdk_android: 29
```

## Правила использования

- Красная точка только там, где идёт или готовится запись.
- Знак в монохромной версии (`monochrome`) держит одну форму: система сама красит его в цвет темы.
- Минимальный размер знака: 24 dp. Ниже кольцо превращается в шум, используй `ic_stat_rec` (кольцо + точка).
- Вордмарк DOTREC собран из точечной матрицы 5×7 и не использует шрифтов, лицензия на шрифт не нужна.
- Safe zone адаптивной иконки: знак вписан в круг диаметром 61 из 66 dp.
- UI-иконки: сетка 24 dp, толщина линии 1,8, скругленные концы и стыки.

## Список UI-иконок (24)

bolt, check, chevron_left, chevron_right, close, cut, info, library, mic, mic_off, open, pause, play, record, settings, share, stop, theme, timer, touches, trash, video, volume, volume_off.

Иконка `settings` нарисована ползунками, а не шестерёнкой: в `design/renders/screens.html` основного архива спецификации стоят временные иконки, при вёрстке опирайся на этот набор.

## Пересборка

```bash
pip install pillow
python3 tools/generate_icons.py          # в текущую папку набора
python3 tools/generate_icons.py ./out    # в другую папку
```
