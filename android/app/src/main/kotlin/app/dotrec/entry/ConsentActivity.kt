package app.dotrec.entry

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import app.dotrec.recorder.RecorderService
import app.dotrec.recorder.RecorderState
import app.dotrec.recorder.RecorderStateStore

/**
 * Прозрачная Activity для согласия MediaProjection.
 * MediaProjection требует startActivityForResult; плитка и виджет не могут сами.
 */
class ConsentActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val mpm = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            @Suppress("DEPRECATION")
            startActivityForResult(mpm.createScreenCaptureIntent(), REQ)
        } catch (_: Exception) {
            runCatching { RecorderStateStore.set(RecorderState.Failed("consent_denied")) }
            finish()
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ) {
            if (resultCode == RESULT_OK && data != null) {
                val start = Intent(this, RecorderService::class.java)
                    .setAction(RecorderService.ACTION_START)
                    .putExtra(RecorderService.EXTRA_RESULT_CODE, resultCode)
                    .putExtra(RecorderService.EXTRA_RESULT_DATA, data)
                startForegroundService(start)
            } else {
                runCatching { RecorderStateStore.set(RecorderState.Failed("consent_denied")) }
            }
        }
        finish()
    }

    companion object {
        private const val REQ = 7001
    }
}
