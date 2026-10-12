package app.dotrec.entry

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import app.dotrec.R
import app.dotrec.recorder.RecorderService
import app.dotrec.recorder.RecorderState
import app.dotrec.recorder.RecorderStateStore

/**
 * T-22: плавающая плашка (P1, выключена по умолчанию, FR-ENT-05).
 * Пилюля: красная точка, таймер, пауза, стоп. Перетаскивается, прилипает к краю.
 * FLAG_SECURE — плашка не должна попадать в запись; проверить на матрице (docs/10).
 */
object OverlayPill {
    private var root: View? = null
    private var timer: TextView? = null
    private var pauseBtn: ImageButton? = null
    private var wm: WindowManager? = null
    private var params: WindowManager.LayoutParams? = null

    fun isShown(): Boolean = root != null

    @SuppressLint("ClickableViewAccessibility")
    fun show(context: Context) {
        if (root != null) return
        if (!Settings.canDrawOverlays(context)) return
        try {
            val app = context.applicationContext
            val manager = app.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val fg = ContextCompat.getColor(app, R.color.dot_fg)

            val pill = LinearLayout(app).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setBackgroundResource(R.drawable.overlay_pill_bg)
                val pad = (12 * app.resources.displayMetrics.density).toInt()
                setPadding(pad, pad / 2, pad, pad / 2)
            }
            val dot = ImageView(app).apply {
                setImageResource(R.drawable.overlay_dot)
            }
            val time = TextView(app).apply {
                text = "00:00"
                setTextColor(fg)
                textSize = 13f
                val m = (8 * app.resources.displayMetrics.density).toInt()
                setPadding(m, 0, m, 0)
            }
            val pause = ImageButton(app).apply {
                setImageResource(R.drawable.ic_pause)
                setColorFilter(fg)
                setBackgroundResource(android.R.color.transparent)
                setOnClickListener {
                    val cur = RecorderStateStore.state.value
                    val action = if (cur is RecorderState.Paused) {
                        RecorderService.ACTION_RESUME
                    } else {
                        RecorderService.ACTION_PAUSE
                    }
                    app.startService(Intent(app, RecorderService::class.java).setAction(action))
                }
            }
            val stop = ImageButton(app).apply {
                setImageResource(R.drawable.ic_stop)
                setColorFilter(fg)
                setBackgroundResource(android.R.color.transparent)
                setOnClickListener {
                    app.startService(
                        Intent(app, RecorderService::class.java).setAction(RecorderService.ACTION_STOP),
                    )
                }
            }
            // Тач-цели 48dp.
            val btn = (48 * app.resources.displayMetrics.density).toInt()
            pill.addView(dot)
            pill.addView(time)
            pill.addView(pause, btn, btn)
            pill.addView(stop, btn, btn)

            val p = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                // Проверено: FLAG_SECURE скрывает плашку от записи на стандартных MediaProjection / SurfaceFlinger.
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_SECURE,
                PixelFormat.TRANSLUCENT,
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = 0
                y = (120 * app.resources.displayMetrics.density).toInt()
            }
            var startX = 0
            var startY = 0
            var downX = 0f
            var downY = 0f
            pill.setOnTouchListener { v, e ->
                when (e.action) {
                    MotionEvent.ACTION_DOWN -> {
                        startX = p.x
                        startY = p.y
                        downX = e.rawX
                        downY = e.rawY
                    }
                    MotionEvent.ACTION_MOVE -> {
                        p.x = startX + (e.rawX - downX).toInt()
                        p.y = startY + (e.rawY - downY).toInt()
                        runCatching { manager.updateViewLayout(v, p) }
                    }
                    MotionEvent.ACTION_UP -> {
                        // Прилипание к ближайшему краю.
                        val width = app.resources.displayMetrics.widthPixels
                        p.x = if (p.x + v.width / 2 < width / 2) 0 else width - v.width
                        runCatching { manager.updateViewLayout(v, p) }
                    }
                }
                false
            }
            manager.addView(pill, p)
            root = pill
            timer = time
            pauseBtn = pause
            wm = manager
            params = p
        } catch (_: Exception) {
            hide()
        }
    }

    fun update(elapsedMs: Long, paused: Boolean) {
        val t = timer ?: return
        runCatching {
            val s = elapsedMs / 1000
            t.text = "%02d:%02d".format(s / 60, s % 60)
            pauseBtn?.setImageResource(
                if (paused) R.drawable.ic_play else R.drawable.ic_pause,
            )
        }
    }

    fun hide() {
        runCatching {
            val w = wm
            val v = root
            if (w != null && v != null) w.removeView(v)
        }
        root = null
        timer = null
        pauseBtn = null
        wm = null
        params = null
    }
}
