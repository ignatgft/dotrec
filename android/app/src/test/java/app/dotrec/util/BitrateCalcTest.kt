package app.dotrec.util

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BitrateCalcTest {
    @Test
    fun `1080x2400 60fps h264 follows formula to 12`() {
        assertEquals(12, BitrateCalc.defaultMbps(1080, 2400, 60, false))
    }

    @Test
    fun `720p 30fps h264 is 4`() {
        assertEquals(4, BitrateCalc.defaultMbps(720, 1280, 30, false))
    }

    @Test
    fun `hevc is not higher than h264`() {
        val h264 = BitrateCalc.defaultMbps(1080, 2400, 60, false)
        val hevc = BitrateCalc.defaultMbps(1080, 2400, 60, true)
        assertTrue(hevc <= h264)
    }

    @Test
    fun `1440 wide 60fps h264 is 20`() {
        assertEquals(20, BitrateCalc.defaultMbps(1440, 3120, 60, false))
    }

    @Test
    fun `only step values returned`() {
        val steps = setOf(4, 8, 12, 20, 40)
        for (w in listOf(720, 1080, 1440)) {
            for (f in listOf(30, 60, 90)) {
                assertTrue(steps.contains(BitrateCalc.defaultMbps(w, w * 2, f, false)))
            }
        }
    }
}
