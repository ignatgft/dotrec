package app.dotrec.entry

import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import app.dotrec.R
import app.dotrec.recorder.RecorderService
import app.dotrec.recorder.RecorderState
import app.dotrec.recorder.RecorderStateStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * T-20: плитка шторки. Старт/стоп без Flutter-движка (FR-ENT-02).
 * Таймер — в подписи плитки (API 29+).
 */
class RecordTileService : TileService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var collectJob: Job? = null

    override fun onStartListening() {
        super.onStartListening()
        render(RecorderStateStore.state.value)
        collectJob?.cancel()
        collectJob = scope.launch {
            RecorderStateStore.state.collect { render(it) }
        }
    }

    override fun onStopListening() {
        collectJob?.cancel()
        collectJob = null
        super.onStopListening()
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    override fun onClick() {
        super.onClick()
        when (RecorderStateStore.state.value) {
            is RecorderState.Recording, is RecorderState.Paused -> {
                startService(
                    Intent(this, RecorderService::class.java).setAction(RecorderService.ACTION_STOP),
                )
            }
            else -> {
                val consent = Intent(this, ConsentActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (Build.VERSION.SDK_INT >= 34) {
                    // TODO(verify): перегрузка с PendingIntent на API 34+.
                    val pi = PendingIntent.getActivity(
                        this, 0, consent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    startActivityAndCollapse(pi)
                } else {
                    @Suppress("DEPRECATION")
                    startActivityAndCollapse(consent)
                }
            }
        }
    }

    private fun render(s: RecorderState) {
        val tile = qsTile ?: return
        when (s) {
            is RecorderState.Recording -> {
                tile.state = Tile.STATE_ACTIVE
                tile.label = "Запись"
                // Подпись плитки доступна с API 29 (наш minSdk).
                tile.subtitle = fmt(s.elapsedMs)
                tile.icon = Icon.createWithResource(this, R.drawable.ic_tile_stop)
            }
            is RecorderState.Paused -> {
                tile.state = Tile.STATE_ACTIVE
                tile.label = "Пауза"
                tile.subtitle = fmt(s.elapsedMs)
                tile.icon = Icon.createWithResource(this, R.drawable.ic_tile_stop)
            }
            else -> {
                tile.state = Tile.STATE_INACTIVE
                tile.label = getString(R.string.tile_label)
                tile.subtitle = null
                tile.icon = Icon.createWithResource(this, R.drawable.ic_tile_rec)
            }
        }
        tile.updateTile()
    }

    private fun fmt(ms: Long): String {
        val s = ms / 1000
        return "%02d:%02d".format(s / 60, s % 60)
    }
}
