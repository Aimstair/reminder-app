package app.aimstair.reminder_app.alarms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import app.aimstair.reminder_app.places.GeofenceRegistrar
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

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
        // LOC-15: Android drops geofences after a reboot or app update.
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            val pending = goAsync()
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    runCatching { GeofenceRegistrar.registerAll(context) }
                } finally {
                    pending.finish()
                }
            }
        }
    }
}
