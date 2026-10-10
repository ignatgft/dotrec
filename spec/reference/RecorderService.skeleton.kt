package app.dotrec.recorder

// СКЕЛЕТ. Каждое место с TODO(verify) нужно сверить с актуальной документацией Android
// для соответствующего API уровня, прежде чем считать готовым.

import android.app.Service
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper

class RecorderService : Service() {

    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var recorder: MediaRecorder? = null
    private val main = Handler(Looper.getMainLooper())

    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            // Система или пользователь остановили проекцию: завершить запись корректно.
            stopRecording(reason = "projection_stopped")
        }
        // TODO(verify): onCapturedContentResize / onCapturedContentVisibilityChanged (API 34+)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startRecording(intent)
            ACTION_STOP -> stopRecording(reason = null)
            ACTION_PAUSE -> recorder?.pause()
            ACTION_RESUME -> recorder?.resume()
        }
        return START_NOT_STICKY
    }

    private fun startRecording(intent: Intent) {
        RecorderStateStore.set(RecorderState.Starting)

        // 1) СНАЧАЛА foreground с типом mediaProjection.
        // startForeground(NOTIFICATION_ID, NotificationFactory.recording(this), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        // TODO(verify): сигнатура и константа для API 29/34.

        // 2) Только потом получаем проекцию из результата ConsentActivity.
        val mpm = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
        val data: Intent = intent.getParcelableExtra(EXTRA_RESULT_DATA) ?: return fail("consent_denied")
        // TODO(verify): getParcelableExtra deprecated на API 33, использовать типизированную версию.
        projection = mpm.getMediaProjection(resultCode, data)

        // 3) На API 34+ колбэк регистрируется ДО createVirtualDisplay.
        projection?.registerCallback(projectionCallback, main)

        // 4) Настройка MediaRecorder в строгом порядке (см. docs/04).
        // 5) createVirtualDisplay(..., recorder.surface, ...), затем recorder.start().
        // 6) RecorderStateStore.set(Recording(0)) и запуск тикера elapsedMs раз в секунду.
    }

    private fun stopRecording(reason: String?) {
        // Чек-лист из docs/04: каждый шаг в своём try/catch, всё в finally.
        // recorder.stop(); virtualDisplay.release(); projection.unregisterCallback; projection.stop();
        // закрыть ParcelFileDescriptor; IS_PENDING = 0; stopForeground; stopSelf.
        RecorderStateStore.set(RecorderState.Saving)
        // ... по завершении: RecorderStateStore.set(RecorderState.Idle)
    }

    private fun fail(code: String) {
        RecorderStateStore.set(RecorderState.Failed(code))
        stopSelf()
    }

    companion object {
        const val ACTION_START = "app.dotrec.action.START"
        const val ACTION_STOP = "app.dotrec.action.STOP"
        const val ACTION_PAUSE = "app.dotrec.action.PAUSE"
        const val ACTION_RESUME = "app.dotrec.action.RESUME"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        const val NOTIFICATION_ID = 1001
    }
}
