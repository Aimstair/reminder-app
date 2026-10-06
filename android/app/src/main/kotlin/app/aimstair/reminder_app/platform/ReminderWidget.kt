package app.aimstair.reminder_app.platform

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import app.aimstair.reminder_app.MainActivity
import app.aimstair.reminder_app.R
import org.json.JSONObject

/**
 * S-61 home-screen widget: [+] quick add and the next 3 reminders. Dart pushes the content as JSON
 * (`{"items":[{"title","when"}],"empty":"…"}`) via PlatformHostApi.updateWidget; it is kept in
 * SharedPreferences so the widget can redraw without Flutter.
 */
class ReminderWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    companion object {
        private const val PREFS = "reminder_widget"
        private const val KEY_JSON = "json"

        private val rows = listOf(
            Triple(R.id.widget_row1, R.id.widget_row1_title, R.id.widget_row1_when),
            Triple(R.id.widget_row2, R.id.widget_row2_title, R.id.widget_row2_when),
            Triple(R.id.widget_row3, R.id.widget_row3_title, R.id.widget_row3_when),
        )

        fun update(context: Context, json: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY_JSON, json).apply()
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, ReminderWidget::class.java))
            if (ids.isNotEmpty()) render(context, manager, ids)
        }

        /** [action] null = just open the app. */
        fun launchIntent(context: Context, action: String?, requestCode: Int): PendingIntent {
            val intent = Intent(context, MainActivity::class.java)
                .apply { if (action != null) putExtra(PendingLaunch.EXTRA_LAUNCH_ACTION, action) }
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            return PendingIntent.getActivity(
                context, requestCode, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }

        private fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val json = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_JSON, null)
            val data = runCatching { JSONObject(json ?: "{}") }.getOrDefault(JSONObject())
            val items = data.optJSONArray("items")
            val views = RemoteViews(context.packageName, R.layout.reminder_widget)

            views.setOnClickPendingIntent(R.id.widget_add, launchIntent(context, PendingLaunch.ACTION_CAPTURE, 1))
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context, null, 2))

            val count = minOf(items?.length() ?: 0, rows.size)
            rows.forEachIndexed { i, (row, title, whenId) ->
                if (i < count) {
                    val item = items!!.getJSONObject(i)
                    views.setViewVisibility(row, View.VISIBLE)
                    views.setTextViewText(title, item.optString("title"))
                    views.setTextViewText(whenId, item.optString("when"))
                } else {
                    views.setViewVisibility(row, View.GONE)
                }
            }
            views.setViewVisibility(R.id.widget_empty, if (count == 0) View.VISIBLE else View.GONE)
            views.setTextViewText(
                R.id.widget_empty,
                data.optString("empty").ifEmpty { context.getString(R.string.widget_empty) },
            )
            manager.updateAppWidget(ids, views)
        }
    }
}
