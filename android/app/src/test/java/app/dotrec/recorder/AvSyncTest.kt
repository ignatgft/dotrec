package app.dotrec.recorder

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class AvSyncTest {
    @Test
    fun `video pts subtracts start and pauses`() {
        assertEquals(1000L, AvSync.videoPts(5000, 1000, 3000))
        assertEquals(0L, AvSync.videoPts(1000, 1000, 500))
    }

    @Test
    fun `audio pts from frame counter`() {
        assertEquals(1_000_000L, AvSync.audioPts(44100, 44100))
        assertEquals(0L, AvSync.audioPts(0, 44100))
    }
}

class PcmMixerTest {
    @Test
    fun `silence plus silence`() {
        val out = ShortArray(4)
        val n = PcmMixer.mix(ShortArray(4), 2, ShortArray(2), 2, out)
        assertEquals(2, n)
        assertTrue(out.all { it == 0.toShort() })
    }

    @Test
    fun `mic duplicated to both channels`() {
        val sys = shortArrayOf(100, 200)
        val mic = shortArrayOf(10)
        val out = ShortArray(2)
        val n = PcmMixer.mix(sys, 1, mic, 1, out)
        assertEquals(1, n)
        assertEquals(110.toShort(), out[0])
        assertEquals(210.toShort(), out[1])
    }

    @Test
    fun `clipping clamps to short range`() {
        val up = ShortArray(2)
        PcmMixer.mix(shortArrayOf(30000, 0), 1, shortArrayOf(5000), 1, up)
        assertEquals(Short.MAX_VALUE, up[0])
        val down = ShortArray(2)
        PcmMixer.mix(shortArrayOf(-30000, 0), 1, shortArrayOf(-5000), 1, down)
        assertEquals(Short.MIN_VALUE, down[0])
    }

    @Test
    fun `shortest input wins`() {
        val out = ShortArray(8)
        val n = PcmMixer.mix(ShortArray(8), 4, ShortArray(1), 1, out)
        assertEquals(1, n)
    }
}
