package app.dotrec.util

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

class FileNamerTest {
    @Test
    fun `name format`() {
        val cal = Calendar.getInstance().apply {
            set(2026, Calendar.OCTOBER, 9, 17, 15, 0)
            set(Calendar.MILLISECOND, 0)
        }
        assertEquals("DotRec_20261009_171500.mp4", FileNamer.name(cal.time))
    }

    @Test
    fun `pattern validation`() {
        assertTrue(FileNamer.isValid("DotRec_20261009_171500.mp4"))
        assertFalse(FileNamer.isValid("video.mp4"))
        assertFalse(FileNamer.isValid("DotRec_2026.mp4"))
    }
}
