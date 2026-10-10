package app.dotrec.util

import kotlin.math.abs

/** Битрейт по умолчанию: w * h * fps * k, затем ближайшее значение из списка. */
object BitrateCalc {
    private val STEPS_MBPS = listOf(4, 8, 12, 20, 40)

    fun defaultMbps(width: Int, height: Int, fps: Int, hevc: Boolean): Int {
        val k = if (hevc) 0.045 else 0.07
        val bps = width.toDouble() * height * fps * k
        val mbps = bps / 1_000_000.0
        return STEPS_MBPS.minBy { abs(it - mbps) }
    }
}
