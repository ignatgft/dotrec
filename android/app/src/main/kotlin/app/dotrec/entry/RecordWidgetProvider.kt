package app.dotrec.entry

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import app.dotrec.R
import app.dotrec.recorder.RecorderService
import app.dotrec.recorder.RecorderState
import app.dotrec.recorder.RecorderStateStore
import app.dotrec.settings.SettingsStore

/**
 * T-21: виджет 2×1. Старт/стоп, текущий пресет (FR-ENT-03).
 * Секундного таймера нет (ограничение частоты обновления) — индикатор REC
 * через активную/пассивную кнопку. Темы: values / values-night.
 */
class RecordWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        updateAll(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE) {
            when (RecorderStateStore.state.value) {
                is RecorderState.Recording, is RecorderState.Paused -> {
                    context.startService(
                        Intent(context, RecorderService::class.java)
                            .setAction(RecorderService.ACTION_STOP),
                    )
                }
                else -> {
                    context.startActivity(
                        Intent(context, ConsentActivity::class.java)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                }
            }
        } else if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            updateAll(context)
        }
    }

    companion object {
        const val ACTION_TOGGLE = "app.dotrec.action.WIDGET_TOGGLE"

        fun updateAll(context: Context) {
            runCatching {
                val mgr = AppWidgetManager.getInstance(context)
                val ids = mgr.getAppWidgetIds(
                    ComponentName(context, RecordWidgetProvider::class.java),
                )
                for (id in ids) {
                    mgr.updateAppWidget(id, views(context))
                }
            }
        }

        private fun views(context: Context): RemoteViews {
            val s = RecorderStateStore.state.value
            val settings = SettingsStore(context.applicationContext).getAll()
            val res = (settings["resolution"] as? Number)?.toInt() ?: 1080
            val fps = (settings["fps"] as? Number)?.toInt() ?: 60
            val active = s is RecorderState.Recording || s is RecorderState.Paused
            val v = RemoteViews(context.packageName, R.layout.widget_record)
            v.setTextViewText(R.id.txt_preset, "$res·$fps")
            v.setTextViewText(
                R.id.txt_status,
                if (active) "Идёт запись" else "Тап — запись",
            )
            v.setImageViewResource(
                R.id.btn_toggle,
                if (active) R.drawable.widget_record_active else R.drawable.widget_record_idle,
            )
            val pi = if (active) {
                PendingIntent.getService(
                    context, 20,
                    Intent(context, RecorderService::class.java)
                        .setAction(RecorderService.ACTION_STOP),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            } else {
                PendingIntent.getActivity(
                    context, 21,
                    Intent(context, ConsentActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            }
            v.setOnClickPendingIntent(R.id.widget_root, pi)
            return v
        }
    }
}
