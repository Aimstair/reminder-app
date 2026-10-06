package app.aimstair.reminder_app.alarms

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings

/** Dart → Kotlin entry point (Pigeon). Dart plans, Kotlin executes (docs/architecture.md §1). */
class AlarmHostApiImpl(private val activity: Activity) : AlarmHostApi {
    private val context get() = activity.applicationContext
    private val db get() = NativeDb.get(context)

    override fun sync(alarms: List<AlarmSpec>) {
        // SCH-4: diff by key — cancel what's gone, add/replace the rest
        val wanted = alarms.associateBy { it.key }
        db.allAlarms().filter { it.key !in wanted }.forEach { AlarmScheduler.cancel(context, it.key) }
        alarms.forEach { spec ->
            AlarmScheduler.schedule(
                context,
                NativeDb.Alarm(
                    key = spec.key,
                    fireAtUtcMs = spec.fireAtUtcMs,
                    title = spec.title,
                    body = spec.body,
                    kind = spec.kind,
                    lateCutoffMs = spec.lateCutoffMs,
                    exact = true,
                )
            )
        }
    }

    override fun cancel(keys: List<String>) = keys.forEach { AlarmScheduler.cancel(context, it) }

    override fun registered(): List<RegisteredAlarm> = db.allAlarms().map {
        RegisteredAlarm(
            spec = AlarmSpec(
                key = it.key, fireAtUtcMs = it.fireAtUtcMs, title = it.title,
                body = it.body, kind = it.kind, lateCutoffMs = it.lateCutoffMs,
            ),
            exact = it.exact,
        )
    }

    override fun getPermissionState(): PermissionState {
        val pm = context.getSystemService(PowerManager::class.java)
        return PermissionState(
            notifications = Notifications.enabled(context),
            exactAlarms = AlarmScheduler.canScheduleExact(context),
            ignoringBatteryOptimizations = pm.isIgnoringBatteryOptimizations(context.packageName),
        )
    }

    override fun requestNotificationPermission() {
        // PRM-6: asked at first save with alerts (spike: on demand)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
        }
    }

    override fun openExactAlarmSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            activity.startActivity(
                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:" + context.packageName))
            )
        }
    }

    override fun openBatteryOptimizationSettings() {
        activity.startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
    }

    override fun readJournal(): List<JournalEntry> = db.unappliedJournal()

    override fun markApplied(ids: List<Long>) = db.markApplied(ids)

    override fun getFireLog(sinceMs: Long): List<FireLogEntry> = db.fireLog(sinceMs)

    override fun clearLogs() = db.clearLogs()
}
