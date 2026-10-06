package app.aimstair.reminder_app.alarms

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

/**
 * native.db — owned by Kotlin only (docs/architecture.md §4). Holds just what is needed to fire
 * alarms and handle notification buttons while Flutter isn't running.
 */
class NativeDb private constructor(context: Context) :
    SQLiteOpenHelper(context, "native.db", null, 1) {

    data class Alarm(
        val key: String,
        val fireAtUtcMs: Long,
        val title: String,
        val body: String,
        val kind: String,
        val lateCutoffMs: Long,
        val exact: Boolean,
    )

    override fun onConfigure(db: SQLiteDatabase) {
        db.enableWriteAheadLogging()
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """CREATE TABLE alarms (
                key TEXT PRIMARY KEY,
                fire_at_utc INTEGER NOT NULL,
                title TEXT NOT NULL,
                body TEXT NOT NULL,
                kind TEXT NOT NULL,
                late_cutoff_ms INTEGER NOT NULL,
                exact INTEGER NOT NULL DEFAULT 1
            )"""
        )
        db.execSQL(
            """CREATE TABLE action_journal (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                alarm_key TEXT NOT NULL,
                action TEXT NOT NULL,
                acted_at INTEGER NOT NULL,
                applied INTEGER NOT NULL DEFAULT 0
            )"""
        )
        db.execSQL(
            """CREATE TABLE fire_log (
                alarm_key TEXT PRIMARY KEY,
                scheduled_at INTEGER NOT NULL,
                fired_at INTEGER NOT NULL,
                outcome TEXT NOT NULL
            )"""
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit

    // ---- alarms ----

    fun upsertAlarm(a: Alarm) {
        writableDatabase.insertWithOnConflict("alarms", null, ContentValues().apply {
            put("key", a.key)
            put("fire_at_utc", a.fireAtUtcMs)
            put("title", a.title)
            put("body", a.body)
            put("kind", a.kind)
            put("late_cutoff_ms", a.lateCutoffMs)
            put("exact", if (a.exact) 1 else 0)
        }, SQLiteDatabase.CONFLICT_REPLACE)
    }

    fun setExact(key: String, exact: Boolean) {
        writableDatabase.update(
            "alarms", ContentValues().apply { put("exact", if (exact) 1 else 0) },
            "key = ?", arrayOf(key)
        )
    }

    fun deleteAlarm(key: String) {
        writableDatabase.delete("alarms", "key = ?", arrayOf(key))
    }

    fun alarm(key: String): Alarm? = allAlarms("key = ?", arrayOf(key)).firstOrNull()

    fun allAlarms(where: String? = null, args: Array<String>? = null): List<Alarm> {
        readableDatabase.query("alarms", null, where, args, null, null, "fire_at_utc").use { c ->
            val out = mutableListOf<Alarm>()
            while (c.moveToNext()) {
                out += Alarm(
                    key = c.getString(c.getColumnIndexOrThrow("key")),
                    fireAtUtcMs = c.getLong(c.getColumnIndexOrThrow("fire_at_utc")),
                    title = c.getString(c.getColumnIndexOrThrow("title")),
                    body = c.getString(c.getColumnIndexOrThrow("body")),
                    kind = c.getString(c.getColumnIndexOrThrow("kind")),
                    lateCutoffMs = c.getLong(c.getColumnIndexOrThrow("late_cutoff_ms")),
                    exact = c.getInt(c.getColumnIndexOrThrow("exact")) == 1,
                )
            }
            return out
        }
    }

    // ---- journal ----

    fun journal(alarmKey: String, action: String) {
        writableDatabase.insert("action_journal", null, ContentValues().apply {
            put("alarm_key", alarmKey)
            put("action", action)
            put("acted_at", System.currentTimeMillis())
        })
    }

    fun unappliedJournal(): List<JournalEntry> {
        readableDatabase.query(
            "action_journal", null, "applied = 0", null, null, null, "id"
        ).use { c ->
            val out = mutableListOf<JournalEntry>()
            while (c.moveToNext()) {
                out += JournalEntry(
                    id = c.getLong(c.getColumnIndexOrThrow("id")),
                    alarmKey = c.getString(c.getColumnIndexOrThrow("alarm_key")),
                    action = c.getString(c.getColumnIndexOrThrow("action")),
                    actedAtMs = c.getLong(c.getColumnIndexOrThrow("acted_at")),
                )
            }
            return out
        }
    }

    fun markApplied(ids: List<Long>) {
        val db = writableDatabase
        db.beginTransaction()
        try {
            ids.forEach { id ->
                db.update("action_journal", ContentValues().apply { put("applied", 1) },
                    "id = ?", arrayOf(id.toString()))
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    // ---- fire log ----

    /** SCH-6: true if this key was already shown (or recorded missed) — never fire twice. */
    fun alreadyFired(key: String): Boolean =
        readableDatabase.query("fire_log", arrayOf("alarm_key"), "alarm_key = ?", arrayOf(key),
            null, null, null).use { it.moveToFirst() }

    fun recordFire(key: String, scheduledAt: Long, firedAt: Long, outcome: String) {
        writableDatabase.insertWithOnConflict("fire_log", null, ContentValues().apply {
            put("alarm_key", key)
            put("scheduled_at", scheduledAt)
            put("fired_at", firedAt)
            put("outcome", outcome)
        }, SQLiteDatabase.CONFLICT_IGNORE)
    }

    fun fireLog(sinceMs: Long): List<FireLogEntry> {
        readableDatabase.query("fire_log", null, "scheduled_at >= ?", arrayOf(sinceMs.toString()),
            null, null, "scheduled_at DESC").use { c ->
            val out = mutableListOf<FireLogEntry>()
            while (c.moveToNext()) {
                out += FireLogEntry(
                    alarmKey = c.getString(c.getColumnIndexOrThrow("alarm_key")),
                    scheduledAtMs = c.getLong(c.getColumnIndexOrThrow("scheduled_at")),
                    firedAtMs = c.getLong(c.getColumnIndexOrThrow("fired_at")),
                    outcome = c.getString(c.getColumnIndexOrThrow("outcome")),
                )
            }
            return out
        }
    }

    fun clearLogs() {
        writableDatabase.delete("fire_log", null, null)
        writableDatabase.delete("action_journal", null, null)
    }

    companion object {
        @Volatile private var instance: NativeDb? = null
        fun get(context: Context): NativeDb =
            instance ?: synchronized(this) {
                instance ?: NativeDb(context.applicationContext).also { instance = it }
            }
    }
}
