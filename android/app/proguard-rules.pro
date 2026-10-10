# DotRec: R8/ProGuard. Держать классы MethodChannel/EventChannel и модели.
-keep class io.flutter.** { *; }
-keep class app.dotrec.bridge.** { *; }
-keep class app.dotrec.recorder.** { *; }
-keep class app.dotrec.settings.** { *; }
-dontwarn kotlinx.coroutines.**
# Сгенерировано AGP (Flutter embedding ссылается на Play Core без зависимости).
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
