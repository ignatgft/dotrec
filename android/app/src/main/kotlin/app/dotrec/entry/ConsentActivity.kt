package app.dotrec.entry

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import app.dotrec.recorder.RecorderService
import app.dotrec.recorder.RecorderState
import app.dotrec.recorder.RecorderStateStore
import app.dotrec.settings.SettingsStore

/**
 * Прозрачная Activity для согласия MediaProjection.
 * Разрешения — только в момент нужды (FR-ONB-02): микрофон при включённом
 * микрофоне, уведомления при первой записи. Токен Android 14+ одноразовый.
 */
class ConsentActivity : Activity() {
    private var needMic = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        needMic = (SettingsStore(this).getAll()["mic"] as? Boolean) ?: false
        requestNotificationsIfNeeded()
    }

    private fun requestNotificationsIfNeeded() {
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            // Отказ не блокирует запись: уведомление foreground-сервиса показывается всё равно.
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQ_NOTIF)
        } else {
            requestMicIfNeeded()
        }
    }

    private fun requestMicIfNeeded() {
        if (needMic && checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), REQ_MIC)
        } else {
            requestCapture()
        }
    }

    private fun requestCapture() {
        try {
            val mpm = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            val intentToLaunch = if (Build.VERSION.SDK_INT >= 34) {
                val cfg = android.media.projection.MediaProjectionConfig.createConfigForUserChoice()
                mpm.createScreenCaptureIntent(cfg)
            } else {
                @Suppress("DEPRECATION")
                mpm.createScreenCaptureIntent()
            }
            @Suppress("DEPRECATION")
            startActivityForResult(intentToLaunch, REQ_CAPTURE)
        } catch (_: Exception) {
            runCatching { RecorderStateStore.set(RecorderState.Failed("consent_denied")) }
            finish()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            REQ_NOTIF -> requestMicIfNeeded()
            REQ_MIC -> {
                if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
                    requestCapture()
                } else {
                    // UI объяснит последствия и предложит системные настройки (FR-ONB-03).
                    val cur = RecorderStateStore.state.value
                    if (cur is RecorderState.Failed) {
                        runCatching { RecorderStateStore.set(RecorderState.Idle) }
                    }
                    runCatching { RecorderStateStore.set(RecorderState.Starting) }
                    runCatching { RecorderStateStore.set(RecorderState.Failed("audio_error")) }
                    finish()
                }
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_CAPTURE) {
            if (resultCode == RESULT_OK && data != null) {
                val start = Intent(this, RecorderService::class.java)
                    .setAction(RecorderService.ACTION_START)
                    .putExtra(RecorderService.EXTRA_RESULT_CODE, resultCode)
                    .putExtra(RecorderService.EXTRA_RESULT_DATA, data)
                startForegroundService(start)
            } else {
                val cur = RecorderStateStore.state.value
                if (cur is RecorderState.Failed) {
                    runCatching { RecorderStateStore.set(RecorderState.Idle) }
                }
                runCatching { RecorderStateStore.set(RecorderState.Starting) }
                runCatching { RecorderStateStore.set(RecorderState.Failed("consent_denied")) }
            }
        }
        finish()
    }

    companion object {
        private const val REQ_CAPTURE = 7001
        private const val REQ_MIC = 7002
        private const val REQ_NOTIF = 7003
    }
}
