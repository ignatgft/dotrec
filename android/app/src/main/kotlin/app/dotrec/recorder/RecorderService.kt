package app.dotrec.recorder

import android.Manifest
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.StatFs
import android.os.SystemClock
import android.util.Log
import app.dotrec.entry.NotificationFactory
import app.dotrec.entry.OverlayPill
import app.dotrec.entry.RecordWidgetProvider
import app.dotrec.settings.SettingsStore
import app.dotrec.util.BitrateCalc
import app.dotrec.util.SizeCalc
import java.io.FileDescriptor

/**
 * M1 T-08: запись видео через MediaProjection + MediaRecorder + VirtualDisplay.
 * Порядок настройки MediaRecorder строгий (см. docs/04). Видео не проходит через Dart.
 * Каждый шаг освобождения — в своём try/catch, всё в finally (чек-лист docs/04).
 */
class RecorderService : Service() {

    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var recorder: MediaRecorder? = null
    private var codec: CodecPipeline? = null
    private var session: OutputWriter.Session? = null
    private var usedSysAudio = false

    private val main = Handler(Looper.getMainLooper())

    private var pendingResultCode: Int = 0
    private var pendingData: Intent? = null
    private var countdownLeft: Int = 0

    private var segmentStart: Long = 0
    private var recordedMs: Long = 0
    private var ticking = false
    private var tickCount = 0
    private var densityDpi: Int = 0

    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            // Система или пользователь остановили проекцию: корректно завершить.
            stopRecording(reason = "projection_stopped")
        }

        // Проверено: resize виртуального дисплея с чётными сторонами под текущую плотность.
        override fun onCapturedContentResize(width: Int, height: Int) {
            val vd = virtualDisplay
            if (vd != null && width > 0 && height > 0) {
                runCatching { vd.resize(width - width % 2, height - height % 2, densityDpi) }
            }
        }
    }

    private val countdownStep = object : Runnable {
        override fun run() {
            if (countdownLeft <= 0) {
                beginCapture()
                return
            }
            runCatching { RecorderStateStore.set(RecorderState.Countdown(countdownLeft)) }
            countdownLeft--
            main.postDelayed(this, 1000)
        }
    }

    private val ticker = object : Runnable {
        override fun run() {
            if (!ticking) return
            val cur = RecorderStateStore.state.value
            if (cur is RecorderState.Recording) {
                val elapsed = recordedMs + (SystemClock.elapsedRealtime() - segmentStart)
                runCatching { RecorderStateStore.set(RecorderState.Recording(elapsed)) }
                runCatching { OverlayPill.update(elapsed, false) }
                tickCount++
                // NFR-REL-02: при критически малом месте — остановить и сохранить.
                if (tickCount % 5 == 0 && freeBytes() < MIN_FREE_CRITICAL) {
                    stopRecording(reason = null)
                    return
                }
            }
            main.postDelayed(this, 1000)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startRecording(intent)
            ACTION_STOP -> stopRecording(reason = null)
            ACTION_PAUSE -> pauseRecording()
            ACTION_RESUME -> resumeRecording()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        // NFR-REL-01: процесс убит — уже записанное финализируем как можем.
        val cur = RecorderStateStore.state.value
        if (cur is RecorderState.Recording || cur is RecorderState.Paused) {
            runCatching { stopRecording(reason = null) }
        } else {
            runCatching { releaseAll() }
        }
        super.onDestroy()
    }

    // ---------- запуск ----------

    private fun startRecording(intent: Intent) {
        val cur = RecorderStateStore.state.value
        Log.d(TAG, "startRecording state=$cur")
        if (cur is RecorderState.Recording || cur is RecorderState.Starting ||
            cur is RecorderState.Countdown || cur is RecorderState.Saving
        ) {
            return
        }
        runCatching { RecorderStateStore.set(RecorderState.Starting) }
        // СНАЧАЛА foreground с типом mediaProjection, только потом проекция.
        startForegroundNotif(paused = false)
        Log.d(TAG, "foreground started, free=${freeBytes()}")

        val settings = SettingsStore(this).getAll()
        if (freeBytes() < MIN_FREE_START) {
            fail("low_storage")
            return
        }
        pendingResultCode = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
        pendingData = getResultData(intent)
        if (pendingData == null) {
            fail("consent_denied")
            return
        }
        val mic = settings["mic"] as? Boolean ?: false
        if (mic && checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            fail("audio_error")
            return
        }

        recordedMs = 0
        segmentStart = 0
        tickCount = 0
        val countdown = (settings["countdownSec"] as? Number)?.toInt() ?: 0
        if (countdown > 0) {
            countdownLeft = countdown
            main.post(countdownStep)
        } else {
            beginCapture()
        }
    }

    private fun beginCapture() {
        runCatching { RecorderStateStore.set(RecorderState.Starting) }
        val settings = SettingsStore(this).getAll()
        val metrics = resources.displayMetrics
        densityDpi = metrics.densityDpi
        val cfg = pickConfig(
            res = (settings["resolution"] as? Number)?.toInt() ?: 1080,
            fps = (settings["fps"] as? Number)?.toInt() ?: 60,
            bitrateMbps = (settings["bitrateMbps"] as? Number)?.toInt() ?: 20,
            codec = (settings["codec"] as? String) ?: "h264",
            screenW = metrics.widthPixels,
            screenH = metrics.heightPixels,
        )
        if (cfg == null) {
            fail("encoder_error")
            return
        }
        val mic = settings["mic"] as? Boolean ?: false
        // T-24: звук системы — пайплайн MediaCodec + MediaMuxer, иначе MediaRecorder.
        val sysAudio = (settings["systemAudio"] as? Boolean) == true
        usedSysAudio = sysAudio

        // Токен Android 14+ одноразовый: получаем проекцию здесь, не кешируем data.
        val mpm = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val data = pendingData
        pendingData = null
        val proj = try {
            mpm.getMediaProjection(pendingResultCode, data!!)
        } catch (_: Exception) {
            null
        }
        if (proj == null) {
            fail("consent_denied")
            return
        }
        projection = proj
        // На API 34+ колбэк регистрируется ДО createVirtualDisplay, иначе исключение.
        runCatching { proj.registerCallback(projectionCallback, main) }

        val s = OutputWriter.create(this)
        if (s == null) {
            fail("io_error")
            return
        }
        session = s

        val surface: android.view.Surface
        if (sysAudio) {
            val pipe = CodecPipeline()
            try {
                surface = pipe.configure(
                    proj,
                    cfg.w,
                    cfg.h,
                    cfg.fps,
                    cfg.bitrateBps,
                    cfg.mime,
                    mic,
                    s.pfd.fileDescriptor,
                )
            } catch (_: Exception) {
                runCatching { pipe.release() }
                fail("audio_error")
                return
            }
            codec = pipe
        } else {
            val rec = try {
                buildRecorder(cfg, mic, s.pfd.fileDescriptor)
            } catch (_: Exception) {
                null
            }
            if (rec == null) {
                fail("encoder_error")
                return
            }
            recorder = rec
            try {
                rec.prepare()
            } catch (_: Exception) {
                fail("encoder_error")
                return
            }
            surface = rec.surface
        }
        // MediaProjection.createVirtualDisplay: порядок (flags, surface).
        val vd = try {
            proj.createVirtualDisplay(
                "DotRec",
                cfg.w,
                cfg.h,
                densityDpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                surface,
                null,
                main,
            )
        } catch (_: Exception) {
            null
        }
        if (vd == null) {
            fail("encoder_error")
            return
        }
        virtualDisplay = vd
        try {
            codec?.start() ?: recorder?.start()
        } catch (_: Exception) {
            fail("encoder_error")
            return
        }
        segmentStart = SystemClock.elapsedRealtime()
        Log.d(TAG, "capture started ${cfg.w}x${cfg.h}@${cfg.fps} ${cfg.bitrateBps}bps ${cfg.mime} sysAudio=$sysAudio")
        app.dotrec.link.LinkServer.onKeyframeRequested = {
            codec?.requestKeyframe()
        }
        app.dotrec.link.LinkServer.onBitrateChanged = { newBps ->
            codec?.setBitrate(newBps)
        }
        runCatching { RecorderStateStore.set(RecorderState.Recording(0)) }
        runCatching { RecordWidgetProvider.updateAll(this) }
        if ((settings["overlayPill"] as? Boolean) == true) {
            runCatching { OverlayPill.show(this) }
        }
        ticking = true
        main.post(ticker)
    }

    private data class CaptureConfig(
        val w: Int,
        val h: Int,
        val fps: Int,
        val bitrateBps: Int,
        val mime: String,
    )

    /** Ближайшая поддерживаемая конфигурация; null если энкодер не тянет ничего. */
    private fun pickConfig(
        res: Int,
        fps: Int,
        bitrateMbps: Int,
        codec: String,
        screenW: Int,
        screenH: Int,
    ): CaptureConfig? {
        val mimes = if (codec == "hevc") {
            listOf("video/hevc", "video/avc")
        } else {
            listOf("video/avc")
        }
        val targets = (listOf(res) + listOf(1440, 1080, 720)).distinct().filter { it <= res }
        for (mime in mimes) {
            val caps = videoCaps(mime)
            for (t in targets) {
                val (w, h) = SizeCalc.fit(screenW, screenH, t) ?: continue
                if (caps != null && !caps.isSizeSupported(w, h)) continue
                var f = fps.coerceIn(15, 120)
                if (caps != null) {
                    f = try {
                        // Range<Integer>: платформенный тип, приводим явно.
                        val range = caps.getSupportedFrameRatesFor(w, h)
                        f.coerceIn(range.lower.toInt(), range.upper.toInt())
                    } catch (_: Exception) {
                        f
                    }
                }
                var br = if (bitrateMbps in ALLOWED_BR) {
                    bitrateMbps
                } else {
                    BitrateCalc.defaultMbps(w, h, f, mime == "video/hevc")
                }
                if (caps != null) {
                    br = try {
                        val r = caps.bitrateRange
                        (br * 1_000_000).coerceIn(r.lower.toInt(), r.upper.toInt()) / 1_000_000
                    } catch (_: Exception) {
                        br
                    }
                    if (br <= 0) br = 4
                }
                return CaptureConfig(w, h, f, br * 1_000_000, mime)
            }
        }
        return null
    }

    private fun videoCaps(mime: String): MediaCodecInfo.VideoCapabilities? {
        return try {
            MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos
                .firstOrNull { it.isEncoder && mime in it.supportedTypes }
                ?.getCapabilitiesForType(mime)?.videoCapabilities
        } catch (_: Exception) {
            null
        }
    }

    /** Строгий порядок вызовов MediaRecorder (docs/04). */
    private fun buildRecorder(cfg: CaptureConfig, mic: Boolean, fd: FileDescriptor): MediaRecorder {
        val rec = if (Build.VERSION.SDK_INT >= 31) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
        if (mic) rec.setAudioSource(MediaRecorder.AudioSource.MIC)
        rec.setVideoSource(MediaRecorder.VideoSource.SURFACE)
        rec.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        if (mic) rec.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        rec.setVideoEncoder(
            if (cfg.mime == "video/hevc") {
                MediaRecorder.VideoEncoder.HEVC
            } else {
                MediaRecorder.VideoEncoder.H264
            },
        )
        rec.setVideoSize(cfg.w, cfg.h)
        rec.setVideoFrameRate(cfg.fps)
        rec.setVideoEncodingBitRate(cfg.bitrateBps)
        rec.setOutputFile(fd)
        return rec
    }

    // ---------- пауза / продолжение (FR-REC-06) ----------

    private fun pauseRecording() {
        val cur = RecorderStateStore.state.value
        Log.d(TAG, "pause cur=$cur")
        if (cur is RecorderState.Recording) {
            recordedMs += SystemClock.elapsedRealtime() - segmentStart
            runCatching { codec?.pause() ?: recorder?.pause() }
            Log.d(TAG, "paused at $recordedMs")
            runCatching { RecorderStateStore.set(RecorderState.Paused(recordedMs)) }
            runCatching { RecordWidgetProvider.updateAll(this) }
            runCatching { OverlayPill.update(recordedMs, true) }
            startForegroundNotif(paused = true)
        }
    }

    private fun resumeRecording() {
        val cur = RecorderStateStore.state.value
        Log.d(TAG, "resume cur=$cur")
        if (cur is RecorderState.Paused) {
            runCatching { codec?.resume() ?: recorder?.resume() }
            segmentStart = SystemClock.elapsedRealtime()
            runCatching { RecorderStateStore.set(RecorderState.Recording(cur.elapsedMs)) }
            runCatching { RecordWidgetProvider.updateAll(this) }
            runCatching { OverlayPill.update(cur.elapsedMs, false) }
            startForegroundNotif(paused = false)
        }
    }

    // ---------- остановка (чек-лист docs/04) ----------

    private fun stopRecording(reason: String?) {
        main.removeCallbacks(countdownStep)
        main.removeCallbacks(ticker)
        ticking = false
        val cur = RecorderStateStore.state.value
        if (cur is RecorderState.Idle || cur is RecorderState.Failed) return
        if ((cur is RecorderState.Countdown || cur is RecorderState.Starting) && recorder == null) {
            runCatching { RecorderStateStore.set(RecorderState.Idle) }
            finishService()
            return
        }
        val totalMs = when (cur) {
            is RecorderState.Recording -> recordedMs + (SystemClock.elapsedRealtime() - segmentStart)
            is RecorderState.Paused -> recordedMs
            else -> recordedMs
        }
        runCatching { RecorderStateStore.set(RecorderState.Saving) }
        var stopped = false
        Log.d(TAG, "stopRecording cur=$cur reason=$reason")
        try {
            stopped = try {
                val c = codec
                if (c != null) {
                    c.stop()
                } else {
                    recorder?.stop()
                    recorder != null
                }
            } catch (e: Exception) {
                Log.d(TAG, "stop threw: $e")
                false
            }
            try {
                virtualDisplay?.release()
            } catch (_: Exception) {
            }
            try {
                projection?.unregisterCallback(projectionCallback)
            } catch (_: Exception) {
            }
            try {
                projection?.stop()
            } catch (_: Exception) {
            }
            val s = session
            OutputWriter.close(s)
            if (s != null && stopped) {
                OutputWriter.finish(this, s.uri, true)
                val size = OutputWriter.sizeBytes(this, s.uri)
                Log.d(TAG, "saved uri=${s.uri} size=$size ms=$totalMs")
                RecordingEvents.saved(s.uri.toString(), totalMs, size)
                runCatching {
                    // FR-AUD-04: при звуке системы честно предупреждаем:
                    // часть приложений могла запретить захват.
                    NotificationFactory.notifySaved(this, s.uri, usedSysAudio)
                }
                runCatching { RecorderStateStore.set(RecorderState.Idle) }
            } else if (s != null) {
                OutputWriter.finish(this, s.uri, false)
                runCatching { RecorderStateStore.set(RecorderState.Failed(reason ?: "io_error")) }
            } else {
                runCatching { RecorderStateStore.set(RecorderState.Failed(reason ?: "unknown")) }
            }
        } finally {
            runCatching { OverlayPill.hide() }
            runCatching { RecordWidgetProvider.updateAll(this) }
            finishService()
        }
        projection = null
        virtualDisplay = null
        recorder = null
        codec = null
        session = null
        pendingData = null
    }

    private fun fail(code: String) {
        Log.d(TAG, "fail($code)")
        main.removeCallbacks(countdownStep)
        main.removeCallbacks(ticker)
        ticking = false
        runCatching { OverlayPill.hide() }
        runCatching { RecordWidgetProvider.updateAll(this) }
        releaseAll()
        runCatching { RecorderStateStore.set(RecorderState.Failed(code)) }
        finishService()
    }

    private fun releaseAll() {
        try {
            codec?.release()
        } catch (_: Exception) {
        }
        try {
            recorder?.release()
        } catch (_: Exception) {
        }
        try {
            virtualDisplay?.release()
        } catch (_: Exception) {
        }
        try {
            projection?.unregisterCallback(projectionCallback)
        } catch (_: Exception) {
        }
        try {
            projection?.stop()
        } catch (_: Exception) {
        }
        val s = session
        OutputWriter.close(s)
        if (s != null) OutputWriter.finish(this, s.uri, false)
        projection = null
        virtualDisplay = null
        recorder = null
        codec = null
        session = null
        pendingData = null
        app.dotrec.link.LinkServer.onKeyframeRequested = null
        app.dotrec.link.LinkServer.onBitrateChanged = null
    }

    private fun finishService() {
        try {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } catch (_: Exception) {
        }
        stopSelf()
    }

    private fun startForegroundNotif(paused: Boolean) {
        val n = NotificationFactory.recording(this, paused)
        startForeground(
            NOTIFICATION_ID,
            n,
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION,
        )
    }

    private fun getResultData(intent: Intent): Intent? {
        return if (Build.VERSION.SDK_INT >= 33) {
            // Проверено: типизированный getParcelableExtra на API 33+.
            intent.getParcelableExtra(EXTRA_RESULT_DATA, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(EXTRA_RESULT_DATA)
        }
    }

    private fun freeBytes(): Long {
        return try {
            StatFs(Environment.getDataDirectory().path).availableBytes
        } catch (_: Exception) {
            0
        }
    }

    companion object {
        const val TAG = "DotRec"
        const val ACTION_START = "app.dotrec.action.START"
        const val ACTION_STOP = "app.dotrec.action.STOP"
        const val ACTION_PAUSE = "app.dotrec.action.PAUSE"
        const val ACTION_RESUME = "app.dotrec.action.RESUME"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        const val NOTIFICATION_ID = 1001
        const val MIN_FREE_START = 200L * 1024 * 1024
        const val MIN_FREE_CRITICAL = 100L * 1024 * 1024
        private val ALLOWED_BR = setOf(4, 8, 12, 20, 40)
    }
}
