package com.sam4g.app_settings

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.RemoteViews
import java.net.HttpURLConnection
import java.net.URL

/**
 * مستقبل بث مركزي يتولى جميع إجراءات أزرار الويدجت والإشعار الدائم.
 *
 * الإجراءات المدعومة:
 * - ACTION_WIDGET_REFRESH  → يجلب بيانات المودم في الخلفية ويحدّث الويدجت والإشعار
 * - ACTION_WIDGET_REBOOT   → يرسل أمر إعادة تشغيل للمودم مباشرة
 * - ACTION_OPEN_BILL       → يفتح التطبيق مباشرة على شاشة الرصيد
 */
class WidgetActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_WIDGET_REFRESH = "com.sam4g.app_settings.WIDGET_REFRESH"
        const val ACTION_WIDGET_REBOOT  = "com.sam4g.app_settings.WIDGET_REBOOT"
        const val ACTION_OPEN_BILL      = "com.sam4g.app_settings.OPEN_BILL"

        const val EXTRA_OPEN_SCREEN     = "open_screen"
        const val EXTRA_OPEN_ACTION     = "action"
        const val SCREEN_BILL           = "bill"
        const val ACTION_CONFIRM_REBOOT = "confirm_reboot"

        const val PREFS_NAME            = NotificationHelper.PREFS_NAME
        const val FLUTTER_PREFIX        = "flutter."
        const val SESSION_ID_KEY        = "${FLUTTER_PREFIX}modem_session_id"
        const val MODEM_BASE_URL        = "http://mobile.router"

        /**
         * إنشاء PendingIntent لزر التحديث
         */
        fun buildRefreshIntent(context: Context, requestCode: Int = 100): PendingIntent {
            val intent = Intent(context, WidgetActionReceiver::class.java).apply {
                action = ACTION_WIDGET_REFRESH
            }
            return PendingIntent.getBroadcast(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        /**
         * إنشاء PendingIntent لزر إعادة التشغيل يفتح مربع التأكيد الشفاف مباشرة دون فتح التطبيق
         */
        fun buildRebootIntent(context: Context, requestCode: Int = 101): PendingIntent {
            val intent = Intent(context, RebootConfirmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        /**
         * إنشاء PendingIntent لفتح صفحة الرصيد
         */
        fun buildOpenBillIntent(context: Context, requestCode: Int = 102): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = ACTION_OPEN_BILL
                putExtra(EXTRA_OPEN_SCREEN, SCREEN_BILL)
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        /**
         * إنشاء PendingIntent لفتح التطبيق (الشاشة الرئيسية)
         */
        fun buildOpenAppIntent(context: Context, requestCode: Int = 103): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_WIDGET_REFRESH -> handleRefresh(context)
            ACTION_WIDGET_REBOOT  -> handleReboot(context)
        }
    }

    /**
     * يحدّث الويدجت والإشعار بالاتصال الفعلي بالمودم.
     */
    private fun handleRefresh(context: Context) {
        Log.d("WidgetAction", "🔄 Refresh action triggered")

        // 1. تحديث فوري سريع بالبيانات الحالية
        refreshAllWidgets(context)
        try {
            NotificationHelper.refreshNotification(context)
        } catch (e: Exception) {
            Log.e("WidgetAction", "Failed to refresh notification: ${e.message}")
        }

        // 2. فحص الاتصال الحقيقي وتحديث البيانات في خيط خلفي
        Thread {
            try {
                val timestamp = System.currentTimeMillis()
                val url = URL("$MODEM_BASE_URL/api.cgi?path=router&method=get_sys_time&timeout=3&_=$timestamp")
                val conn = url.openConnection() as HttpURLConnection
                conn.connectTimeout = 3000
                conn.readTimeout = 3000
                val code = conn.responseCode
                conn.disconnect()

                val isConnected = (code in 200..299)
                val timeFormat = java.text.SimpleDateFormat("hh:mm a", java.util.Locale("ar"))
                val updatedTime = timeFormat.format(java.util.Date())

                val notifPrefs = context.getSharedPreferences(NotificationHelper.PREFS_NAME, Context.MODE_PRIVATE)
                notifPrefs.edit()
                    .putBoolean("${NotificationHelper.FLUTTER_PREFIX}notif_is_connected", isConnected)
                    .putString("${NotificationHelper.FLUTTER_PREFIX}notif_last_updated", updatedTime)
                    .apply()

                val homePrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                homePrefs.edit()
                    .putBoolean("${FLUTTER_PREFIX}is_connected", isConnected)
                    .putString("${FLUTTER_PREFIX}last_updated_time", updatedTime)
                    .apply()

                Handler(Looper.getMainLooper()).post {
                    refreshAllWidgets(context)
                    NotificationHelper.refreshNotification(context)
                }
            } catch (e: Exception) {
                Log.w("WidgetAction", "Modem unreachable: ${e.message}")
                val notifPrefs = context.getSharedPreferences(NotificationHelper.PREFS_NAME, Context.MODE_PRIVATE)
                notifPrefs.edit()
                    .putBoolean("${NotificationHelper.FLUTTER_PREFIX}notif_is_connected", false)
                    .apply()

                val homePrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                homePrefs.edit()
                    .putBoolean("${FLUTTER_PREFIX}is_connected", false)
                    .apply()

                Handler(Looper.getMainLooper()).post {
                    refreshAllWidgets(context)
                    NotificationHelper.refreshNotification(context)
                }
            }
        }.start()
    }

    /**
     * يفتح مربع التأكيد الشفاف مباشرة دون فتح التطبيق.
     */
    private fun handleReboot(context: Context) {
        Log.d("WidgetAction", "⚡ Reboot action triggered -> Launching RebootConfirmActivity")
        val openIntent = Intent(context, RebootConfirmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        context.startActivity(openIntent)
    }

    /**
     * يعرض مؤشر "جارٍ التحديث..." لثانية واحدة ثم يعود للبيانات الحقيقية.
     */
    private fun showRefreshingIndicator(context: Context) {
        val manager = AppWidgetManager.getInstance(context)

        // تحديث ويدجت المصغر
        val smallIds = manager.getAppWidgetIds(
            ComponentName(context, WidgetSmallProvider::class.java)
        )
        if (smallIds.isNotEmpty()) {
            val views = RemoteViews(context.packageName, R.layout.widget_small)
            views.setTextViewText(R.id.tv_status_text, "يتم التحديث...")
            manager.updateAppWidget(smallIds, views)
        }

        // بعد ثانيتين: استعادة البيانات الحقيقية
        Handler(Looper.getMainLooper()).postDelayed({
            refreshAllWidgets(context)
        }, 2000)
    }

    /**
     * يطلب من كل Provider تحديث نفسه من SharedPreferences.
     */
    private fun refreshAllWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)

        val smallIds = manager.getAppWidgetIds(ComponentName(context, WidgetSmallProvider::class.java))
        if (smallIds.isNotEmpty()) {
            val i = Intent(context, WidgetSmallProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, smallIds)
            }
            context.sendBroadcast(i)
        }

        val bannerIds = manager.getAppWidgetIds(ComponentName(context, WidgetBannerProvider::class.java))
        if (bannerIds.isNotEmpty()) {
            val i = Intent(context, WidgetBannerProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, bannerIds)
            }
            context.sendBroadcast(i)
        }

        val detailedIds = manager.getAppWidgetIds(ComponentName(context, WidgetDetailedProvider::class.java))
        if (detailedIds.isNotEmpty()) {
            val i = Intent(context, WidgetDetailedProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, detailedIds)
            }
            context.sendBroadcast(i)
        }
    }
}
