package app.dotrec.recorder

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.os.Build
import android.os.SystemClock
import android.view.Surface
import java.io.FileDescriptor
import java.nio.ByteBuffer

/**
 * T-23/T-24: пайплайн MediaCodec + MediaMuxer для звука системы (FR-AUD-02/03).
 * Видео: энкодер с input surface. Аудио: AudioPlaybackCapture (+микс с MIC),
 * AAC. Синхронизация по общей wall-clock шкале (AvSync), пауза без разрывов
 * меток. Используется при systemAudio=true, иначе путь MediaRecorder.
 */
class CodecPipeline {
    private var videoEnc: MediaCodec? = null
    private var audioEnc: MediaCodec? = null
    private var muxer: MediaMuxer? = null
    private var playbackRec: AudioRecord? = null
    private var micRec: AudioRecord? = null
    private var surface: Surface? = null

    @Volatile private var running = false
    @Volatile private var paused = false
    @Volatile private var pausedUs = 0L
    private var pauseStartUs = 0L
    private var startUs = 0L
    private var audioFrames = 0L

    private var videoThread: Thread? = null
    private var audioThread: Thread? = null

    private val muxerLock = Any()
    private var videoTrack = -1
    private var audioTrack = -1
    private var muxerStarted = false
    private val pendingVideo = ArrayDeque<Raw>()
    private val pendingAudio = ArrayDeque<Raw>()

    private data class Raw(val data: ByteArray, val pts: Long, val flags: Int)

    fun inputSurface(): Surface = surface!!

    @Throws(Exception::class)
    fun configure(
        projection: MediaProjection,
        w: Int,
        h: Int,
        fps: Int,
        bitrateBps: Int,
        mime: String,
        mic: Boolean,
        fd: FileDescriptor,
    ): Surface {
        val vf = MediaFormat.createVideoFormat(mime, w, h).apply {
            setInteger(
                MediaFormat.KEY_COLOR_FORMAT,
                MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface,
            )
            setInteger(MediaFormat.KEY_BIT_RATE, bitrateBps)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                setInteger(MediaFormat.KEY_PREPEND_HEADER_TO_SYNC_FRAMES, 1)
            }
        }
        val venc = MediaCodec.createEncoderByType(mime)
        venc.configure(vf, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        surface = venc.createInputSurface()
        videoEnc = venc

        val stereo = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(SAMPLE_RATE)
            .setChannelMask(AudioFormat.CHANNEL_IN_STEREO)
            .build()
        val minBuf = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_STEREO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        if (minBuf <= 0) throw IllegalStateException("bad playback buffer")
        val capCfg = AudioPlaybackCaptureConfiguration.Builder(projection)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_GAME)
            .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
            .build()
        val prec = AudioRecord.Builder()
            .setAudioFormat(stereo)
            .setBufferSizeInBytes(minBuf * 4)
            .setAudioPlaybackCaptureConfig(capCfg)
            .build()
        if (prec.state != AudioRecord.STATE_INITIALIZED) {
            throw IllegalStateException("playback record not initialized")
        }
        playbackRec = prec

