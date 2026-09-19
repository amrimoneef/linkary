package com.sam4g.app_settings

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

// ══════════════════════════════════════════════════════════════════
// قاعدة مشتركة لجميع Providers — تقرأ البيانات من HomeWidgetPlugin
// ══════════════════════════════════════════════════════════════════
abstract class LinkaryBaseWidgetProvider : AppWidgetProvider() {

    /** كل subclass يُحدد layout الخاص به */
    abstract val layoutRes: Int

    /** كل subclass يملأ الـ RemoteViews بالبيانات */
    abstract fun applyData(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutRes)
            applyData(context, views, widgetData)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// ══════════════════════════════════════════════════════════════════
// الويدجت المصغر (2×2) — مربع الرصيد
// ══════════════════════════════════════════════════════════════════
class WidgetSmallProvider : LinkaryBaseWidgetProvider() {

    override val layoutRes = R.layout.widget_small

    override fun applyData(context: Context, views: RemoteViews, widgetData: SharedPreferences) {
        val isConnected   = widgetData.getBoolean("is_connected", false)
        val balanceVal    = widgetData.getString("balance_val", "--")  ?: "--"
        val balanceUnit   = widgetData.getString("balance_unit", "GB") ?: "GB"
        val daysRemaining = widgetData.getString("days_remaining", "-- يوم متبقي") ?: "-- يوم متبقي"
        val batteryLevel  = widgetData.getInt("battery_level", 0)
        val devicesCount  = widgetData.getInt("devices_count", 0)
        val totalText     = widgetData.getString("total_text", "GB 0.0")  ?: "GB 0.0"
        val consumedText  = widgetData.getString("consumed_text", "GB 0.0") ?: "GB 0.0"
        val quotaProgress = widgetData.getInt("quota_progress_int", 0)

        views.apply {
            setTextViewText(R.id.tv_status_text,
                if (isConnected) "متصل" else "غير متصل")
            setImageViewResource(R.id.iv_status_indicator,
                if (isConnected) R.drawable.ic_dot_green else R.drawable.ic_dot_red)
            setTextViewText(R.id.tv_title, "SAM4G")
            setTextViewText(R.id.tv_balance_unit, balanceUnit)
            setTextViewText(R.id.tv_balance_value, balanceVal)
            setTextViewText(R.id.tv_days_remaining, daysRemaining)
            setProgressBar(R.id.pb_quota, 100, quotaProgress, false)
            setTextViewText(R.id.tv_total_plan, "الإجمالي: $totalText")
            setTextViewText(R.id.tv_consumed, "المستهلك: $consumedText")
            setTextViewText(R.id.tv_devices, "$devicesCount أجهزة")
            setTextViewText(R.id.tv_battery, "$batteryLevel%")

            // ✅ الضغط على الويدجت يفتح التطبيق
            setOnClickPendingIntent(R.id.widget_small_root,
                WidgetActionReceiver.buildOpenAppIntent(context, 10))
        }
    }
}

// ══════════════════════════════════════════════════════════════════
// الويدجت الشريطي (4×1) — بانر أفقي
// ══════════════════════════════════════════════════════════════════
class WidgetBannerProvider : LinkaryBaseWidgetProvider() {

    override val layoutRes = R.layout.widget_banner

