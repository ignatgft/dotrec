# DotRec: R8/ProGuard. Держать классы MethodChannel/EventChannel и модели.
-keep class io.flutter.** { *; }
-keep class app.dotrec.bridge.** { *; }
-keep class app.dotrec.recorder.** { *; }
-keep class app.dotrec.settings.** { *; }
-dontwarn kotlinx.coroutines.**
