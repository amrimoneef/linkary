package com.sam4g.app_settings

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

/**
 * مساعد مركزي لإدارة الإشعار الدائم.
 *
 * يُعاد استخدامه من:
 * - MainActivity (عند إنشاء الإشعار أو تحديثه)
 * - BootReceiver (عند إعادة تشغيل الجهاز)
 * - WidgetActionReceiver (عند الضغط على زر التحديث)
 */
object NotificationHelper {

    const val CHANNEL_ID    = "quick_tools_persistent_channel"
    const val CHANNEL_NAME  = "مراقبة المودم المستمرة"
    const val CHANNEL_DESC  = "عرض حي ودائم لحالة الرصيد والبطارية والاتصال"
    const val NOTIF_ID      = 8888

    // مفاتيح SharedPreferences لحفظ آخر حالة للإشعار
    const val PREFS_NAME               = "FlutterSharedPreferences"
    const val FLUTTER_PREFIX           = "flutter."
    const val NOTIF_ENABLED_KEY        = "${FLUTTER_PREFIX}quick_notification_enabled_key"
    const val NOTIF_IS_CONNECTED_KEY   = "${FLUTTER_PREFIX}notif_is_connected"
    const val NOTIF_BALANCE_KEY        = "${FLUTTER_PREFIX}notif_balance_text"
    const val NOTIF_DAYS_KEY           = "${FLUTTER_PREFIX}notif_days_remaining"
    const val NOTIF_BATTERY_KEY        = "${FLUTTER_PREFIX}notif_battery_level"
    const val NOTIF_IS_CHARGING_KEY    = "${FLUTTER_PREFIX}notif_is_charging"
    const val NOTIF_SIGNAL_KEY         = "${FLUTTER_PREFIX}notif_signal_bars"
    const val NOTIF_DEVICES_KEY        = "${FLUTTER_PREFIX}notif_devices_count"
    const val NOTIF_UPDATED_KEY        = "${FLUTTER_PREFIX}notif_last_updated"
    const val NOTIF_QUOTA_KEY          = "${FLUTTER_PREFIX}notif_quota_progress"
    const val NOTIF_TOTAL_PLAN_KEY     = "${FLUTTER_PREFIX}notif_total_plan"

