package app.aimstair.reminder_app.alarms

import app.aimstair.reminder_app.R
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId

/**
 * Notification buttons, handled natively without starting Flutter (NTF-8).
 * Every tap is written to the journal; Dart applies it to app.db on its next run.
 */
class ActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val key = intent.getStringExtra(AlarmReceiver.EXTRA_KEY) ?: return
        val alarm = NativeDb.Alarm(
            key = key,
            fireAtUtcMs = System.currentTimeMillis(),
            title = intent.getStringExtra(EXTRA_TITLE) ?: "",
            body = intent.getStringExtra(EXTRA_BODY) ?: "",
            kind = intent.getStringExtra(EXTRA_KIND) ?: "task",
            lateCutoffMs = intent.getLongExtra(EXTRA_CUTOFF, DEFAULT_CUTOFF_MS),
            exact = true,
        )
        val db = NativeDb.get(context)
        val action = intent.action ?: return
        db.journal(key, action)

        when (action) {
            DONE -> {
                cancelSiblings(context, key, keepDayOf = false) // OCC-4
                val verb = if (alarm.kind == "bill") R.string.notif_confirm_paid else R.string.notif_confirm_done
                Notifications.showUndo(context, alarm, verb) // NTF-9, BIL-4
            }
            PREPARED -> {
                cancelSiblings(context, key, keepDayOf = true) // OCC-3: day-of alert still rings
                Notifications.showUndo(context, alarm, R.string.notif_confirm_prepared)
            }
            SNOOZE -> {
                // NTF-4: snooze delays the alert only, never the due date
                val delay = when (alarm.kind) {
                    "meeting" -> 5 * MINUTE
                    "test" -> MINUTE
                    else -> 60 * MINUTE
                }
                rescheduleAs(context, alarm, System.currentTimeMillis() + delay)
            }
            TOMORROW -> rescheduleAs(context, alarm, tomorrowAtDayTime()) // NTF-4, PRF-5 default
            UNDO -> {
                // Spike: Dart restores cancelled alarms when it reconciles the journal.
                Notifications.dismiss(context, key)
            }
        }
    }

    private fun rescheduleAs(context: Context, alarm: NativeDb.Alarm, fireAt: Long) {
        Notifications.dismiss(context, alarm.key)
        val base = alarm.key.substringBefore(":snz")
        AlarmScheduler.schedule(context, alarm.copy(key = "$base:snz$fireAt", fireAtUtcMs = fireAt))
    }

    /** Cancel the occurrence's other alerts. Key format: occurrence_id:stage:nag_seq (SCH-4). */
    private fun cancelSiblings(context: Context, key: String, keepDayOf: Boolean) {
        val occurrence = key.substringBefore(':')
        NativeDb.get(context).allAlarms()
            .filter { it.key.substringBefore(':') == occurrence && it.key != key }
            .filterNot { keepDayOf && it.kind == "occasion_day" }
            .forEach { AlarmScheduler.cancel(context, it.key) }
    }

    private fun tomorrowAtDayTime(): Long =
        LocalDate.now().plusDays(1).atTime(LocalTime.of(9, 0))
            .atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()

    companion object {
        const val DONE = "app.aimstair.reminder_app.DONE"
        const val PREPARED = "app.aimstair.reminder_app.PREPARED"
        const val SNOOZE = "app.aimstair.reminder_app.SNOOZE"
        const val TOMORROW = "app.aimstair.reminder_app.TOMORROW"
        const val UNDO = "app.aimstair.reminder_app.UNDO"

        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_KIND = "kind"
        const val EXTRA_CUTOFF = "late_cutoff"

        private const val MINUTE = 60_000L
        private const val DEFAULT_CUTOFF_MS = 2 * 60 * MINUTE // PRF-6 default
    }
}
