package app.aimstair.reminder_app.alarms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-registers alarms after reboot, app update, clock or time-zone change (SCH-5).
 * AlarmManager forgets everything on reboot; native.db remembers.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED",
            -> AlarmScheduler.rescheduleAll(context)
        }
    }
}
