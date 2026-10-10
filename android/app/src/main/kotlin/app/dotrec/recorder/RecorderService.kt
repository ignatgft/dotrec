package app.dotrec.recorder

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import app.dotrec.entry.NotificationFactory

/**
 * BETA-заглушка T-08: каркас сервиса с машиной состояний и тикером.
 * Реальный пайплайн MediaProjection + MediaRecorder + VirtualDisplay —
 * задача M1 (см. docs/04, reference/RecorderService.skeleton.kt).
 * Каждый шаг освобождения — в своём try/catch, всё в finally.
 */
class RecorderService : Service() {

    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var recorder: MediaRecorder? = null
    private val main = Handler(Looper.getMainLooper())
    private var startRealtime: Long = 0
    private var pausedAccum: Long = 0
    private var pauseStart: Long = 0
    private var ticking = false

    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            stopRecording(reason = "projection_stopped")
        }
        // TODO(verify): onCapturedContentResize / onCapturedContentVisibilityChanged (API 34+)
    }

    private val ticker = object : Runnable {
        override fun run() {
            if (!ticking) return
            val cur = RecorderStateStore.state.value
            val elapsed = currentElapsed()
            if (cur is RecorderState.Recording) {
                runCatching { RecorderStateStore.set(RecorderState.Recording(elapsed)) }
                startForegroundNotif(paused = false)
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

    private fun currentElapsed(): Long {
        val cur = RecorderStateStore.state.value
        return when (cur) {
            is RecorderState.Paused -> pausedAccum
            else -> {
                if (startRealtime == 0L) return pausedAccum
                val extra = if (pauseStart != 0L) 0 else 0
                pausedAccum + (SystemClock.elapsedRealtime() - startRealtime) + extra
            }
        }
    }

    private fun startForegroundNotif(paused: Boolean) {
        val n = NotificationFactory.recording(this, paused)
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(
                NOTIFICATION_ID,
                n,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION,
            )
        } else {
            @Suppress("DEPRECATION")
            startForeground(NOTIFICATION_ID, n)
        }
    }

    private fun startRecording(intent: Intent) {
        val cur = RecorderStateStore.state.value
        if (cur is RecorderState.Recording || cur is RecorderState.Starting) return
        runCatching { RecorderStateStore.set(RecorderState.Starting) }
        startForegroundNotif(paused = false)

        // TODO(M1 T-08): получить MediaProjection из resultCode/data,
        // registerCallback ДО createVirtualDisplay на API 34+,
        // настроить MediaRecorder в строгом порядке, VirtualDisplay, start().
        // Токен Android 14+ одноразовый — не кешировать data.
        val countdown = intent.getIntExtra(EXTRA_COUNTDOWN, 0)
        startRealtime = SystemClock.elapsedRealtime()
        pausedAccum = 0
        pauseStart = 0
        if (countdown > 0) {
            runCatching { RecorderStateStore.set(RecorderState.Countdown(countdown)) }
            main.postDelayed({ beginCapture() }, (countdown * 1000).toLong())
        } else {
            beginCapture()
        }
    }

    private fun beginCapture() {
        runCatching { RecorderStateStore.set(RecorderState.Recording(0)) }
        ticking = true
        main.post(ticker)
    }

    private fun pauseRecording() {
        val cur = RecorderStateStore.state.value
        if (cur is RecorderState.Recording) {
            pausedAccum = cur.elapsedMs
            runCatching { recorder?.pause() }
            runCatching { RecorderStateStore.set(RecorderState.Paused(pausedAccum)) }
            startForegroundNotif(paused = true)
        }
    }

    private fun resumeRecording() {
        val cur = RecorderStateStore.state.value
        if (cur is RecorderState.Paused) {
            startRealtime = SystemClock.elapsedRealtime()
            runCatching { recorder?.resume() }
            runCatching { RecorderStateStore.set(RecorderState.Recording(cur.elapsedMs)) }
            startForegroundNotif(paused = false)
        }
    }

    private fun stopRecording(reason: String?) {
        ticking = false
        main.removeCallbacks(ticker)
        runCatching { RecorderStateStore.set(RecorderState.Saving) }
        try {
            try { recorder?.stop() } catch (_: Exception) { }
            try { virtualDisplay?.release() } catch (_: Exception) { }
            try { projection?.unregisterCallback(projectionCallback) } catch (_: Exception) { }
            try { projection?.stop() } catch (_: Exception) { }
            // TODO(M1): закрыть ParcelFileDescriptor, снять IS_PENDING, уведомление «Запись сохранена».
            if (reason != null) {
                runCatching { RecorderStateStore.set(RecorderState.Failed(reason)) }
                runCatching { RecorderStateStore.set(RecorderState.Idle) }
            } else {
                runCatching { RecorderStateStore.set(RecorderState.Idle) }
            }
        } finally {
            try { stopForeground(STOP_FOREGROUND_REMOVE) } catch (_: Exception) { }
            stopSelf()
        }
        projection = null
        virtualDisplay = null
        recorder = null
    }

    companion object {
        const val ACTION_START = "app.dotrec.action.START"
        const val ACTION_STOP = "app.dotrec.action.STOP"
        const val ACTION_PAUSE = "app.dotrec.action.PAUSE"
        const val ACTION_RESUME = "app.dotrec.action.RESUME"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        const val EXTRA_COUNTDOWN = "countdown"
        const val NOTIFICATION_ID = 1001
    }
}
