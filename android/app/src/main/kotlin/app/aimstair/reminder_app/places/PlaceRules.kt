package app.aimstair.reminder_app.places

import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalDateTime

/**
 * The LOC-5 / LOC-7 checks Kotlin runs when a geofence fires — the same rules as
 * packages/core/lib/src/places/place_rules.dart. Dart already filtered the active days into the
 * payload (LOC-13); this decides which of them a moment belongs to.
 */
object PlaceRules {
    /** LOC-6: "Every time" rings at most this often per reminder. */
    const val EVERY_TIME_GAP_MS = 60 * 60 * 1000L

    /** LOC-9: a trigger Android delivers later than this is shown as "(late)". */
    const val LATE_AFTER_MS = 30 * 60 * 1000L

    data class Day(val day: LocalDate?, val occurrence: String)

    data class Reminder(
        val id: String,
        val title: String,
        val arrivedBody: String,
        val leftBody: String,
        val arrive: Boolean,
        val leave: Boolean,
        /** Minutes after midnight; -1 = any time. */
        val from: Int,
        val to: Int,
        val every: Boolean,
        val days: List<Day>,
    )

    data class Payload(val place: String, val lateCutoffMs: Long, val reminders: List<Reminder>)

    fun parse(json: String): Payload {
        val o = JSONObject(json)
        val list = o.getJSONArray("reminders")
        val reminders = (0 until list.length()).map { i ->
            val r = list.getJSONObject(i)
            val days = r.getJSONArray("days")
            Reminder(
                id = r.getString("id"),
                title = r.getString("title"),
                arrivedBody = r.getString("arrived"),
                leftBody = r.getString("left"),
                arrive = r.getBoolean("arrive"),
                leave = r.getBoolean("leave"),
                from = r.getInt("from"),
                to = r.getInt("to"),
                every = r.getBoolean("every"),
                days = (0 until days.length()).map { j ->
                    val d = days.getJSONObject(j)
                    Day(if (d.isNull("day")) null else LocalDate.parse(d.getString("day")), d.getString("occ"))
                },
            )
        }
        return Payload(o.getString("place"), o.getLong("late_ms"), reminders)
    }

    /**
     * LOC-5: the day whose hours contain [at], or null outside the hours. A range that ends at or
     * before it starts runs past midnight and belongs to the day it starts.
     */
    fun windowDay(from: Int, to: Int, at: LocalDateTime): LocalDate? {
        val day = at.toLocalDate()
        if (from < 0 || to < 0) return day
        val m = at.hour * 60 + at.minute
        if (from < to) return if (m in from until to) day else null
        if (m >= from) return day
        if (m < to) return day.minusDays(1)
        return null
    }

    /** LOC-7 (days + hours): the occurrence [r] would ring for at [at], or null. */
    fun occurrenceAt(r: Reminder, at: LocalDateTime): String? {
        val day = windowDay(r.from, r.to, at) ?: return null
        r.days.firstOrNull { it.day == null }?.let { return it.occurrence } // Any day
        return r.days.firstOrNull { it.day == day }?.occurrence
    }

    fun firesOn(r: Reminder, arrive: Boolean): Boolean = if (arrive) r.arrive else r.leave
}