    /**
     * إنشاء قناة الإشعارات (مطلوب على Android O+)
     */
    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(NotificationManager::class.java) ?: return
            if (manager.getNotificationChannel(CHANNEL_ID) != null) return
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_LOW).apply {
                description = CHANNEL_DESC
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }
    }

    /**
     * حفظ بيانات الإشعار الحالية في SharedPreferences
     * حتى يمكن إعادة بنائه بعد إعادة تشغيل الجهاز.
     */
    fun saveNotifState(
        context: Context,
        isConnected: Boolean,
        balanceText: String,
        daysRemaining: String,
        batteryLevel: Int,
        isCharging: Boolean,
        signalBars: Int,
        devicesCount: Int,
        lastUpdated: String,
        quotaProgress: Int,
        totalPlan: String
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(NOTIF_IS_CONNECTED_KEY, isConnected)
            .putString(NOTIF_BALANCE_KEY, balanceText)
            .putString(NOTIF_DAYS_KEY, daysRemaining)
            .putInt(NOTIF_BATTERY_KEY, batteryLevel)
            .putBoolean(NOTIF_IS_CHARGING_KEY, isCharging)
            .putInt(NOTIF_SIGNAL_KEY, signalBars)
            .putInt(NOTIF_DEVICES_KEY, devicesCount)
            .putString(NOTIF_UPDATED_KEY, lastUpdated)
            .putInt(NOTIF_QUOTA_KEY, quotaProgress)
            .putString(NOTIF_TOTAL_PLAN_KEY, totalPlan)
            .apply()
    }

    /**
     * إعادة بناء الإشعار من البيانات المحفوظة في SharedPreferences.
     * يُستخدم عند إعادة تشغيل الجهاز أو الضغط على زر التحديث.
     */
    fun refreshNotification(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        val isEnabled = prefs.getBoolean(NOTIF_ENABLED_KEY, false)
        if (!isEnabled) return

        val isConnected  = prefs.getBoolean(NOTIF_IS_CONNECTED_KEY, false)
        val balanceText  = prefs.getString(NOTIF_BALANCE_KEY, "-- GB") ?: "-- GB"
        val daysRemain   = prefs.getString(NOTIF_DAYS_KEY, "-- يوم") ?: "-- يوم"
        val batteryLevel = prefs.getInt(NOTIF_BATTERY_KEY, 0)
        val isCharging   = prefs.getBoolean(NOTIF_IS_CHARGING_KEY, false)
        val signalBars   = prefs.getInt(NOTIF_SIGNAL_KEY, 0)
        val devicesCount = prefs.getInt(NOTIF_DEVICES_KEY, 0)
        val lastUpdated  = prefs.getString(NOTIF_UPDATED_KEY, "--:--") ?: "--:--"
        val quotaProgress= prefs.getInt(NOTIF_QUOTA_KEY, 50)
        val totalPlan    = prefs.getString(NOTIF_TOTAL_PLAN_KEY, "باقة نشطة") ?: "باقة نشطة"

        showNotification(
            context       = context,
            isConnected   = isConnected,
            balanceText   = balanceText,
            daysRemaining = daysRemain,
            batteryLevel  = batteryLevel,
            isCharging    = isCharging,
            signalBars    = signalBars,
            devicesCount  = devicesCount,
            lastUpdated   = lastUpdated,
            quotaProgress = quotaProgress,
            totalPlan     = totalPlan
        )
    }

    /**
     * بناء الإشعار وعرضه.
     */
    fun showNotification(
        context: Context,
        isConnected: Boolean,
        balanceText: String,
        daysRemaining: String,
        batteryLevel: Int,
        isCharging: Boolean,
        signalBars: Int,
        devicesCount: Int,
        lastUpdated: String,
        quotaProgress: Int,
        totalPlan: String
    ) {
        createChannel(context)

        val signalQuality = when {
            signalBars >= 4 -> "ممتازة جداً"
            signalBars >= 2 -> "جيدة"
            else            -> "ضعيفة"
        }

        // ── العرض الموسّع ──────────────────────────────────────
        val expandedView = RemoteViews(context.packageName, R.layout.notification_expanded).apply {
            setTextViewText(R.id.tv_notif_title,       "مودم SAM4G")
            setViewVisibility(R.id.tv_notif_status,    View.GONE)
            setTextViewText(R.id.tv_notif_status_badge,if (isConnected) "متصل" else "غير متصل")
            setTextColor(R.id.tv_notif_status_badge,
                android.graphics.Color.parseColor(if (isConnected) "#34D399" else "#EF4444"))
            setImageViewResource(R.id.iv_notif_status_dot,
                if (isConnected) R.drawable.ic_dot_green else R.drawable.ic_dot_red)
            setTextViewText(R.id.tv_notif_updated,     "آخر تحديث: $lastUpdated")
            setTextViewText(R.id.tv_notif_days,        daysRemaining)
            setTextViewText(R.id.tv_notif_balance,     balanceText)
            setTextViewText(R.id.tv_notif_total_plan,  totalPlan)
            setProgressBar(R.id.pb_notif_quota, 100, quotaProgress, false)
            setTextViewText(R.id.tv_notif_battery,     "$batteryLevel%")
            setTextViewText(R.id.tv_notif_charging,    if (isCharging) "شحن سريع" else "على البطارية")
            setTextViewText(R.id.tv_notif_signal,      "$signalBars/5")
            setTextViewText(R.id.tv_notif_signal_quality, signalQuality)
            setTextViewText(R.id.tv_notif_devices,     "$devicesCount أجهزة")

            // ✅ أزرار وظيفية حقيقية
            setOnClickPendingIntent(R.id.notif_expanded_root,
                WidgetActionReceiver.buildOpenAppIntent(context, 200))
            setOnClickPendingIntent(R.id.btn_notif_refresh,
                WidgetActionReceiver.buildRefreshIntent(context, 201))
            setOnClickPendingIntent(R.id.btn_notif_bill,
                WidgetActionReceiver.buildOpenBillIntent(context, 202))
            setOnClickPendingIntent(R.id.btn_notif_reboot,
                WidgetActionReceiver.buildRebootIntent(context, 203))
        }

        // ── العرض المصغّر ───────────────────────────────────────
        val collapsedView = RemoteViews(context.packageName, R.layout.notification_collapsed).apply {
            setImageViewResource(R.id.iv_notif_col_dot,
                if (isConnected) R.drawable.ic_dot_green else R.drawable.ic_dot_red)
            setTextViewText(R.id.tv_notif_col_balance,  balanceText)
            setTextViewText(R.id.tv_notif_col_days,     daysRemaining)
            setTextViewText(R.id.tv_notif_col_subtitle,
                "🔋 $batteryLevel%  •  📶 $signalBars/5  •  👥 $devicesCount")
            setOnClickPendingIntent(R.id.notif_collapsed_root,
                WidgetActionReceiver.buildOpenAppIntent(context, 204))
        }

        // ── بناء الإشعار ────────────────────────────────────────
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setCustomContentView(collapsedView)
            .setCustomBigContentView(expandedView)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())  // ✅ مضاف
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setColorized(true)
            .setColor(0xFF0F172A.toInt())
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIF_ID, notification)
        Log.d("NotificationHelper", "✅ Notification shown/updated")
    }

    /**
     * إلغاء الإشعار الدائم.
     */
    fun cancelNotification(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIF_ID)
        Log.d("NotificationHelper", "🔕 Notification cancelled")
    }

    /**
     * التحقق إذا كان الإشعار مفعلاً.
     */
    fun isNotificationEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(NOTIF_ENABLED_KEY, false)
    }
}
