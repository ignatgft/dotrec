package app.dotrec.util

/** Подбор размеров видео: масштаб по короткой стороне, обе стороны чётные. */
object SizeCalc {
    /** Возвращает Pair(w, h) или null, если экран меньше целевого. */
    fun fit(screenW: Int, screenH: Int, targetShortSide: Int): Pair<Int, Int>? {
        val shortSide = minOf(screenW, screenH)
        if (shortSide < targetShortSide) return null
        val scale = targetShortSide.toDouble() / shortSide
        var w = (screenW * scale).toInt()
        var h = (screenH * scale).toInt()
        w -= w % 2
        h -= h % 2
        if (w < 2 || h < 2) return null
        return w to h
    }

    fun availableTargets(screenW: Int, screenH: Int): List<Int> =
        listOf(720, 1080, 1440).filter { fit(screenW, screenH, it) != null }
}
