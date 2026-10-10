package app.dotrec.entry

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import app.dotrec.R
import app.dotrec.recorder.RecorderService

/** Уведомления записи (см. docs/04). Малая иконка монохромная. */
object NotificationFactory {
    const val CHANNEL_RECORDING = "recording"
    const val CHANNEL_RESULTS = "results"

    fun ensureChannels(context: Context) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_RECORDING, "Запись", NotificationManager.IMPORTANCE_LOW),
        )
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_RESULTS, "Результаты", NotificationManager.IMPORTANCE_DEFAULT),
        )
    }

    fun recording(context: Context, paused: Boolean): Notification {
        ensureChannels(context)
        val stop = PendingIntent.getService(
            context, 1,
            Intent(context, RecorderService::class.java).setAction(RecorderService.ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val pause = PendingIntent.getService(
            context, 2,
            Intent(
                context,
                RecorderService::class.java,
            ).setAction(if (paused) RecorderService.ACTION_RESUME else RecorderService.ACTION_PAUSE),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(context, CHANNEL_RECORDING)
            .setSmallIcon(R.drawable.ic_stat_rec)
            .setContentTitle(if (paused) "Запись на паузе" else "Идёт запись")
            .setUsesChronometer(!paused)
            .setOngoing(true)
            .addAction(0, if (paused) "Продолжить" else "Пауза", pause)
            .addAction(0, "Стоп", stop)
            .build()
    }
}
