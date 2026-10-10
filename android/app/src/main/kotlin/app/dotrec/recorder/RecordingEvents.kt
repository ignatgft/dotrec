package app.dotrec.recorder

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * Одноразовые события результата. Контракт v1: `saved` приходит один раз,
 * после него store возвращается в Idle.
 */
object RecordingEvents {
    private val _results =
        MutableSharedFlow<Map<String, Any?>>(extraBufferCapacity = 4)
    val results: SharedFlow<Map<String, Any?>> = _results.asSharedFlow()

    fun saved(uri: String, durationMs: Long, sizeBytes: Long) {
        _results.tryEmit(
            mapOf(
                "type" to "saved",
                "uri" to uri,
                "durationMs" to durationMs,
                "sizeBytes" to sizeBytes,
            ),
        )
    }
}
