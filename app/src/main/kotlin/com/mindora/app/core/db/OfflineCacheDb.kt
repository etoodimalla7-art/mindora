package com.mindora.app.core.db

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

data class PendingSyncAction(
    val id: Long,
    val actionType: String,
    val payloadJson: String,
    val createdAt: Long
)

/**
 * Thread-safe offline-first SQLite cache & pending-sync queue.
 */
class OfflineCacheDb(context: Context) :
    SQLiteOpenHelper(context.applicationContext, DB_NAME, null, DB_VERSION) {

    private val gson = Gson()
    private val lock = Any()

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE IF NOT EXISTS cache_entries (
                cache_key TEXT PRIMARY KEY,
                json_payload TEXT NOT NULL,
                updated_at INTEGER NOT NULL
            )
            """.trimIndent()
        )
        db.execSQL(
            """
            CREATE TABLE IF NOT EXISTS pending_actions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                action_type TEXT NOT NULL,
                payload_json TEXT NOT NULL,
                created_at INTEGER NOT NULL
            )
            """.trimIndent()
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS cache_entries")
        db.execSQL("DROP TABLE IF EXISTS pending_actions")
        onCreate(db)
    }

    fun putJson(key: String, value: Any) {
        synchronized(lock) {
            val payload = if (value is String) value else gson.toJson(value)
            val cv = ContentValues().apply {
                put("cache_key", key)
                put("json_payload", payload)
                put("updated_at", System.currentTimeMillis())
            }
            writableDatabase.insertWithOnConflict(
                "cache_entries",
                null,
                cv,
                SQLiteDatabase.CONFLICT_REPLACE
            )
        }
    }

    fun getRaw(key: String): String? = synchronized(lock) {
        readableDatabase.rawQuery(
            "SELECT json_payload FROM cache_entries WHERE cache_key = ?",
            arrayOf(key)
        ).use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        }
    }

    fun <T> getObject(key: String, clazz: Class<T>): T? {
        val raw = getRaw(key) ?: return null
        return try {
            gson.fromJson(raw, clazz)
        } catch (_: Exception) {
            null
        }
    }

    fun <T> getList(key: String, elementClass: Class<T>): List<T>? {
        val raw = getRaw(key) ?: return null
        return try {
            val type = TypeToken.getParameterized(List::class.java, elementClass).type
            gson.fromJson(raw, type)
        } catch (_: Exception) {
            null
        }
    }

    fun enqueueAction(actionType: String, payload: Any) {
        synchronized(lock) {
            val cv = ContentValues().apply {
                put("action_type", actionType)
                put("payload_json", if (payload is String) payload else gson.toJson(payload))
                put("created_at", System.currentTimeMillis())
            }
            writableDatabase.insert("pending_actions", null, cv)
        }
    }

    fun listPendingActions(): List<PendingSyncAction> = synchronized(lock) {
        val result = mutableListOf<PendingSyncAction>()
        readableDatabase.rawQuery(
            "SELECT id, action_type, payload_json, created_at FROM pending_actions ORDER BY id ASC",
            emptyArray()
        ).use { cursor ->
            while (cursor.moveToNext()) {
                result.add(
                    PendingSyncAction(
                        id = cursor.getLong(0),
                        actionType = cursor.getString(1),
                        payloadJson = cursor.getString(2),
                        createdAt = cursor.getLong(3)
                    )
                )
            }
        }
        result
    }

    fun deletePendingAction(id: Long) {
        synchronized(lock) {
            writableDatabase.delete("pending_actions", "id = ?", arrayOf(id.toString()))
        }
    }

    fun clearAll() {
        synchronized(lock) {
            writableDatabase.delete("cache_entries", null, null)
            writableDatabase.delete("pending_actions", null, null)
        }
    }

    companion object {
        private const val DB_NAME = "mindora_offline_cache.db"
        private const val DB_VERSION = 1
    }
}
