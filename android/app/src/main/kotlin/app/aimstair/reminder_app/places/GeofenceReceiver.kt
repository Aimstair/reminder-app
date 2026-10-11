package app.aimstair.reminder_app.places

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import app.aimstair.reminder_app.alarms.NativeDb
import app.aimstair.reminder_app.alarms.Notifications
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId

/**
 * A geofence fired (LOC-7, LOC-9). Runs without Flutter: checks each reminder at the place, posts
 * the notification and records the fire in the journal so Dart marks the occurrence fired (LOC-8).
 */
class GeofenceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError()) return
        val arrive = when (event.geofenceTransition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> true
            Geofence.GEOFENCE_TRANSITION_EXIT -> false
            else -> return
        }
        val now = System.currentTimeMillis()
        val happenedAt = event.triggeringLocation?.time?.takeIf { it in 1..now } ?: now
        val db = NativeDb.get(context)
        event.triggeringGeofences.orEmpty().forEach { g ->
            val row = db.geofence(g.requestId) ?: return@forEach
            val payload = runCatching { PlaceRules.parse(row.payload) }.getOrNull() ?: return@forEach
            fire(context, payload, arrive, happenedAt, now)
        }
    }

    companion object {
        const val ACTION = "app.aimstair.reminder_app.GEOFENCE"
        const val ARRIVED = "app.aimstair.reminder_app.PLACE_ARRIVED"
        const val LEFT = "app.aimstair.reminder_app.PLACE_LEFT"

        fun fire(context: Context, payload: PlaceRules.Payload, arrive: Boolean, happenedAt: Long, now: Long) {
            val db = NativeDb.get(context)
            // LOC-5: hours are device local time at the moment it happened.
            val at = LocalDateTime.ofInstant(Instant.ofEpochMilli(happenedAt), ZoneId.systemDefault())
            for (r in payload.reminders) {
                if (!PlaceRules.firesOn(r, arrive)) continue
                val occ = PlaceRules.occurrenceAt(r, at) ?: continue // outside days/hours: ignored, no catch-up
                if (db.placeDone(occ)) continue
                if (!r.every && db.placeFired(occ)) continue // LOC-6 first time
                val last = db.lastPlaceFire(r.id)
                if (r.every && last != null && now - last < PlaceRules.EVERY_TIME_GAP_MS) continue // LOC-6 every time
                db.recordPlaceFire(occ, r.id, if (arrive) "arrive" else "leave", now)

                val key = "$occ:place:$now"
                db.journal(key, if (arrive) ARRIVED else LEFT) // LOC-8: Dart marks it fired
                val lateBy = now - happenedAt
                val alarm = NativeDb.Alarm(
                    key = key,
                    fireAtUtcMs = happenedAt,
                    title = r.title,
                    body = if (arrive) r.arrivedBody else r.leftBody,
                    kind = "place",
                    lateCutoffMs = payload.lateCutoffMs,
                    exact = true,
                )
                val outcome = when {
                    lateBy > payload.lateCutoffMs -> "missed" // LOC-9 → SCH-7
                    !Notifications.enabled(context) -> "missed"
                    else -> {
                        Notifications.showAlarm(context, alarm, late = lateBy > PlaceRules.LATE_AFTER_MS)
                        if (lateBy > PlaceRules.LATE_AFTER_MS) "late" else "shown"
                    }
                }
                db.recordFire(key, happenedAt, now, outcome)
            }
        }
    }
}
