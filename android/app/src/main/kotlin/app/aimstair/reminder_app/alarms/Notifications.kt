package app.aimstair.reminder_app.alarms

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build

/** Builds and posts reminder notifications (NTF-*). Channels per docs/copy.md §2. */
object Notifications {
    const val CHANNEL_REMINDERS = "reminders"
    const val CHANNEL_NAG = "nag"
    const val CHANNEL_SYSTEM = "system"
    private const val UNDO_VISIBLE_MS = 5_000L // NTF-9

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannels(
            listOf(
                NotificationChannel(CHANNEL_REMINDERS, "Reminders", NotificationManager.IMPORTANCE_HIGH)
                    .apply { description = "Alerts for your reminders" },
                NotificationChannel(CHANNEL_NAG, "Nagging reminders", NotificationManager.IMPORTANCE_HIGH)
                    .apply { description = "Repeat alerts until you mark something done" },
                NotificationChannel(CHANNEL_SYSTEM, "App status", NotificationManager.IMPORTANCE_LOW)
                    .apply { description = "Late alerts, time zone changes, reliability tips" },
            )
        )
    }

    /** Stable notification id per alarm key, so updates replace and cancels find it. */
    fun idFor(key: String): Int = key.hashCode()

    /** Buttons carry the alarm's fields, because the alarm row is gone once it has fired. */
    private fun actionIntent(context: Context, alarm: NativeDb.Alarm, action: String): PendingIntent {
        val intent = Intent(context, ActionReceiver::class.java)
            .setAction(action)
            .setData(Uri.parse("reminder://action/" + Uri.encode(alarm.key) + "/" + action))
            .putExtra(AlarmReceiver.EXTRA_KEY, alarm.key)
            .putExtra(ActionReceiver.EXTRA_TITLE, alarm.title)
            .putExtra(ActionReceiver.EXTRA_BODY, alarm.body)
            .putExtra(ActionReceiver.EXTRA_KIND, alarm.kind)
            .putExtra(ActionReceiver.EXTRA_CUTOFF, alarm.lateCutoffMs)
        return PendingIntent.getBroadcast(
            context, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    private fun openAppIntent(context: Context): PendingIntent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        return PendingIntent.getActivity(context, 0, launch, PendingIntent.FLAG_IMMUTABLE)
    }

    private fun builder(context: Context, channel: String): Notification.Builder =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(context, channel)
        else @Suppress("DEPRECATION") Notification.Builder(context)

    /** NTF-2: buttons per situation. */
    private fun actionsFor(kind: String): List<Pair<String, String>> = when (kind) {
        "occasion_prep" -> listOf("Tomorrow" to ActionReceiver.TOMORROW,
            "I'm prepared" to ActionReceiver.PREPARED, "Done" to ActionReceiver.DONE)
        "occasion_day" -> listOf("Snooze 1h" to ActionReceiver.SNOOZE, "Done" to ActionReceiver.DONE)
        "meeting" -> listOf("Snooze 5m" to ActionReceiver.SNOOZE)
        "test" -> listOf("Snooze 1m" to ActionReceiver.SNOOZE, "Done" to ActionReceiver.DONE)
        else -> listOf("Snooze 1h" to ActionReceiver.SNOOZE,
            "Tomorrow" to ActionReceiver.TOMORROW, "Done" to ActionReceiver.DONE)
    }

    fun showAlarm(context: Context, alarm: NativeDb.Alarm, late: Boolean) {
        ensureChannels(context)
        val channel = if (alarm.key.contains(":nag")) CHANNEL_NAG else CHANNEL_REMINDERS
        val body = if (late) alarm.body + " · late" else alarm.body
        val b = builder(context, channel)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle(alarm.title)
            .setContentText(body)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setWhen(alarm.fireAtUtcMs)
            .setShowWhen(true)
            .setAutoCancel(true)
            .setContentIntent(openAppIntent(context))
        actionsFor(alarm.kind).forEach { (label, action) ->
            b.addAction(Notification.Action.Builder(null, label, actionIntent(context, alarm, action)).build())
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            b.setPriority(Notification.PRIORITY_HIGH).setDefaults(Notification.DEFAULT_ALL)
        }
        context.getSystemService(NotificationManager::class.java).notify(idFor(alarm.key), b.build())
    }

    /** NTF-9: replace the notification for 5 s with a confirmation + Undo. */
    fun showUndo(context: Context, alarm: NativeDb.Alarm, verb: String) {
        ensureChannels(context)
        val b = builder(context, CHANNEL_SYSTEM)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle(verb)
            .setContentText(alarm.title)
            .setAutoCancel(true)
            .addAction(Notification.Action.Builder(null, "Undo",
                actionIntent(context, alarm, ActionReceiver.UNDO)).build())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) b.setTimeoutAfter(UNDO_VISIBLE_MS)
        context.getSystemService(NotificationManager::class.java).notify(idFor(alarm.key), b.build())
    }

    fun dismiss(context: Context, key: String) {
        context.getSystemService(NotificationManager::class.java).cancel(idFor(key))
    }

    fun enabled(context: Context): Boolean =
        context.getSystemService(NotificationManager::class.java).areNotificationsEnabled()
}
