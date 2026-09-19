package com.sam4g.app_settings

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class WidgetSmallProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_small).apply {
                val isConnected = widgetData.getBoolean("is_connected", false)
                val balanceVal = widgetData.getString("balance_val", "28.4")
                val balanceUnit = widgetData.getString("balance_unit", "GB")
                val daysRemaining = widgetData.getString("days_remaining", "14 يوم متبقي")
                val batteryLevel = widgetData.getInt("battery_level", 92)
                val devicesCount = widgetData.getInt("devices_count", 3)
                val totalText = widgetData.getString("total_text", "GB 40.0")
                val consumedText = widgetData.getString("consumed_text", "GB 11.6")
                val quotaProgress = widgetData.getInt("quota_progress_int", 71)

                setTextViewText(R.id.tv_status_text, if (isConnected) "متصل" else "غير متصل")
                setImageViewResource(
                    R.id.iv_status_indicator,
                    if (isConnected) R.drawable.ic_dot_green else R.drawable.ic_dot_red
                )
                setTextViewText(R.id.tv_title, "SAM4G")
                setTextViewText(R.id.tv_balance_unit, balanceUnit)
                setTextViewText(R.id.tv_balance_value, balanceVal)
                setTextViewText(R.id.tv_days_remaining, daysRemaining)
                setProgressBar(R.id.pb_quota, 100, quotaProgress, false)
                setTextViewText(R.id.tv_total_plan, "$totalText :الإجمالي")
                setTextViewText(R.id.tv_consumed, "$consumedText :المستهلك")
                setTextViewText(R.id.tv_devices, "$devicesCount أجهزة")
                setTextViewText(R.id.tv_battery, "$batteryLevel%")

                // Open App on click
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_small_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class WidgetBannerProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_banner).apply {
                val isConnected = widgetData.getBoolean("is_connected", false)
                val balanceVal = widgetData.getString("balance_val", "28.4")
                val balanceUnit = widgetData.getString("balance_unit", "GB")
                val daysRemaining = widgetData.getString("days_remaining", "14 يوم متبقي")
                val batteryLevel = widgetData.getInt("battery_level", 92)
                val signalBars = widgetData.getInt("signal_bars", 5)
                val devicesCount = widgetData.getInt("devices_count", 3)
                val quotaProgress = widgetData.getInt("quota_progress_int", 71)

                setTextViewText(R.id.tv_banner_battery, "$batteryLevel%")
                setTextViewText(R.id.tv_banner_signal, "4G $signalBars/5")
                setTextViewText(R.id.tv_banner_devices, "$devicesCount أجهزة")
                setTextViewText(R.id.tv_banner_balance_unit, balanceUnit)
                setTextViewText(R.id.tv_banner_balance_val, balanceVal)
                setTextViewText(R.id.tv_banner_days, daysRemaining)
                setProgressBar(R.id.pb_banner_quota, 100, quotaProgress, false)
                setImageViewResource(
                    R.id.iv_banner_status_dot,
                    if (isConnected) R.drawable.ic_dot_green else R.drawable.ic_dot_red
                )
                setTextViewText(R.id.tv_banner_title, "SAM4G")

                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    1,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_banner_root, pendingIntent)
                setOnClickPendingIntent(R.id.btn_banner_refresh, pendingIntent)
                setOnClickPendingIntent(R.id.btn_banner_wifi, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class WidgetDetailedProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_detailed).apply {
                val isConnected = widgetData.getBoolean("is_connected", false)
                val balanceText = widgetData.getString("balance_text", "-- GB")
                val daysRemaining = widgetData.getString("days_remaining", "-- يوم متبقي")
                val batteryLevel = widgetData.getInt("battery_level", 0)
                val signalText = widgetData.getString("signal_text", "4G LTE")
                val devicesCount = widgetData.getInt("devices_count", 0)
                val lastUpdated = widgetData.getString("last_updated_time", "00:00")

                setTextViewText(R.id.tv_det_balance, balanceText)
                setTextViewText(R.id.tv_det_days, daysRemaining)
                setTextViewText(R.id.tv_det_battery, "البطارية: $batteryLevel%")
                setTextViewText(R.id.tv_det_devices, "الأجهزة: $devicesCount")
                setTextViewText(R.id.tv_det_signal, "الإشارة: $signalText")
                setTextViewText(R.id.tv_det_updated, lastUpdated)
                setTextViewText(R.id.tv_det_status, if (isConnected) "متصل" else "غير متصل")
                setImageViewResource(
                    R.id.iv_det_status_dot,
                    if (isConnected) R.drawable.ic_dot_green else R.drawable.ic_dot_red
                )

                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    2,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_detailed_root, pendingIntent)
                setOnClickPendingIntent(R.id.btn_det_open, pendingIntent)
                setOnClickPendingIntent(R.id.btn_det_refresh, pendingIntent)
                setOnClickPendingIntent(R.id.btn_det_reboot, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
