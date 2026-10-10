package app.dotrec.recorder

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** Единый источник правды о записи. Живёт в процессе приложения, не зависит от Flutter. */
sealed interface RecorderState {
    data object Idle : RecorderState
    data class Countdown(val secondsLeft: Int) : RecorderState
    data object Starting : RecorderState
    data class Recording(val elapsedMs: Long) : RecorderState
    data class Paused(val elapsedMs: Long) : RecorderState
    data object Saving : RecorderState
    data class Failed(val code: String, val message: String? = null) : RecorderState
}

object RecorderStateStore {
    private val _state = MutableStateFlow<RecorderState>(RecorderState.Idle)
    val state: StateFlow<RecorderState> = _state.asStateFlow()

    fun set(next: RecorderState) {
        check(isTransitionAllowed(_state.value, next)) { "Illegal transition ${_state.value} -> $next" }
        _state.value = next
    }

    /** Допустимые переходы из docs/03-architecture.md. Покрыть юнит-тестами. */
    fun isTransitionAllowed(from: RecorderState, to: RecorderState): Boolean = when (from) {
        is RecorderState.Idle -> to is RecorderState.Countdown || to is RecorderState.Starting
        is RecorderState.Countdown -> to is RecorderState.Countdown || to is RecorderState.Starting || to is RecorderState.Idle
        is RecorderState.Starting -> to is RecorderState.Recording || to is RecorderState.Failed || to is RecorderState.Idle
        is RecorderState.Recording -> to is RecorderState.Recording || to is RecorderState.Paused || to is RecorderState.Saving || to is RecorderState.Failed
        is RecorderState.Paused -> to is RecorderState.Paused || to is RecorderState.Recording || to is RecorderState.Saving || to is RecorderState.Failed
        is RecorderState.Saving -> to is RecorderState.Idle || to is RecorderState.Failed
        is RecorderState.Failed -> to is RecorderState.Idle
    }
}
