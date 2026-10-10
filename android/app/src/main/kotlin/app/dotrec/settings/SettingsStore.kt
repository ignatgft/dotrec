package app.dotrec.settings

import android.content.Context
import android.content.SharedPreferences

/** Настройки. Источник правды — Kotlin (плитке нужны настройки без Flutter). */
class SettingsStore(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun getAll(): Map<String, Any?> = mapOf(
        "resolution" to prefs.getInt("resolution", 1080),
        "fps" to prefs.getInt("fps", 60),
        "bitrateMbps" to prefs.getInt("bitrateMbps", 20),
        "codec" to (prefs.getString("codec", "h264") ?: "h264"),
        "mic" to prefs.getBoolean("mic", false),
        "systemAudio" to prefs.getBoolean("systemAudio", false),
        "countdownSec" to prefs.getInt("countdownSec", 3),
        "preset" to (prefs.getString("preset", "balanced") ?: "balanced"),
        "overlayPill" to prefs.getBoolean("overlayPill", false),
        "themeMode" to (prefs.getString("themeMode", "system") ?: "system"),
    )

    fun saveAll(m: Map<String, Any?>) {
        val validRes = setOf(720, 1080, 1440)
        val validFps = setOf(30, 60, 90)
        val validBr = setOf(4, 8, 12, 20, 40)
        val res = (m["resolution"] as? Number)?.toInt() ?: 1080
        val fps = (m["fps"] as? Number)?.toInt() ?: 60
        require(res in validRes) { "invalid resolution" }
        require(fps in validFps) { "invalid fps" }
        val br = (m["bitrateMbps"] as? Number)?.toInt() ?: 20
        require(br in validBr) { "invalid bitrate" }
        prefs.edit()
            .putInt("resolution", res)
            .putInt("fps", fps)
            .putInt("bitrateMbps", br)
            .putString("codec", (m["codec"] as? String) ?: "h264")
            .putBoolean("mic", (m["mic"] as? Boolean) ?: false)
            .putBoolean("systemAudio", (m["systemAudio"] as? Boolean) ?: false)
            .putInt("countdownSec", (m["countdownSec"] as? Number)?.toInt() ?: 3)
            .putString("preset", (m["preset"] as? String) ?: "balanced")
            .putBoolean("overlayPill", (m["overlayPill"] as? Boolean) ?: false)
            .putString("themeMode", (m["themeMode"] as? String) ?: "system")
            .apply()
    }

    companion object {
        const val PREFS = "dotrec_settings"
    }
}
