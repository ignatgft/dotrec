package app.dotrec.link

import java.io.InputStream
import java.io.OutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * DotRec Link v1 — бинарный протокол фрейминга (docs/protocol.md).
 * Заголовок: 14 байт: [type u8][flags u8][length u32][pts_us u64][payload bytes]
 */
object LinkProtocol {
    const val PORT = 48211
    const val PROTOCOL_VERSION = 1
    const val HEADER_SIZE = 14

    // Типы пакетов
    const val TYPE_CONFIG: Byte = 0x01
    const val TYPE_VIDEO: Byte = 0x02
    const val TYPE_AUDIO: Byte = 0x03
    const val TYPE_COMMAND: Byte = 0x04
    const val TYPE_STATS: Byte = 0x05

    // Флаги
    const val FLAG_KEYFRAME: Byte = 0x01
    const val FLAG_EOS: Byte = 0x02
    const val FLAG_ENCRYPTED: Byte = 0x04

    fun writeFrame(
        out: OutputStream,
        type: Byte,
        flags: Byte,
        ptsUs: Long,
        payload: ByteArray,
    ) {
        val header = ByteBuffer.allocate(HEADER_SIZE).order(ByteOrder.BIG_ENDIAN)
        header.put(type)
        header.put(flags)
        header.putInt(payload.size)
        header.putLong(ptsUs)
        synchronized(out) {
            out.write(header.array())
            if (payload.isNotEmpty()) {
                out.write(payload)
            }
            out.flush()
        }
    }

    class Frame(
        val type: Byte,
        val flags: Byte,
        val length: Int,
        val ptsUs: Long,
        val payload: ByteArray,
    )

    fun readFrame(input: InputStream): Frame? {
        val headerBuf = ByteArray(HEADER_SIZE)
        var readH = 0
        while (readH < HEADER_SIZE) {
            val r = input.read(headerBuf, readH, HEADER_SIZE - readH)
            if (r == -1) return null
            readH += r
        }
        val bb = ByteBuffer.wrap(headerBuf).order(ByteOrder.BIG_ENDIAN)
        val type = bb.get()
        val flags = bb.get()
        val length = bb.int
        val ptsUs = bb.long
        if (length < 0 || length > 16 * 1024 * 1024) {
            throw IllegalStateException("Frame payload too large: $length")
        }
        val payload = ByteArray(length)
        var readP = 0
        while (readP < length) {
            val r = input.read(payload, readP, length - readP)
            if (r == -1) return null
            readP += r
        }
        return Frame(type, flags, length, ptsUs, payload)
    }
}
