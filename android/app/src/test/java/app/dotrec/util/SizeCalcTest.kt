package app.dotrec.util

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertNotNull
import org.junit.Test

class SizeCalcTest {
    @Test
    fun `1080x2400 to 720 keeps even sides`() {
        val (w, h) = SizeCalc.fit(1080, 2400, 720)!!
        assertEquals(0, w % 2)
        assertEquals(0, h % 2)
    }

    @Test
    fun `screen smaller than target is null`() {
        assertNull(SizeCalc.fit(720, 1280, 1080))
        assertNotNull(SizeCalc.fit(1080, 2400, 1080))
        assertNull(SizeCalc.fit(480, 800, 720))
    }

    @Test
    fun `odd input rounds down to even`() {
        val (w, h) = SizeCalc.fit(1081, 2401, 720)!!
        assertEquals(0, w % 2)
        assertEquals(0, h % 2)
    }

    @Test
    fun `available targets hide unsupported`() {
        assertEquals(listOf(720), SizeCalc.availableTargets(720, 1280))
        assertEquals(listOf(720, 1080), SizeCalc.availableTargets(1080, 2400))
        assertEquals(listOf(720, 1080, 1440), SizeCalc.availableTargets(1440, 3120))
    }
}
