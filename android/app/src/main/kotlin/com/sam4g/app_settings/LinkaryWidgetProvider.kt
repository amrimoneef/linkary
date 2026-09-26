package com.sam4g.app_settings

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar
import java.util.Locale

object WidgetTimeHelper {
    /**
     * تحية ذكية حسب الوقت باللغة العربية:
     * - الصباح (من 5:00 ص إلى 11:59 ص): "صباح الخير ☀️"
     * - الظهيرة (من 12:00 م إلى 4:59 م): "طاب يومك 🌤️"
     * - المساء والليل (من 5:00 م إلى 4:59 ص): "مساء الخير 🌙"
     */
    fun getTimeBasedGreeting(): String {
        val calendar = Calendar.getInstance()
        val hour = calendar.get(Calendar.HOUR_OF_DAY)
        return when (hour) {
            in 5..11 -> "صباح الخير"
            in 12..16 -> "طاب يومك"
            else -> "مساء الخير"
        }
    }

    fun formatArabicTime(): String {
        val calendar = Calendar.getInstance()
        val hour24 = calendar.get(Calendar.HOUR_OF_DAY)
        val hour12 = if (hour24 % 12 == 0) 12 else hour24 % 12
        val minute = String.format(Locale.US, "%02d", calendar.get(Calendar.MINUTE))
        val period = if (hour24 >= 12) "م" else "ص"
        return "$hour12:$minute $period"
    }
}

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

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        // عند إضافة أول ويدجت للشاشة الرئيسية -> بدء جدولة التحديث الدوري كل 5 دقائق
        WidgetActionReceiver.schedulePeriodicUpdate(context, delayMs = 3000L)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // عند إزالة جميع الويدجت -> إيقاف المنبه الدوري لتوفير البطارية 100%
        val manager = AppWidgetManager.getInstance(context)
        val hasSmall = manager.getAppWidgetIds(android.content.ComponentName(context, WidgetSmallProvider::class.java)).isNotEmpty()
        val hasBanner = manager.getAppWidgetIds(android.content.ComponentName(context, WidgetBannerProvider::class.java)).isNotEmpty()
        val hasDetailed = manager.getAppWidgetIds(android.content.ComponentName(context, WidgetDetailedProvider::class.java)).isNotEmpty()
        if (!hasSmall && !hasBanner && !hasDetailed) {
            WidgetActionReceiver.cancelPeriodicUpdate(context)
        }
    }

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

        // التأكد من استمرار جدولة التحديث كل 5 دقائق
        WidgetActionReceiver.schedulePeriodicUpdate(context)
    }
}

// ══════════════════════════════════════════════════════════════════
// الويدجت المصغر (2×2) — مربع الرصيد والتحية الذكية
// ══════════════════════════════════════════════════════════════════
class WidgetSmallProvider : LinkaryBaseWidgetProvider() {

    override val layoutRes = R.layout.widget_small

    override fun applyData(context: Context, views: RemoteViews, widgetData: SharedPreferences) {
        val isConnected = widgetData.getBoolean("is_connected", false)
        val greeting = WidgetTimeHelper.getTimeBasedGreeting()

        views.apply {
            // شريط الحالة العلوي
            setTextViewText(R.id.tv_title, "SAM4G")
            setTextViewText(R.id.tv_status_text, if (isConnected) "متصل" else "غير متصل")
            setTextColor(R.id.tv_status_text, Color.parseColor(if (isConnected) "#34D399" else "#EF4444"))
            setImageViewResource(R.id.iv_status_indicator,
                if (isConnected) R.drawable.ic_dot_green else R.drawable.ic_dot_red)

            if (isConnected) {
                // حالة الاتصال بمودم SAM4G -> عرض البيانات الفعلية
                setViewVisibility(R.id.layout_small_connected, View.VISIBLE)
                setViewVisibility(R.id.layout_small_disconnected, View.GONE)
                setViewVisibility(R.id.layout_bottom_pill, View.VISIBLE)

                val balanceVal    = widgetData.getString("balance_val", "--")  ?: "--"
                val balanceUnit   = widgetData.getString("balance_unit", "GB") ?: "GB"
                val daysRemaining = widgetData.getString("days_remaining", "-- يوم متبقي") ?: "-- يوم متبقي"
                val batteryLevel  = widgetData.getInt("battery_level", 0)
                val devicesCount  = widgetData.getInt("devices_count", 0)
                val totalText     = widgetData.getString("total_text", "GB 0.0")  ?: "GB 0.0"
                val consumedText  = widgetData.getString("consumed_text", "GB 0.0") ?: "GB 0.0"
                val quotaProgress = widgetData.getInt("quota_progress_int", 0)

                setTextViewText(R.id.tv_balance_unit, balanceUnit)
                setTextViewText(R.id.tv_balance_value, balanceVal)
                setTextViewText(R.id.tv_days_remaining, daysRemaining)
                setProgressBar(R.id.pb_quota, 100, quotaProgress, false)
                setTextViewText(R.id.tv_total_plan, "الإجمالي: $totalText")
                setTextViewText(R.id.tv_consumed, "المستهلك: $consumedText")
                setTextViewText(R.id.tv_devices, "$devicesCount أجهزة")
                setTextViewText(R.id.tv_battery, "$batteryLevel%")
            } else {
                // حالة عدم الاتصال بمودم SAM4G -> إخفاء البيانات وعرض التحية والتوجيه
                setViewVisibility(R.id.layout_small_connected, View.GONE)
                setViewVisibility(R.id.layout_small_disconnected, View.VISIBLE)
                setViewVisibility(R.id.layout_bottom_pill, View.GONE)

                setTextViewText(R.id.tv_small_greeting, greeting)
                setTextViewText(R.id.tv_small_prompt, "يرجى الاتصال بمودم SAM4G")
            }

            // ✅ الضغط على الويدجت يفتح التطبيق
            setOnClickPendingIntent(R.id.widget_small_root,
                WidgetActionReceiver.buildOpenAppIntent(context, 10))
        }
    }
}

