package app.aimstair.reminder_app.alarms

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import app.aimstair.reminder_app.MainActivity
import app.aimstair.reminder_app.R
import app.aimstair.reminder_app.platform.PendingLaunch

/** Builds and posts reminder notifications (NTF-*). Channels per docs/copy.md §2. */
object Notifications {
    const val CHANNEL_REMINDERS = "reminders"
    const val CHANNEL_NAG = "nag"
    const val CHANNEL_SYSTEM = "system"
    const val CHANNEL_DIGEST = "digest"
    private const val UNDO_VISIBLE_MS = 5_000L // NTF-9

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannels(
            listOf(
                NotificationChannel(CHANNEL_REMINDERS, context.getString(R.string.channel_reminders), NotificationManager.IMPORTANCE_HIGH)
                    .apply { description = context.getString(R.string.channel_reminders_desc) },
                NotificationChannel(CHANNEL_NAG, context.getString(R.string.channel_nag), NotificationManager.IMPORTANCE_HIGH)
                    .apply { description = context.getString(R.string.channel_nag_desc) },
                NotificationChannel(CHANNEL_DIGEST, context.getString(R.string.channel_digest), NotificationManager.IMPORTANCE_DEFAULT)
                    .apply { description = context.getString(R.string.channel_digest_desc) },
                NotificationChannel(CHANNEL_SYSTEM, context.getString(R.string.channel_system), NotificationManager.IMPORTANCE_LOW)
                    .apply { description = context.getString(R.string.channel_system_desc) },
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

    /** NTF-3: tapping the body opens that occurrence's detail screen (Dart reads `open:<alarmKey>`). */
    private fun openAppIntent(context: Context, key: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setData(Uri.parse("reminder://open/" + Uri.encode(key)))
            .putExtra(PendingLaunch.EXTRA_LAUNCH_ACTION, "open:$key")
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(
            context, idFor(key), intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    private fun builder(context: Context, channel: String): Notification.Builder =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(context, channel)
        else @Suppress("DEPRECATION") Notification.Builder(context)

    /** NTF-2: buttons per situation. */
    /** Button label resource → receiver action ([OPEN] launches the app instead, mockup 05). */
    private fun actionsFor(kind: String): List<Pair<Int, String>> = when (kind) {
        "occasion_prep" -> listOf(R.string.notif_tomorrow to ActionReceiver.TOMORROW,
            R.string.notif_prepared to ActionReceiver.PREPARED, R.string.notif_done to ActionReceiver.DONE)
        "occasion_day" -> listOf(R.string.notif_snooze_1h to ActionReceiver.SNOOZE, R.string.notif_done to ActionReceiver.DONE)
        "meeting" -> listOf(R.string.notif_snooze_5m to ActionReceiver.SNOOZE, R.string.notif_open to OPEN)
        "digest" -> emptyList() // DIG-3: tap opens the app
        "test" -> listOf(R.string.notif_snooze_1m to ActionReceiver.SNOOZE, R.string.notif_done to ActionReceiver.DONE)
        else -> listOf(R.string.notif_snooze_1h to ActionReceiver.SNOOZE,
            R.string.notif_tomorrow to ActionReceiver.TOMORROW, R.string.notif_done to ActionReceiver.DONE)
    }

    /** Pseudo-action: the button opens the reminder like tapping the body (NTF-3). */
    private const val OPEN = "open"

    fun showAlarm(context: Context, alarm: NativeDb.Alarm, late: Boolean) {
        ensureChannels(context)
        val channel = when {
            alarm.kind == "digest" -> CHANNEL_DIGEST
            alarm.key.contains(":nag") -> CHANNEL_NAG
            else -> CHANNEL_REMINDERS
        }
        val body = if (late) alarm.body + context.getString(R.string.notif_late_suffix) else alarm.body
        val b = builder(context, channel)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle(alarm.title)
            .setContentText(body)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setWhen(alarm.fireAtUtcMs)
            .setShowWhen(true)
            .setAutoCancel(true)
            .setContentIntent(openAppIntent(context, alarm.key))
        actionsFor(alarm.kind).forEach { (label, action) ->
            val intent = if (action == OPEN) openAppIntent(context, alarm.key) else actionIntent(context, alarm, action)
            b.addAction(Notification.Action.Builder(null, context.getString(label), intent).build())
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            b.setPriority(Notification.PRIORITY_HIGH).setDefaults(Notification.DEFAULT_ALL)
        }
        context.getSystemService(NotificationManager::class.java).notify(idFor(alarm.key), b.build())
    }

    /** NTF-9: replace the notification for 5 s with a confirmation + Undo. */
    fun showUndo(context: Context, alarm: NativeDb.Alarm, verbRes: Int) {
        val verb = context.getString(verbRes)
        ensureChannels(context)
        val b = builder(context, CHANNEL_SYSTEM)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle(verb)
            .setContentText(alarm.title)
            .setAutoCancel(true)
            .addAction(Notification.Action.Builder(null, context.getString(R.string.notif_undo),
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
