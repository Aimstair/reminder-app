package app.aimstair.reminder_app.alarms

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build

/** Registers alarms with AlarmManager. The only scheduling code on the firing path (SCH-1). */
object AlarmScheduler {
    /** SCH-9: inexact fallback window when exact alarms aren't allowed. */
    private const val INEXACT_WINDOW_MS = 10 * 60 * 1000L

    fun canScheduleExact(context: Context): Boolean {
        val am = context.getSystemService(AlarmManager::class.java)
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
    }

    /** SCH-4: same key always maps to the same PendingIntent, so re-registering replaces. */
    private fun pendingIntent(context: Context, key: String, flags: Int): PendingIntent? {
        val intent = Intent(context, AlarmReceiver::class.java)
            .setAction(AlarmReceiver.ACTION_FIRE)
            .setData(Uri.parse("reminder://alarm/" + Uri.encode(key)))
            .putExtra(AlarmReceiver.EXTRA_KEY, key)
        return PendingIntent.getBroadcast(context, 0, intent, flags or PendingIntent.FLAG_IMMUTABLE)
    }

    fun register(context: Context, alarm: NativeDb.Alarm) {
        val am = context.getSystemService(AlarmManager::class.java)
        val pi = pendingIntent(context, alarm.key, PendingIntent.FLAG_UPDATE_CURRENT)!!
        val exact = canScheduleExact(context)
        if (exact) {
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarm.fireAtUtcMs, pi)
        } else {
            am.setWindow(AlarmManager.RTC_WAKEUP, alarm.fireAtUtcMs, INEXACT_WINDOW_MS, pi) // SCH-9
        }
        NativeDb.get(context).setExact(alarm.key, exact)
    }

    fun unregister(context: Context, key: String) {
        val am = context.getSystemService(AlarmManager::class.java)
        pendingIntent(context, key, PendingIntent.FLAG_NO_CREATE)?.let {
            am.cancel(it)
            it.cancel()
        }
    }

    /** Save + register. */
    fun schedule(context: Context, alarm: NativeDb.Alarm) {
        NativeDb.get(context).upsertAlarm(alarm)
        register(context, alarm)
    }

    /** Remove from db, AlarmManager and the notification shade (OCC-4). */
    fun cancel(context: Context, key: String) {
        unregister(context, key)
        NativeDb.get(context).deleteAlarm(key)
        Notifications.dismiss(context, key)
    }

    /**
     * Re-register everything after boot, app update, time or time-zone change (SCH-5).
     * Alarms already due are handled per SCH-7: shown if within the late cutoff, else missed.
     */
    fun rescheduleAll(context: Context) {
        val db = NativeDb.get(context)
        val now = System.currentTimeMillis()
        db.allAlarms().forEach { alarm ->
            if (alarm.fireAtUtcMs > now) {
                register(context, alarm)
            } else {
                AlarmReceiver.deliver(context, alarm, now)
            }
        }
    }
}