    override fun applyData(context: Context, views: RemoteViews, widgetData: SharedPreferences) {
        val isConnected   = widgetData.getBoolean("is_connected", false)
        val balanceVal    = widgetData.getString("balance_val", "--")  ?: "--"
        val balanceUnit   = widgetData.getString("balance_unit", "GB") ?: "GB"
        val daysRemaining = widgetData.getString("days_remaining", "-- يوم متبقي") ?: "-- يوم متبقي"
        val batteryLevel  = widgetData.getInt("battery_level", 0)
        val signalBars    = widgetData.getInt("signal_bars", 0)
        val devicesCount  = widgetData.getInt("devices_count", 0)
        val quotaProgress = widgetData.getInt("quota_progress_int", 0)

        views.apply {
            setTextViewText(R.id.tv_banner_battery, "$batteryLevel%")
            setTextViewText(R.id.tv_banner_signal, "4G $signalBars/5")
            setTextViewText(R.id.tv_banner_devices, "$devicesCount")
            setTextViewText(R.id.tv_banner_balance_unit, balanceUnit)
            setTextViewText(R.id.tv_banner_balance_val, balanceVal)
            setTextViewText(R.id.tv_banner_days, daysRemaining)
            setProgressBar(R.id.pb_banner_quota, 100, quotaProgress, false)
            setImageViewResource(R.id.iv_banner_status_dot,
                if (isConnected) R.drawable.ic_dot_green else R.drawable.ic_dot_red)
            setTextViewText(R.id.tv_banner_title, "SAM4G")

            // ✅ الضغط على الجسم الرئيسي → فتح التطبيق
            setOnClickPendingIntent(R.id.widget_banner_root,
                WidgetActionReceiver.buildOpenAppIntent(context, 20))

            // ✅ زر التحديث → يحدث الويدجت في الخلفية فقط
            setOnClickPendingIntent(R.id.btn_banner_refresh,
                WidgetActionReceiver.buildRefreshIntent(context, 21))

            // ✅ زر الواي-فاي → يفتح التطبيق على شاشة الأجهزة المتصلة
            setOnClickPendingIntent(R.id.btn_banner_wifi,
                WidgetActionReceiver.buildOpenAppIntent(context, 22))
        }
    }
}

// ══════════════════════════════════════════════════════════════════
// الويدجت التفصيلي (4×2) — البطاقة التفاعلية المتكاملة
// ══════════════════════════════════════════════════════════════════
class WidgetDetailedProvider : LinkaryBaseWidgetProvider() {

    override val layoutRes = R.layout.widget_detailed

    override fun applyData(context: Context, views: RemoteViews, widgetData: SharedPreferences) {
        val isConnected   = widgetData.getBoolean("is_connected", false)
        val balanceText   = widgetData.getString("balance_text", "-- GB") ?: "-- GB"
        val daysRemaining = widgetData.getString("days_remaining", "-- يوم متبقي") ?: "-- يوم متبقي"
        val batteryLevel  = widgetData.getInt("battery_level", 0)
        val signalText    = widgetData.getString("signal_text", "4G LTE") ?: "4G LTE"
        val devicesCount  = widgetData.getInt("devices_count", 0)
        val lastUpdated   = widgetData.getString("last_updated_time", "--:--") ?: "--:--"

        views.apply {
            setTextViewText(R.id.tv_det_balance, balanceText)
            setTextViewText(R.id.tv_det_days, daysRemaining)
            setTextViewText(R.id.tv_det_battery, "البطارية: $batteryLevel%")
            setTextViewText(R.id.tv_det_devices, "الأجهزة: $devicesCount")
            setTextViewText(R.id.tv_det_signal, "الإشارة: $signalText")
            setTextViewText(R.id.tv_det_updated, lastUpdated)
            setTextViewText(R.id.tv_det_status,
                if (isConnected) "متصل" else "غير متصل")
            setImageViewResource(R.id.iv_det_status_dot,
                if (isConnected) R.drawable.ic_dot_green else R.drawable.ic_dot_red)

            // ✅ الضغط على الجذر → فتح التطبيق
            setOnClickPendingIntent(R.id.widget_detailed_root,
                WidgetActionReceiver.buildOpenAppIntent(context, 30))

            // ✅ زر فتح التطبيق
            setOnClickPendingIntent(R.id.btn_det_open,
                WidgetActionReceiver.buildOpenAppIntent(context, 31))

            // ✅ زر التحديث → يجلب البيانات في الخلفية
            setOnClickPendingIntent(R.id.btn_det_refresh,
                WidgetActionReceiver.buildRefreshIntent(context, 32))

            // ✅ زر إعادة التشغيل → يرسل أمر للمودم مباشرة
            setOnClickPendingIntent(R.id.btn_det_reboot,
                WidgetActionReceiver.buildRebootIntent(context, 33))
        }
    }
}
