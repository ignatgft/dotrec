package app.dotrec.recorder

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import app.dotrec.util.FileNamer
import java.util.Date

/**
 * Вывод в MediaStore: файлы только в Movies/DotRec/, без широких прав (NFR-PRIV-02).
 * Схема: создать запись с IS_PENDING=1 → писать по дескриптору → IS_PENDING=0.
 */
object OutputWriter {
    data class Session(val uri: Uri, val pfd: ParcelFileDescriptor)

    fun create(context: Context, at: Date = Date()): Session? {
        val values = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, FileNamer.name(at))
            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/DotRec")
            put(MediaStore.Video.Media.IS_PENDING, 1)
        }
        val uri = context.contentResolver.insert(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            values,
        ) ?: return null
        val pfd = try {
            context.contentResolver.openFileDescriptor(uri, "w")
        } catch (_: Exception) {
            runCatching { context.contentResolver.delete(uri, null, null) }
            null
        } ?: return null
        return Session(uri, pfd)
    }

    /** Успех: снять IS_PENDING. Провал: удалить только если файл пуст, иначе спасти (crash recovery). */
    fun finish(context: Context, uri: Uri, success: Boolean) {
        val size = sizeBytes(context, uri)
        if (success || size > 100 * 1024) {
            val done = ContentValues().apply {
                put(MediaStore.Video.Media.IS_PENDING, 0)
            }
            runCatching { context.contentResolver.update(uri, done, null, null) }
        } else {
            runCatching { context.contentResolver.delete(uri, null, null) }
        }
    }

    fun close(session: Session?) {
        runCatching { session?.pfd?.close() }
    }

    fun sizeBytes(context: Context, uri: Uri): Long {
        val cur = context.contentResolver.query(
            uri,
            arrayOf(MediaStore.Video.Media.SIZE),
            null,
            null,
            null,
        ) ?: return 0
        cur.use {
            if (!it.moveToFirst()) return 0
            return it.getLong(0)
        }
    }

    fun idOf(uri: Uri): Long = ContentUris.parseId(uri)
}
