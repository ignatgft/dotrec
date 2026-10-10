package app.dotrec.recorder

/** Общая шкала времени A/V и микширование PCM (чистые функции, покрыты тестами). */
object AvSync {
    /** Метка видео: wall-clock минус старт и паузы. */
    fun videoPts(nowUs: Long, startUs: Long, pausedUs: Long): Long =
        (nowUs - startUs - pausedUs).coerceAtLeast(0)

    /** Метка аудио: по счётчику кадров (во время паузы счётчик стоит). */
    fun audioPts(frames: Long, sampleRate: Int): Long =
        frames * 1_000_000L / sampleRate
}

object PcmMixer {
    /**
     * Микс системного стерео и моно-микрофона в стерео с клиппингом.
     * [system] и [out]: interleaved stereo 16-bit, [micMono]: mono 16-bit.
     * Возвращает число записанных стерео-кадров.
     */
    fun mix(system: ShortArray, systemFrames: Int, micMono: ShortArray, micFrames: Int, out: ShortArray): Int {
        val n = minOf(systemFrames, micFrames, out.size / 2)
        for (i in 0 until n) {
            val mic = micMono[i].toInt()
            out[i * 2] = clamp(system[i * 2].toInt() + mic)
            out[i * 2 + 1] = clamp(system[i * 2 + 1].toInt() + mic)
        }
        return n
    }

    private fun clamp(v: Int): Short =
        (v.coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())).toShort()
}
