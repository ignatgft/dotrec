package app.dotrec.recorder

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RecorderStateStoreTest {
    private val s = RecorderStateStore

    @Test
    fun `idle allows countdown and starting only`() {
        assertTrue(s.isTransitionAllowed(RecorderState.Idle, RecorderState.Countdown(3)))
        assertTrue(s.isTransitionAllowed(RecorderState.Idle, RecorderState.Starting))
        assertFalse(s.isTransitionAllowed(RecorderState.Idle, RecorderState.Recording(0)))
        assertFalse(s.isTransitionAllowed(RecorderState.Idle, RecorderState.Idle))
    }

    @Test
    fun `recording allows pause saving failed`() {
        val r = RecorderState.Recording(1000)
        assertTrue(s.isTransitionAllowed(r, RecorderState.Paused(1000)))
        assertTrue(s.isTransitionAllowed(r, RecorderState.Saving))
        assertTrue(s.isTransitionAllowed(r, RecorderState.Failed("x")))
        assertFalse(s.isTransitionAllowed(r, RecorderState.Idle))
        assertFalse(s.isTransitionAllowed(r, RecorderState.Starting))
    }

    @Test
    fun `paused resumes or saves`() {
        val p = RecorderState.Paused(1000)
        assertTrue(s.isTransitionAllowed(p, RecorderState.Recording(1000)))
        assertTrue(s.isTransitionAllowed(p, RecorderState.Saving))
        assertFalse(s.isTransitionAllowed(p, RecorderState.Idle))
    }

    @Test
    fun `saving ends in idle or failed`() {
        assertTrue(s.isTransitionAllowed(RecorderState.Saving, RecorderState.Idle))
        assertTrue(s.isTransitionAllowed(RecorderState.Saving, RecorderState.Failed("io_error")))
        assertFalse(s.isTransitionAllowed(RecorderState.Saving, RecorderState.Recording(0)))
    }

    @Test
    fun `failed resets to idle only`() {
        assertTrue(s.isTransitionAllowed(RecorderState.Failed("x"), RecorderState.Idle))
        assertFalse(s.isTransitionAllowed(RecorderState.Failed("x"), RecorderState.Starting))
    }

    @Test
    fun `illegal transition throws`() {
        try {
            s.set(RecorderState.Recording(0))
            assertFalse("expected IllegalStateException", true)
        } catch (_: IllegalStateException) {
            // ok: Idle -> Recording запрещён
        }
    }
}
