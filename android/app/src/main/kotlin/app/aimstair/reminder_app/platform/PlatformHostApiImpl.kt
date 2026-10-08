package app.aimstair.reminder_app.platform

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.CalendarContract
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import java.io.File
import java.util.UUID
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Launch inputs that arrive before Dart is ready (cold start from the share sheet, the Quick Settings
 * tile, the widget or a notification). Dart takes each one exactly once.
 */
object PendingLaunch {
    @Volatile var sharedText: String? = null
    @Volatile var action: String? = null

    const val EXTRA_LAUNCH_ACTION = "launch_action"
    const val ACTION_CAPTURE = "capture"
}

/** Dart → Kotlin platform calls (pigeons/platform_api.dart). */
class PlatformHostApiImpl(private val activity: Activity) : PlatformHostApi {
    private val resolver get() = activity.contentResolver

    private var permissionResult: CompletableDeferred<Boolean>? = null
    private var createDocResult: CompletableDeferred<Uri?>? = null
    private var openDocResult: CompletableDeferred<Uri?>? = null
    private var pickFileResult: CompletableDeferred<Uri?>? = null
    private var pendingBackupJson: String? = null

    // ---- calendar (CAL-*) ----

    override fun hasCalendarPermission(): Boolean =
        activity.checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED

    override suspend fun requestCalendarPermission(): Boolean {
        if (hasCalendarPermission()) return true
        val result = CompletableDeferred<Boolean>()
        permissionResult = result
        activity.requestPermissions(arrayOf(Manifest.permission.READ_CALENDAR), REQ_CALENDAR)
        return result.await()
    }