// ══════════════════════════════════════════════════════════════════
// الويدجت الشريطي (4×1) — بانر أفقي مع التحية الذكية
// ══════════════════════════════════════════════════════════════════
class WidgetBannerProvider : LinkaryBaseWidgetProvider() {

    override val layoutRes = R.layout.widget_banner

    override fun applyData(context: Context, views: RemoteViews, widgetData: SharedPreferences) {
        val isConnected = widgetData.getBoolean("is_connected", false)
        val greeting = WidgetTimeHelper.getTimeBasedGreeting()

        views.apply {
            setTextViewText(R.id.tv_banner_title, "SAM4G")
            setImageViewResource(R.id.iv_banner_status_dot,
                if (isConnected) R.drawable.ic_dot_green else R.drawable.ic_dot_red)

            if (isConnected) {
                // حالة الاتصال بمودم SAM4G -> عرض الإحصائيات والرصيد
                setViewVisibility(R.id.layout_banner_metrics, View.VISIBLE)
                setViewVisibility(R.id.layout_banner_connected, View.VISIBLE)
                setViewVisibility(R.id.layout_banner_disconnected, View.GONE)

                val balanceVal    = widgetData.getString("balance_val", "--")  ?: "--"
                val balanceUnit   = widgetData.getString("balance_unit", "GB") ?: "GB"
                val daysRemaining = widgetData.getString("days_remaining", "-- يوم متبقي") ?: "-- يوم متبقي"
                val batteryLevel  = widgetData.getInt("battery_level", 0)
                val signalBars    = widgetData.getInt("signal_bars", 0)
                val devicesCount  = widgetData.getInt("devices_count", 0)
                val quotaProgress = widgetData.getInt("quota_progress_int", 0)

                setTextViewText(R.id.tv_banner_battery, "$batteryLevel%")
                setTextViewText(R.id.tv_banner_signal, "4G $signalBars/5")
                setTextViewText(R.id.tv_banner_devices, "$devicesCount أجهزة")
                setTextViewText(R.id.tv_banner_balance_unit, balanceUnit)
                setTextViewText(R.id.tv_banner_balance_val, balanceVal)
                setTextViewText(R.id.tv_banner_days, daysRemaining)
                setProgressBar(R.id.pb_banner_quota, 100, quotaProgress, false)
            } else {
                // حالة عدم الاتصال -> إخفاء الإحصائيات وعرض التحية والتوجيه
                setViewVisibility(R.id.layout_banner_metrics, View.GONE)
                setViewVisibility(R.id.layout_banner_connected, View.GONE)
                setViewVisibility(R.id.layout_banner_disconnected, View.VISIBLE)

                setTextViewText(R.id.tv_banner_greeting, greeting)
                setTextViewText(R.id.tv_banner_prompt, "يرجى الاتصال بمودم SAM4G")
            }

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
        val isConnected = widgetData.getBoolean("is_connected", false)
        val greeting = WidgetTimeHelper.getTimeBasedGreeting()
        val lastUpdated = widgetData.getString("last_updated_time", "--:--") ?: "--:--"

        views.apply {
            setTextViewText(R.id.tv_det_title, "مودم SAM4G")
            setTextViewText(R.id.tv_det_status, if (isConnected) "متصل" else "غير متصل")
            setTextColor(R.id.tv_det_status, Color.parseColor(if (isConnected) "#34D399" else "#EF4444"))
            setImageViewResource(R.id.iv_det_status_dot,
                if (isConnected) R.drawable.ic_dot_green else R.drawable.ic_dot_red)
            setTextViewText(R.id.tv_det_updated, lastUpdated)

            if (isConnected) {
                // حالة الاتصال -> عرض تفاصيل الرصيد والشبكة والأجهزة
                setViewVisibility(R.id.layout_det_connected, View.VISIBLE)
                setViewVisibility(R.id.layout_det_disconnected, View.GONE)

                val balanceText   = widgetData.getString("balance_text", "-- GB") ?: "-- GB"
                val daysRemaining = widgetData.getString("days_remaining", "-- يوم متبقي") ?: "-- يوم متبقي"
                val batteryLevel  = widgetData.getInt("battery_level", 0)
                val signalText    = widgetData.getString("signal_text", "4G LTE") ?: "4G LTE"
                val devicesCount  = widgetData.getInt("devices_count", 0)

                setTextViewText(R.id.tv_det_balance, balanceText)
                setTextViewText(R.id.tv_det_days, daysRemaining)
                setTextViewText(R.id.tv_det_battery, "البطارية: $batteryLevel%")
                setTextViewText(R.id.tv_det_devices, "الأجهزة: $devicesCount")
                setTextViewText(R.id.tv_det_signal, "الإشارة: $signalText")
            } else {
                // حالة عدم الاتصال -> إخفاء الإحصائيات وعرض التحية وطلب الاتصال
                setViewVisibility(R.id.layout_det_connected, View.GONE)
                setViewVisibility(R.id.layout_det_disconnected, View.VISIBLE)

                setTextViewText(R.id.tv_det_greeting, greeting)
                setTextViewText(R.id.tv_det_prompt, "يرجى الاتصال بمودم SAM4G")
            }

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
