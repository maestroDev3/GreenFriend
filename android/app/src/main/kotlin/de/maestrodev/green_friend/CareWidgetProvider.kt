package de.maestrodev.green_friend

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Home-screen widget with the plants needing care today. The Flutter app
 * writes the texts (see lib/data/home_care_widget.dart); this only draws them.
 */
class CareWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(widgetId, buildViews(context, widgetData))
        }
    }

    private fun buildViews(context: Context, data: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_care)
        views.setTextViewText(R.id.widget_title, data.getString("care_title", "Green Friend"))
        views.setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val stale = data.getString("care_day", null) != today
        val count = if (stale) 0 else data.getInt("care_count", 0)
        val message = when {
            stale -> data.getString("care_stale", "")
            count == 0 -> data.getString("care_empty", "")
            else -> null
        }
        views.setTextViewText(R.id.widget_message, message ?: "")
        views.setViewVisibility(R.id.widget_message, if (message == null) View.GONE else View.VISIBLE)

        ROWS.forEachIndexed { index, row ->
            if (index < count) {
                views.setViewVisibility(row.container, View.VISIBLE)
                views.setTextViewText(row.name, data.getString("care_row_${index}_name", ""))
                views.setTextViewText(row.tasks, data.getString("care_row_${index}_tasks", ""))
                val uri = data.getString("care_row_${index}_uri", null)
                if (uri == null) {
                    views.setViewVisibility(row.check, View.GONE)
                } else {
                    // Records the care in the background (Dart callback in
                    // lib/widget_actions.dart) without opening the app.
                    views.setViewVisibility(row.check, View.VISIBLE)
                    views.setOnClickPendingIntent(
                        row.check,
                        HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse(uri)),
                    )
                }
            } else {
                views.setViewVisibility(row.container, View.GONE)
            }
        }
        return views
    }

    private data class Row(val container: Int, val name: Int, val tasks: Int, val check: Int)

    companion object {
        private val ROWS = listOf(
            Row(R.id.row_0, R.id.row_0_name, R.id.row_0_tasks, R.id.row_0_check),
            Row(R.id.row_1, R.id.row_1_name, R.id.row_1_tasks, R.id.row_1_check),
            Row(R.id.row_2, R.id.row_2_name, R.id.row_2_tasks, R.id.row_2_check),
            Row(R.id.row_3, R.id.row_3_name, R.id.row_3_tasks, R.id.row_3_check),
            Row(R.id.row_4, R.id.row_4_name, R.id.row_4_tasks, R.id.row_4_check),
        )
    }
}
