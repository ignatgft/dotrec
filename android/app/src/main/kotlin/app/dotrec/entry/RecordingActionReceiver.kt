package app.dotrec.entry

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Действия итогового уведомления: удалить запись (FR-LIB-01/03). */
class RecordingActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_DELETE) return
        val uri = intent.data ?: return
        runCatching { context.contentResolver.delete(uri, null, null) }
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        runCatching { nm.cancel(uri.toString().hashCode()) }
    }

    companion object {
        const val ACTION_DELETE = "app.dotrec.action.DELETE_RECORDING"
    }
}
