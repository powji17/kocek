package com.powji.kocek

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget homescreen Kocek (PRD F9): total tabungan, progres satu target
 * (bar mini), tombol + untuk mencatat, dan waktu pembaruan.
 *
 * Semua teks sudah diformat di sisi Flutter dan disimpan lewat home_widget;
 * kelas ini hanya menampilkannya.
 */
class KocekWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.kocek_widget).apply {
                setTextViewText(
                    R.id.widget_total,
                    widgetData.getString("total_text", null) ?: "Buka Kocek",
                )
                setTextViewText(
                    R.id.widget_updated,
                    widgetData.getString("updated_text", null) ?: "",
                )

                val goalVisible = widgetData.getString("goal_visible", "0") == "1"
                setViewVisibility(
                    R.id.widget_goal_section,
                    if (goalVisible) View.VISIBLE else View.GONE,
                )
                if (goalVisible) {
                    val percent = (widgetData.getString("goal_percent", "0")?.toIntOrNull() ?: 0)
                        .coerceIn(0, 100)
                    setTextViewText(R.id.widget_goal_name, widgetData.getString("goal_name", "") ?: "")
                    setTextViewText(R.id.widget_goal_percent, "$percent%")
                    setProgressBar(R.id.widget_goal_progress, 100, percent, false)
                    setTextViewText(R.id.widget_goal_detail, widgetData.getString("goal_detail", "") ?: "")
                }

                // Ketuk widget = buka Kocek; ketuk tombol + = langsung layar catat.
                val openApp = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("kocek://home"),
                )
                setOnClickPendingIntent(R.id.widget_root, openApp)

                val openAdd = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("kocek://add"),
                )
                setOnClickPendingIntent(R.id.widget_add, openAdd)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