    /** Called from MainActivity.onRequestPermissionsResult. */
    fun onPermissionResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQ_CALENDAR) return false
        permissionResult?.complete(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
        permissionResult = null
        return true
    }

    override fun readCalendars(): List<DeviceCalendar> {
        if (!hasCalendarPermission()) return emptyList()
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.CALENDAR_COLOR,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.ACCOUNT_TYPE,
            CalendarContract.Calendars.OWNER_ACCOUNT,
        )
        val out = mutableListOf<DeviceCalendar>()
        resolver.query(CalendarContract.Calendars.CONTENT_URI, projection, null, null, null)?.use { c ->
            while (c.moveToNext()) {
                val name = c.str(1) ?: ""
                out += DeviceCalendar(
                    id = c.getLong(0).toString(),
                    name = name,
                    color = c.getInt(2).toLong() and 0xFFFFFFFFL,
                    accountName = c.str(3) ?: "",
                    isBirthdays = isBirthdayCalendar(name, c.str(4), c.str(5)),
                )
            }
        }
        return out
    }

    override fun readEvents(fromMs: Long, toMs: Long, calendarIds: List<String>): List<DeviceEvent> {
        if (!hasCalendarPermission() || calendarIds.isEmpty()) return emptyList()
        val owners = calendarOwners()
        val projection = arrayOf(
            CalendarContract.Instances.CALENDAR_ID,
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.ALL_DAY,
            CalendarContract.Instances.EVENT_TIMEZONE,
            CalendarContract.Instances.RRULE,
        )
        val ids = calendarIds.mapNotNull { it.toLongOrNull() }
        if (ids.isEmpty()) return emptyList()
        val selection = "${CalendarContract.Instances.CALENDAR_ID} IN (${ids.joinToString(",")})"
        val uri = CalendarContract.Instances.CONTENT_URI.buildUpon().also {
            android.content.ContentUris.appendId(it, fromMs)
            android.content.ContentUris.appendId(it, toMs)
        }.build()
        val attendeeCache = HashMap<Long, Long>()
        val out = mutableListOf<DeviceEvent>()
        resolver.query(uri, projection, selection, null, "${CalendarContract.Instances.BEGIN} ASC")?.use { c ->
            while (c.moveToNext()) {
                val calendarId = c.getLong(0)
                val eventId = c.getLong(1)
                val others = attendeeCache.getOrPut(eventId) { otherAttendees(eventId, owners[calendarId]) }
                out += DeviceEvent(
                    calendarId = calendarId.toString(),
                    eventId = eventId.toString(),
                    title = c.str(2) ?: "",
                    beginMs = c.getLong(3),
                    endMs = c.getLong(4),
                    allDay = c.getInt(5) == 1,
                    timeZone = c.str(6),
                    rrule = c.str(7),
                    otherAttendees = others,
                )
            }
        }
        return out
    }

    private fun calendarOwners(): Map<Long, String?> {
        val out = HashMap<Long, String?>()
        resolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            arrayOf(CalendarContract.Calendars._ID, CalendarContract.Calendars.OWNER_ACCOUNT),
            null, null, null,
        )?.use { c -> while (c.moveToNext()) out[c.getLong(0)] = c.str(1) }
        return out
    }

    /** CAL-4 rule 3: attendees other than the calendar owner. */
    private fun otherAttendees(eventId: Long, owner: String?): Long {
        var n = 0L
        resolver.query(
            CalendarContract.Attendees.CONTENT_URI,
            arrayOf(CalendarContract.Attendees.ATTENDEE_EMAIL),
            "${CalendarContract.Attendees.EVENT_ID} = ?",
            arrayOf(eventId.toString()),
            null,
        )?.use { c ->
            while (c.moveToNext()) {
                val email = c.str(0)
                if (!email.isNullOrBlank() && !email.equals(owner, ignoreCase = true)) n++
            }
        }
        return n
    }

    // ---- share target / launch actions ----

    override fun takeSharedText(): String? = PendingLaunch.sharedText.also { PendingLaunch.sharedText = null }

    override fun takeLaunchAction(): String? = PendingLaunch.action.also { PendingLaunch.action = null }

    // ---- backup (DAT-5) ----

    override suspend fun saveBackup(fileName: String, json: String): String? {
        val result = CompletableDeferred<Uri?>()
        createDocResult = result
        pendingBackupJson = json
        activity.startActivityForResult(
            Intent(Intent.ACTION_CREATE_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE)
                .setType("application/json")
                .putExtra(Intent.EXTRA_TITLE, fileName),
            REQ_CREATE_DOC,
        )
        val uri = result.await() ?: return null
        val text = pendingBackupJson ?: return null
        pendingBackupJson = null
        withContext(Dispatchers.IO) {
            resolver.openOutputStream(uri, "wt")?.use { it.write(text.toByteArray(Charsets.UTF_8)) }
        }
        return uri.toString()
    }

    override suspend fun openBackup(): String? {
        val result = CompletableDeferred<Uri?>()
        openDocResult = result
        activity.startActivityForResult(
            Intent(Intent.ACTION_OPEN_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE)
                .setType("*/*")
                .putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "text/plain", "application/octet-stream")),
            REQ_OPEN_DOC,
        )
        val uri = result.await() ?: return null
        return withContext(Dispatchers.IO) {
            resolver.openInputStream(uri)?.use { it.readBytes().toString(Charsets.UTF_8) }
        }
    }

    // ---- attachments (ATT-3, ATT-4, ATT-6) ----

    /** Copies the picked file into app storage so it keeps opening even if the original moves. */
    override suspend fun pickAttachment(): PickedFile? {
        val result = CompletableDeferred<Uri?>()
        pickFileResult = result
        activity.startActivityForResult(
            Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("*/*"),
            REQ_PICK_FILE,
        )
        val uri = result.await() ?: return null
        return withContext(Dispatchers.IO) {
            var name = "file"
            var size = 0L
            resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use {
                if (it.moveToFirst()) {
                    it.str(0)?.let { n -> name = n }
                    if (!it.isNull(1)) size = it.getLong(1)
                }
            }
            if (size > MAX_ATTACHMENT_BYTES) throw FlutterError("too_large", "File is over 50 MB", null)
            val dir = File(activity.filesDir, "attachments/${UUID.randomUUID()}").apply { mkdirs() }
            val safe = name.replace(Regex("[/\\\\:*?\"<>|]"), "_").take(120)
            val out = File(dir, safe)
            resolver.openInputStream(uri)?.use { input -> out.outputStream().use { input.copyTo(it) } }
                ?: return@withContext null
            PickedFile(out.absolutePath, name, out.length(), resolver.getType(uri))
        }
    }

    override fun openAttachment(path: String, mime: String?): Boolean {
        val file = File(path)
        if (!file.exists() || !file.canonicalPath.startsWith(attachmentsDir().canonicalPath)) return false
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.files", file)
        val view = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, mime ?: resolver.getType(uri) ?: "*/*")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return try {
            activity.startActivity(Intent.createChooser(view, null).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    override fun deleteAttachment(path: String) {
        val file = File(path)
        if (!file.canonicalPath.startsWith(attachmentsDir().canonicalPath)) return
        // Each file sits in its own attachments/<uuid>/ folder; remove the folder with it.
        val folder = file.parentFile
        if (folder != null && folder.parentFile?.canonicalPath == attachmentsDir().canonicalPath) {
            folder.deleteRecursively()
        } else {
            file.delete()
        }
    }

    private fun attachmentsDir() = File(activity.filesDir, "attachments")

    /** Called from MainActivity.onActivityResult. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
        when (requestCode) {
            REQ_CREATE_DOC -> { createDocResult?.complete(uri); createDocResult = null }
            REQ_OPEN_DOC -> { openDocResult?.complete(uri); openDocResult = null }
            REQ_PICK_FILE -> { pickFileResult?.complete(uri); pickFileResult = null }
            else -> return false
        }
        return true
    }

    // ---- widget & device ----

    override fun updateWidget(json: String) = ReminderWidget.update(activity, json)

    override fun deviceBrand(): String = Build.MANUFACTURER ?: ""

    override fun deviceInfo(): String =
        "${Build.MANUFACTURER} ${Build.MODEL} · Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"

    override fun shareText(text: String) {
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
        }
        activity.startActivity(Intent.createChooser(send, null))
    }

    companion object {
        private const val REQ_CALENDAR = 2001
        private const val REQ_CREATE_DOC = 3001
        private const val REQ_OPEN_DOC = 3002
        private const val REQ_PICK_FILE = 3003
        private const val MAX_ATTACHMENT_BYTES = 50L * 1024 * 1024

        /** CAL-4 rule 1 / CON-7: Google's and Samsung's contact birthday calendars. */
        fun isBirthdayCalendar(name: String, accountType: String?, owner: String?): Boolean =
            owner?.contains("#contacts@group.v.calendar.google.com") == true ||
                accountType == "com.android.contacts" ||
                accountType?.contains("birthday", ignoreCase = true) == true ||
                name.contains("birthday", ignoreCase = true)

        private fun Cursor.str(i: Int): String? = if (isNull(i)) null else getString(i)
    }
}