        if (mic) {
            val minMic = AudioRecord.getMinBufferSize(
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
            )
            if (minMic <= 0) throw IllegalStateException("bad mic buffer")
            @Suppress("DEPRECATION")
            val mrec = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                minMic * 4,
            )
            if (mrec.state != AudioRecord.STATE_INITIALIZED) {
                throw IllegalStateException("mic record not initialized")
            }
            micRec = mrec
        }

        val af = MediaFormat.createAudioFormat(
            MediaFormat.MIMETYPE_AUDIO_AAC,
            SAMPLE_RATE,
            CHANNELS,
        ).apply {
            setInteger(
                MediaFormat.KEY_AAC_PROFILE,
                MediaCodecInfo.CodecProfileLevel.AACObjectLC,
            )
            setInteger(MediaFormat.KEY_BIT_RATE, AUDIO_BITRATE)
            setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16384)
        }
        val aenc = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        aenc.configure(af, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        audioEnc = aenc

        muxer = MediaMuxer(fd, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        return surface!!
    }

    @Throws(Exception::class)
    fun start() {
        startUs = SystemClock.elapsedRealtime() * 1000
        pausedUs = 0
        audioFrames = 0
        running = true
        paused = false
        videoEnc?.start()
        audioEnc?.start()
        playbackRec?.startRecording()
        micRec?.startRecording()
        videoThread = Thread(::videoLoop, "DotRecVideo").apply { start() }
        audioThread = Thread(::audioLoop, "DotRecAudio").apply { start() }
        app.dotrec.link.LinkServer.onKeyframeRequested = {
            requestKeyframe()
        }
        app.dotrec.link.LinkServer.onBitrateChanged = { bps ->
            setBitrate(bps)
        }
    }

    fun pause() {
        if (paused) return
        pauseStartUs = SystemClock.elapsedRealtime() * 1000
        paused = true
    }

    fun resume() {
        if (!paused) return
        pausedUs += SystemClock.elapsedRealtime() * 1000 - pauseStartUs
        paused = false
    }

    /** Остановка и финализация muxer. true если файл валиден. */
    fun stop(): Boolean {
        running = false
        runCatching { videoThread?.join(2000) }
        runCatching { audioThread?.join(2000) }
        var ok = false
        synchronized(muxerLock) {
            try {
                if (muxerStarted) {
                    muxer?.stop()
                    ok = true
                }
            } catch (_: Exception) {
                ok = false
            }
            runCatching { muxer?.release() }
            muxer = null
        }
        runCatching { videoEnc?.stop() }
        runCatching { videoEnc?.release() }
        runCatching { audioEnc?.stop() }
        runCatching { audioEnc?.release() }
        runCatching { playbackRec?.stop() }
        runCatching { playbackRec?.release() }
        runCatching { micRec?.stop() }
        runCatching { micRec?.release() }
        runCatching { surface?.release() }
        videoEnc = null
        audioEnc = null
        playbackRec = null
        micRec = null
        surface = null
        app.dotrec.link.LinkServer.onKeyframeRequested = null
        app.dotrec.link.LinkServer.onBitrateChanged = null
        return ok
    }

    fun release() {
        running = false
        runCatching { videoThread?.join(1000) }
        runCatching { audioThread?.join(1000) }
        synchronized(muxerLock) {
            runCatching { muxer?.release() }
            muxer = null
        }
        runCatching { videoEnc?.release() }
        runCatching { audioEnc?.release() }
        runCatching { playbackRec?.release() }
        runCatching { micRec?.release() }
        runCatching { surface?.release() }
        videoEnc = null
        audioEnc = null
        playbackRec = null
        micRec = null
        surface = null
        app.dotrec.link.LinkServer.onKeyframeRequested = null
        app.dotrec.link.LinkServer.onBitrateChanged = null
    }

    // ---------- video ----------

    private fun videoLoop() {
        val info = MediaCodec.BufferInfo()
        while (running) {
            val enc = videoEnc ?: return
            val idx = try {
                enc.dequeueOutputBuffer(info, 10000)
            } catch (_: Exception) {
                return
            }
            when {
                idx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    onVideoFormat(enc.outputFormat)
                }
                idx >= 0 -> {
                    val buf = try {
                        enc.getOutputBuffer(idx)
                    } catch (_: Exception) {
                        null
                    }
                    if (buf != null && info.size > 0 &&
                        info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0
                    ) {
                        val pts = AvSync.videoPts(
                            SystemClock.elapsedRealtime() * 1000,
                            startUs,
                            pausedUs,
                        )
                        if (!paused) writeVideo(buf, info, pts)
                    }
                    runCatching { enc.releaseOutputBuffer(idx, false) }
                }
            }
        }
    }

    private fun onVideoFormat(fmt: MediaFormat) {
        synchronized(muxerLock) {
            if (videoTrack >= 0) return
            videoTrack = muxer?.addTrack(fmt) ?: -1
            maybeStartMuxer()
        }
        val csd0 = try { fmt.getByteBuffer("csd-0") } catch (_: Exception) { null }
        val csd1 = try { fmt.getByteBuffer("csd-1") } catch (_: Exception) { null }
        val sps = if (csd0 != null) {
            val b = ByteArray(csd0.remaining())
            csd0.duplicate().get(b)
            b
        } else ByteArray(0)
        val pps = if (csd1 != null) {
            val b = ByteArray(csd1.remaining())
            csd1.duplicate().get(b)
            b
        } else ByteArray(0)
        val combined = sps + pps
        if (combined.isNotEmpty()) {
            app.dotrec.link.LinkServer.broadcastConfig(combined)
        }
    }

    private fun writeVideo(buf: ByteBuffer, info: MediaCodec.BufferInfo, pts: Long) {
        val bytes = ByteArray(info.size)
        val dup = buf.duplicate()
        dup.position(info.offset)
        dup.limit(info.offset + info.size)
        dup.get(bytes)

        if (app.dotrec.link.LinkServer.isClientConnected()) {
            val isKey = (info.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0
            app.dotrec.link.LinkServer.broadcastVideo(bytes, isKey, pts)
        }

        val out = MediaCodec.BufferInfo().apply {
            set(bytes.size, 0, pts, info.flags)
        }
        synchronized(muxerLock) {
            if (!muxerStarted || videoTrack < 0) {
                pendingVideo.addLast(Raw(bytes, pts, info.flags))
            } else {
                muxer?.writeSampleData(videoTrack, ByteBuffer.wrap(bytes), out)
            }
        }
    }

    fun requestKeyframe() {
        val b = android.os.Bundle().apply {
            putInt(MediaCodec.PARAMETER_KEY_REQUEST_SYNC_FRAME, 0)
        }
        runCatching { videoEnc?.setParameters(b) }
    }

    fun setBitrate(bitrateBps: Int) {
        val b = android.os.Bundle().apply {
            putInt(MediaCodec.PARAMETER_KEY_VIDEO_BITRATE, bitrateBps)
        }
        runCatching { videoEnc?.setParameters(b) }
    }

    // ---------- audio ----------

    private fun audioLoop() {
        val sysBuf = ShortArray(FRAMES_PER_READ * 2)
        val micBuf = ShortArray(FRAMES_PER_READ)
        val mixed = ShortArray(FRAMES_PER_READ * 2)
        val info = MediaCodec.BufferInfo()
        while (running) {
            if (paused) {
                runCatching { Thread.sleep(10) }
                continue
            }
            val prec = playbackRec ?: return
            val n = try {
                prec.read(sysBuf, 0, sysBuf.size)
            } catch (_: Exception) {
                return
            }
            if (n <= 0) continue
            var frames = n / 2
            var pcm: ShortArray = sysBuf
            val mrec = micRec
            if (mrec != null) {
                val m = try {
                    mrec.read(micBuf, 0, frames)
                } catch (_: Exception) {
                    -1
                }
                if (m > 0) {
                    frames = PcmMixer.mix(sysBuf, frames, micBuf, m, mixed)
                    pcm = mixed
                }
            }
            feedAac(pcm, frames)
            drainAac(info)
        }
    }

    private fun feedAac(pcm: ShortArray, frames: Int) {
        val enc = audioEnc ?: return
        val bytes = frames * 2 * 2
        val idx = try {
            enc.dequeueInputBuffer(10000)
        } catch (_: Exception) {
            return
        }
        if (idx < 0) return
        try {
            val buf = enc.getInputBuffer(idx) ?: return
            buf.clear()
            for (i in 0 until frames * 2) {
                buf.putShort(pcm[i])
            }
            val pts = AvSync.audioPts(audioFrames, SAMPLE_RATE)
            audioFrames += frames
            enc.queueInputBuffer(idx, 0, bytes, pts, 0)
        } catch (_: Exception) {
            return
        }
    }

    private fun drainAac(info: MediaCodec.BufferInfo) {
        val enc = audioEnc ?: return
        while (running && !paused) {
            val idx = try {
                enc.dequeueOutputBuffer(info, 0)
            } catch (_: Exception) {
                return
            }
            when {
                idx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    onAudioFormat(enc.outputFormat)
                }
                idx >= 0 -> {
                    val buf = try {
                        enc.getOutputBuffer(idx)
                    } catch (_: Exception) {
                        null
                    }
                    if (buf != null && info.size > 0 &&
                        info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0
                    ) {
                        writeAudio(buf, info)
                    }
                    runCatching { enc.releaseOutputBuffer(idx, false) }
                }
                else -> return
            }
        }
    }

    private fun onAudioFormat(fmt: MediaFormat) {
        synchronized(muxerLock) {
            if (audioTrack >= 0) return
            audioTrack = muxer?.addTrack(fmt) ?: -1
            maybeStartMuxer()
        }
    }

    private fun writeAudio(buf: ByteBuffer, info: MediaCodec.BufferInfo) {
        val bytes = ByteArray(info.size)
        val dup = buf.duplicate()
        dup.position(info.offset)
        dup.limit(info.offset + info.size)
        dup.get(bytes)

        if (app.dotrec.link.LinkServer.isClientConnected()) {
            app.dotrec.link.LinkServer.broadcastAudio(bytes, info.presentationTimeUs)
        }

        val out = MediaCodec.BufferInfo().apply {
            set(bytes.size, 0, info.presentationTimeUs, info.flags)
        }
        synchronized(muxerLock) {
            if (!muxerStarted || audioTrack < 0) {
                pendingAudio.addLast(Raw(bytes, info.presentationTimeUs, info.flags))
            } else {
                muxer?.writeSampleData(audioTrack, ByteBuffer.wrap(bytes), out)
            }
        }
    }

    private fun maybeStartMuxer() {
        if (muxerStarted || videoTrack < 0 || audioTrack < 0) return
        val m = muxer ?: return
        try {
            m.start()
        } catch (_: Exception) {
            return
        }
        muxerStarted = true
        // Сброс накопленного в порядке меток.
        val all = mutableListOf<Pair<Long, () -> Unit>>()
        while (pendingVideo.isNotEmpty()) {
            val r = pendingVideo.removeFirst()
            all.add(r.pts to { writeNow(videoTrack, r) })
        }
        while (pendingAudio.isNotEmpty()) {
            val r = pendingAudio.removeFirst()
            all.add(r.pts to { writeNow(audioTrack, r) })
        }
        all.sortBy { it.first }
        for ((_, w) in all) {
            runCatching { w() }
        }
    }

    private fun writeNow(track: Int, r: Raw) {
        val out = MediaCodec.BufferInfo().apply {
            set(r.data.size, 0, r.pts, r.flags)
        }
        muxer?.writeSampleData(track, ByteBuffer.wrap(r.data), out)
    }

    companion object {
        const val SAMPLE_RATE = 44100
        const val CHANNELS = 2
        const val AUDIO_BITRATE = 128_000
        private const val FRAMES_PER_READ = 2048
    }
}
