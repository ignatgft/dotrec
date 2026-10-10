package app.dotrec.util

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Имена файлов: DotRec_YYYYMMDD_HHmmss.mp4 (FR-REC-08). */
object FileNamer {
    private val PATTERN = Regex("""^DotRec_\d{8}_\d{6}\.mp4$""")

    fun name(at: Date = Date()): String {
        val f = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US)
        return "DotRec_${f.format(at)}.mp4"
    }

    fun isValid(name: String): Boolean = PATTERN.matches(name)
}
