package app.dotrec.util

import android.content.Context
import android.media.MediaCodecList
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.view.Display

/** Замеры устройства: экран, частоты, HEVC, свободное место (см. docs/04). */
object DeviceCaps {
    fun collect(context: Context, display: Display?): Map<String, Any?> {
        val metrics = context.resources.displayMetrics
        val screenW = metrics.widthPixels
        val screenH = metrics.heightPixels
        val modes = if (Build.VERSION.SDK_INT >= 23 && display != null) {
            display.supportedModes.map { it.refreshRate.toInt() }.distinct().sorted()
        } else {
            listOf(60)
        }
        // TODO(verify): Display.getSupportedModes доступен с API 23; проверить на API 29+.
        val maxHz = modes.maxOrNull() ?: 60
        val hevc = MediaCodecList(MediaCodecList.REGULAR_CODECS)
            .codecInfos
            .any { info ->
                info.isEncoder && info.supportedTypes.any {
                    it.equals("video/hevc", ignoreCase = true)
                }
            }
        val available = SizeCalc.availableTargets(screenW, screenH)
        val free = try {
            val path = Environment.getDataDirectory()
            StatFs(path.path).availableBytes
        } catch (_: Exception) {
            0L
        }
        return mapOf(
            "screenWidth" to screenW,
            "screenHeight" to screenH,
            "supportedRefreshHz" to modes,
            "maxRefreshHz" to maxHz,
            "hevcSupported" to hevc,
            "availableResolutions" to available,
            "freeBytes" to free,
        )
    }
}
