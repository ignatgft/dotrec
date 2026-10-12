package app.dotrec.link

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class LinkProtocolTest {

    @Test
    fun testFrameRoundTrip() {
        val out = ByteArrayOutputStream()
        val payload = "Hello DotRec Link".toByteArray(Charsets.UTF_8)
        val ptsUs = 123456789L

        LinkProtocol.writeFrame(
            out,
            LinkProtocol.TYPE_VIDEO,
            LinkProtocol.FLAG_KEYFRAME,
            ptsUs,
            payload,
        )

        val bytes = out.toByteArray()
        assertEquals(LinkProtocol.HEADER_SIZE + payload.size, bytes.size)

        val input = ByteArrayInputStream(bytes)
        val frame = LinkProtocol.readFrame(input)

        assertNotNull(frame)
        assertEquals(LinkProtocol.TYPE_VIDEO, frame!!.type)
        assertEquals(LinkProtocol.FLAG_KEYFRAME, frame.flags)
        assertEquals(payload.size, frame.length)
        assertEquals(ptsUs, frame.ptsUs)
        assertArrayEquals(payload, frame.payload)
    }

    @Test
    fun testEmptyPayloadFrame() {
        val out = ByteArrayOutputStream()
        LinkProtocol.writeFrame(
            out,
            LinkProtocol.TYPE_COMMAND,
            0.toByte(),
            0L,
            ByteArray(0),
        )

        val input = ByteArrayInputStream(out.toByteArray())
        val frame = LinkProtocol.readFrame(input)

        assertNotNull(frame)
        assertEquals(LinkProtocol.TYPE_COMMAND, frame!!.type)
        assertEquals(0.toByte(), frame.flags)
        assertEquals(0, frame.length)
        assertEquals(0, frame.payload.size)
    }

    @Test
    fun testMultipleFramesSequential() {
        val out = ByteArrayOutputStream()
        val f1 = "Frame 1".toByteArray()
        val f2 = "Frame 2".toByteArray()

        LinkProtocol.writeFrame(out, LinkProtocol.TYPE_CONFIG, 0, 100L, f1)
        LinkProtocol.writeFrame(out, LinkProtocol.TYPE_VIDEO, LinkProtocol.FLAG_KEYFRAME, 200L, f2)

        val input = ByteArrayInputStream(out.toByteArray())
        val r1 = LinkProtocol.readFrame(input)
        val r2 = LinkProtocol.readFrame(input)

        assertNotNull(r1)
        assertEquals(LinkProtocol.TYPE_CONFIG, r1!!.type)
        assertEquals(100L, r1.ptsUs)

        assertNotNull(r2)
        assertEquals(LinkProtocol.TYPE_VIDEO, r2!!.type)
        assertEquals(LinkProtocol.FLAG_KEYFRAME, r2.flags)
        assertEquals(200L, r2.ptsUs)
    }

    @Test
    fun testAudioFrame() {
        val out = ByteArrayOutputStream()
        val audioBytes = byteArrayOf(0xFF.toByte(), 0xF1.toByte(), 0x50.toByte(), 0x80.toByte())
        val ptsUs = 33000L

        LinkProtocol.writeFrame(
            out,
            LinkProtocol.TYPE_AUDIO,
            0.toByte(),
            ptsUs,
            audioBytes,
        )

        val input = ByteArrayInputStream(out.toByteArray())
        val frame = LinkProtocol.readFrame(input)

        assertNotNull(frame)
        assertEquals(LinkProtocol.TYPE_AUDIO, frame!!.type)
        assertEquals(0.toByte(), frame.flags)
        assertEquals(ptsUs, frame.ptsUs)
        assertArrayEquals(audioBytes, frame.payload)
    }
}
