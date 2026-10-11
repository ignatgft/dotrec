package app.dotrec.bridge

import android.app.Activity
import android.content.ContentUris
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.net.toUri
import app.dotrec.R
import app.dotrec.entry.ConsentActivity
import app.dotrec.recorder.RecorderService
import app.dotrec.recorder.RecorderState
import app.dotrec.recorder.RecorderStateStore
import app.dotrec.settings.SettingsStore
import app.dotrec.util.DeviceCaps
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

/** Мост Flutter ↔ Kotlin. Контракт каналов v1. */
object ChannelBridge {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    fun register(activity: Activity, engine: FlutterEngine) {
        val settings = SettingsStore(activity)
        MethodChannel(engine.dartExecutor.binaryMessenger, "app.dotrec/recorder")
            .setMethodCallHandler { call, result -> handleRecorder(activity, settings, call, result) }
        MethodChannel(engine.dartExecutor.binaryMessenger, "app.dotrec/library")
            .setMethodCallHandler { call, result -> handleLibrary(activity, call, result) }
        EventChannel(engine.dartExecutor.binaryMessenger, "app.dotrec/recorder_state")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink) {
                    sink.success(RecorderStateStore.toMap(RecorderStateStore.state.value))
                    val stateJob = scope.launch {
                        RecorderStateStore.state.collectLatest { s ->
                            sink.success(RecorderStateStore.toMap(s))
                        }
                    }
                    val resultJob = scope.launch {
                        app.dotrec.recorder.RecordingEvents.results.collectLatest { m ->
                            sink.success(m)
                        }
                    }
                    sinkJobs = listOf(stateJob, resultJob)
                }

