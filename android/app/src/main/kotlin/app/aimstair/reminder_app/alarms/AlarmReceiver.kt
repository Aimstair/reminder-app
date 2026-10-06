package app.aimstair.reminder_app.alarms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Fires a reminder notification. Runs without starting Flutter (SCH-1, NTF-8). */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_FIRE) return
        val key = intent.getStringExtra(EXTRA_KEY) ?: return
        val alarm = NativeDb.get(context).alarm(key) ?: return // cancelled meanwhile
        deliver(context, alarm, System.currentTimeMillis())
    }

    companion object {
        const val ACTION_FIRE = "app.aimstair.reminder_app.FIRE"
        const val EXTRA_KEY = "key"

        /** Shown later than this counts as "late" in the fire log (D4 target: within 1 min). */
        private const val ON_TIME_MS = 60_000L

        fun deliver(context: Context, alarm: NativeDb.Alarm, now: Long) {
            val db = NativeDb.get(context)
            // SCH-6: never fire twice
            if (db.alreadyFired(alarm.key)) {
                db.deleteAlarm(alarm.key)
                return
            }
            val lateBy = now - alarm.fireAtUtcMs
            val outcome = when {
                lateBy > alarm.lateCutoffMs -> "missed" // SCH-7: beyond cutoff → digest, no notification
                !Notifications.enabled(context) -> "missed" // PRM-1: undelivered alerts count as missed
                else -> {
                    Notifications.showAlarm(context, alarm, late = lateBy > ON_TIME_MS)
                    if (lateBy > ON_TIME_MS) "late" else "shown"
                }
            }
            db.recordFire(alarm.key, alarm.fireAtUtcMs, now, outcome)
            db.deleteAlarm(alarm.key)
        }
    }
}
