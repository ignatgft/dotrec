package app.dotrec.util

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.FileDescriptor
import java.nio.ByteBuffer

/**
 * Быстрая обрезка видео без перекодирования (docs/11).
 * Использует MediaExtractor и MediaMuxer для прямого копирования сэмплов (stream copy).
 */
object VideoTrimmer {
    private const val BUFFER_SIZE = 1024 * 1024 // 1 MB буфер

    fun trim(
        sourceFd: FileDescriptor,
        destFd: FileDescriptor,
        startUs: Long,
        endUs: Long,
    ): Boolean {
        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        try {
            extractor.setDataSource(sourceFd)
            val trackCount = extractor.trackCount
            if (trackCount <= 0) return false

            muxer = MediaMuxer(destFd, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val indexMap = HashMap<Int, Int>()

            for (i in 0 until trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("video/") || mime.startsWith("audio/")) {
                    extractor.selectTrack(i)
                    val muxerTrack = muxer.addTrack(format)
                    indexMap[i] = muxerTrack
                }
            }

            if (indexMap.isEmpty()) return false

            muxer.start()

            // Ищем ключевой кадр перед startUs
            extractor.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)

            val buffer = ByteBuffer.allocateDirect(BUFFER_SIZE)
            val info = MediaCodec.BufferInfo()
            val startSyncTimePerTrack = HashMap<Int, Long>()
            val lastPtsPerTrack = HashMap<Int, Long>()

            while (true) {
                val trackIndex = extractor.sampleTrackIndex
                if (trackIndex < 0) break

                val sampleTime = extractor.sampleTime
                if (sampleTime > endUs && (extractor.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC) == 0) {
                    // Достигли конца интервала
                    break
                }

                val muxerTrack = indexMap[trackIndex]
                if (muxerTrack != null) {
                    buffer.clear()
                    val sampleSize = extractor.readSampleData(buffer, 0)
                    if (sampleSize < 0) break

                    val trackStart = startSyncTimePerTrack.getOrPut(muxerTrack) { sampleTime }
                    val calculatedPts = Math.max(0L, sampleTime - trackStart)
                    val prevPts = lastPtsPerTrack[muxerTrack] ?: -1L
                    val safePts = if (calculatedPts <= prevPts) prevPts + 1000L else calculatedPts
                    lastPtsPerTrack[muxerTrack] = safePts

                    info.offset = 0
                    info.size = sampleSize
                    info.presentationTimeUs = safePts
                    info.flags = extractor.sampleFlags

                    muxer.writeSampleData(muxerTrack, buffer, info)
                }
                extractor.advance()
            }

            muxer.stop()
            return true
        } catch (_: Exception) {
            return false
        } finally {
            runCatching { extractor.release() }
            runCatching { muxer?.release() }
        }
    }
}