                override fun onCancel(args: Any?) {
                    sinkJobs.forEach { it.cancel() }
                    sinkJobs = emptyList()
                }
            })
        EventChannel(engine.dartExecutor.binaryMessenger, "app.dotrec/link_state")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink) {
                    val job = scope.launch {
                        app.dotrec.link.LinkServer.state.collectLatest { st ->
                            sink.success(mapOf(
                                "status" to st.status,
                                "mode" to st.mode,
                                "pin" to st.pin,
                                "pinTtlSec" to st.pinTtlSec,
                                "clientName" to st.clientName,
                                "streamActive" to st.streamActive,
                                "latencyMs" to st.latencyMs,
                            ))
                        }
                    }
                    linkJobs = listOf(job)
                }

                override fun onCancel(args: Any?) {
                    linkJobs.forEach { it.cancel() }
                    linkJobs = emptyList()
                }
            })
    }

    private var sinkJobs: List<kotlinx.coroutines.Job> = emptyList()
    private var linkJobs: List<kotlinx.coroutines.Job> = emptyList()

    private fun handleRecorder(
        activity: Activity,
        settings: SettingsStore,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "start" -> {
                // Повтор после ошибки: Failed виден в UI, сбрасываем для нового старта.
                if (RecorderStateStore.state.value is RecorderState.Failed) {
                    runCatching { RecorderStateStore.set(RecorderState.Idle) }
                }
                if (RecorderStateStore.state.value !is RecorderState.Idle) {
                    result.error("already_running", null, null)
                    return
                }
                if (freeBytes() < 200L * 1024 * 1024) {
                    runCatching { RecorderStateStore.set(RecorderState.Starting) }
                    runCatching { RecorderStateStore.set(RecorderState.Failed("low_storage")) }
                    result.error("low_storage", null, null)
                    return
                }
                @Suppress("UNCHECKED_CAST")
                val args = (call.arguments as? Map<String, Any?>) ?: emptyMap()
                runCatching { settings.saveAll(args) }
                // Сервис сам читает SettingsStore; запуск через прозрачную
                // ConsentActivity (системное согласие, токен одноразовый).
                val consent = Intent(activity, ConsentActivity::class.java)
                activity.startActivity(consent)
                result.success(null)
            }
            "stop" -> {
                activity.startService(
                    Intent(activity, RecorderService::class.java).setAction(RecorderService.ACTION_STOP),
                )
                result.success(null)
            }
            "pause" -> {
                activity.startService(
                    Intent(activity, RecorderService::class.java).setAction(RecorderService.ACTION_PAUSE),
                )
                result.success(null)
            }
            "resume" -> {
                activity.startService(
                    Intent(activity, RecorderService::class.java).setAction(RecorderService.ACTION_RESUME),
                )
                result.success(null)
            }
            "getDeviceCaps" -> {
                val display = if (Build.VERSION.SDK_INT >= 30) {
                    activity.display
                } else {
                    @Suppress("DEPRECATION")
                    activity.windowManager.defaultDisplay
                }
                result.success(DeviceCaps.collect(activity, display))
            }
            "getSettings" -> result.success(settings.getAll())
            "saveSettings" -> {
                @Suppress("UNCHECKED_CAST")
                val args = (call.arguments as? Map<String, Any?>) ?: emptyMap()
                try {
                    settings.saveAll(args)
                    result.success(null)
                } catch (_: IllegalArgumentException) {
                    result.error("invalid_settings", null, null)
                }
            }
            "openAppSettings" -> {
                activity.startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, "package:${activity.packageName}".toUri()),
                )
                result.success(null)
            }
            // Кнопка «Добавить плитку» (Android 13+, docs/04).
            "requestAddTile" -> {
                if (Build.VERSION.SDK_INT >= 33) {
                    try {
                        val sbm = activity.getSystemService(
                            android.app.StatusBarManager::class.java,
                        )
                        val component = android.content.ComponentName(
                            activity,
                            app.dotrec.entry.RecordTileService::class.java,
                        )
                        sbm.requestAddTileService(
                            component,
                            activity.getString(R.string.tile_label),
                            android.graphics.drawable.Icon.createWithResource(
                                activity,
                                R.drawable.ic_tile_rec,
                            ),
                            activity.mainExecutor,
                        ) { r ->
                            result.success(
                                r == android.app.StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ADDED,
                            )
                        }
                    } catch (_: Exception) {
                        result.success(false)
                    }
                } else {
                    result.success(false)
                }
            }
            "openOverlaySettings" -> {
                activity.startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        "package:${activity.packageName}".toUri(),
                    ),
                )
                result.success(null)
            }
            // Экран настроек батареи для гайда (только текст-подсказка + переход,
            // без запроса IGNORE_BATTERY_OPTIMIZATIONS).
            "openBatterySettings" -> {
                runCatching {
                    activity.startActivity(
                        Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
                    )
                }
                result.success(null)
            }
            "startLinkServer" -> {
                val mode = call.argument<String>("mode") ?: "usb"
                app.dotrec.link.LinkServer.start(activity, mode)
                result.success(null)
            }
            "stopLinkServer" -> {
                app.dotrec.link.LinkServer.stop()
                result.success(null)
            }
            "getLinkState" -> {
                val st = app.dotrec.link.LinkServer.state.value
                result.success(mapOf(
                    "status" to st.status,
                    "mode" to st.mode,
                    "pin" to st.pin,
                    "pinTtlSec" to st.pinTtlSec,
                    "clientName" to st.clientName,
                    "streamActive" to st.streamActive,
                    "latencyMs" to st.latencyMs,
                ))
            }
            else -> result.notImplemented()
        }
    }

    private fun handleLibrary(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "list" -> result.success(listDotRec(activity))
            "open" -> {
                val uri = ((call.arguments as? Map<*, *>)?.get("uri") as? String) ?: run {
                    result.success(null)
                    return
                }
                val open = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri.toUri(), "video/mp4")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                activity.startActivity(Intent.createChooser(open, null))
                result.success(null)
            }
            "share" -> {
                val uri = ((call.arguments as? Map<*, *>)?.get("uri") as? String) ?: run {
                    result.success(null)
                    return
                }
                val share = Intent(Intent.ACTION_SEND).apply {
                    type = "video/mp4"
                    putExtra(Intent.EXTRA_STREAM, uri.toUri())
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                activity.startActivity(Intent.createChooser(share, null))
                result.success(null)
            }
            "delete" -> {
                val uri = ((call.arguments as? Map<*, *>)?.get("uri") as? String) ?: run {
                    result.success(false)
                    return
                }
                val rows = activity.contentResolver.delete(uri.toUri(), null, null)
                result.success(rows > 0)
            }
            "trim" -> {
                val args = call.arguments as? Map<*, *>
                val uriStr = args?.get("uri") as? String
                val startMs = (args?.get("startMs") as? Number)?.toLong() ?: 0L
                val endMs = (args?.get("endMs") as? Number)?.toLong() ?: 0L
                if (uriStr == null) {
                    result.success(null)
                    return
                }
                val srcUri = uriStr.toUri()
                val srcPfd = try {
                    activity.contentResolver.openFileDescriptor(srcUri, "r")
                } catch (_: Exception) {
                    null
                }
                if (srcPfd == null) {
                    result.success(null)
                    return
                }
                val destSession = app.dotrec.recorder.OutputWriter.create(activity)
                if (destSession == null) {
                    runCatching { srcPfd.close() }
                    result.success(null)
                    return
                }
                Thread {
                    val ok = app.dotrec.util.VideoTrimmer.trim(
                        srcPfd.fileDescriptor,
                        destSession.pfd.fileDescriptor,
                        startMs * 1000L,
                        endMs * 1000L,
                    )
                    runCatching { srcPfd.close() }
                    runCatching { destSession.pfd.close() }
                    app.dotrec.recorder.OutputWriter.finish(activity, destSession.uri, ok)
                    activity.runOnUiThread {
                        result.success(if (ok) destSession.uri.toString() else null)
                    }
                }.start()
            }
            else -> result.notImplemented()
        }
    }

    private fun listDotRec(activity: Activity): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        val proj = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.DATE_ADDED,
        )
        // TODO(verify): столбец DURATION доступен с API 29 — minSdk 29 ок.
        val cur = activity.contentResolver.query(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            proj,
            "${MediaStore.Video.Media.DISPLAY_NAME} LIKE ?",
            arrayOf("DotRec_%"),
            "${MediaStore.Video.Media.DATE_ADDED} DESC",
        ) ?: return out
        cur.use {
            val idI = it.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
            val nI = it.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
            val dI = it.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
            val sI = it.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
            val cI = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)
            while (it.moveToNext()) {
                val uri = ContentUris.withAppendedId(
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                    it.getLong(idI),
                ).toString()
                out += mapOf(
                    "uri" to uri,
                    "name" to it.getString(nI),
                    "durationMs" to it.getLong(dI),
                    "sizeBytes" to it.getLong(sI),
                    "createdAtMs" to it.getLong(cI) * 1000,
                )
            }
        }
        return out
    }

    private fun freeBytes(): Long = try {
        StatFs(Environment.getDataDirectory().path).availableBytes
    } catch (_: Exception) {
        0L
    }

    fun dispose() = scope.cancel()
}
