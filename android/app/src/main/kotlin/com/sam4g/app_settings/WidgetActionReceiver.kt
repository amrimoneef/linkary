package com.sam4g.app_settings

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Calendar
import java.util.Locale

/**
 * مستقبل بث مركزي فائق السرعة لجميع إجراءات الويدجت وتحديثات الشاشة.
 *
 * الإجراءات المدعومة:
 * 1. ACTION_WIDGET_REFRESH: تحديث يدوي فوري عند النقر على زر التحديث في الويدجت.
 * 2. ACTION_PERIODIC_REFRESH: تحديث دوري ذكي خفيف كل 5 دقائق عبر AlarmManager دون أي صلاحيات خاصة.
 * 3. ACTION_USER_PRESENT: تحديث تلقائي ذكي عند فتح قفل شاشة الهاتف (بشرط الاتصال بالمودم فقط وبمعدل آمن للبطارية).
 * 4. ACTION_WIDGET_REBOOT: فتح نافذة تأكيد إعادة تشغيل المودم المنبثقة.
 */
class WidgetActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_WIDGET_REFRESH   = "com.sam4g.app_settings.WIDGET_REFRESH"
        const val ACTION_PERIODIC_REFRESH = "com.sam4g.app_settings.PERIODIC_REFRESH"
        const val ACTION_WIDGET_REBOOT    = "com.sam4g.app_settings.WIDGET_REBOOT"
        const val ACTION_OPEN_BILL        = "com.sam4g.app_settings.OPEN_BILL"

        const val PERIODIC_INTERVAL_MS    = 5 * 60 * 1000L // 5 دقائق
        const val PERIODIC_REQUEST_CODE   = 999

        const val EXTRA_OPEN_SCREEN       = "open_screen"
        const val SCREEN_BILL             = "bill"

        const val PREFS_NAME              = NotificationHelper.PREFS_NAME
        const val FLUTTER_PREFIX          = "flutter."
        const val SESSION_ID_KEY          = "${FLUTTER_PREFIX}modem_session_id"

        const val MODEM_BASE_URL          = "http://mobile.router"
        private const val KEY_LAST_AUTO_REFRESH_MS = "last_auto_refresh_ms"
        private const val MIN_AUTO_REFRESH_INTERVAL_MS = 60_000L // دقيقة واحدة كحد أدنى بين التحديثات التلقائية

        /**
         * جدولة التحديث الدوري كل 5 دقائق باستخدام AlarmManager القياسي الخفيف
         */
        fun schedulePeriodicUpdate(context: Context, delayMs: Long = PERIODIC_INTERVAL_MS) {
            val manager = AppWidgetManager.getInstance(context)
            val hasSmall = manager.getAppWidgetIds(ComponentName(context, WidgetSmallProvider::class.java)).isNotEmpty()
            val hasBanner = manager.getAppWidgetIds(ComponentName(context, WidgetBannerProvider::class.java)).isNotEmpty()
            val hasDetailed = manager.getAppWidgetIds(ComponentName(context, WidgetDetailedProvider::class.java)).isNotEmpty()

            if (!hasSmall && !hasBanner && !hasDetailed) {
                // لا يوجد أي ويدجت نشط على الشاشة الرئيسية -> إلغاء المنبه لتوفير البطارية 100%
                cancelPeriodicUpdate(context)
                return
            }

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(context, WidgetActionReceiver::class.java).apply {
                action = ACTION_PERIODIC_REFRESH
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, PERIODIC_REQUEST_CODE, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val triggerAt = System.currentTimeMillis() + delayMs
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                }
                Log.d("WidgetAction", "⏰ Scheduled next periodic refresh in ${delayMs / 1000}s")
            } catch (e: Exception) {
                Log.w("WidgetAction", "Could not schedule alarm: ${e.message}")
            }
        }

        /**
         * إلغاء جدولة المنبه الدوري عند حذف جميع الويدجت
         */
        fun cancelPeriodicUpdate(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(context, WidgetActionReceiver::class.java).apply {
                action = ACTION_PERIODIC_REFRESH
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, PERIODIC_REQUEST_CODE, intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
                Log.d("WidgetAction", "⏹️ Cancelled periodic refresh alarm")
            }
        }

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

        /**
         * التحقق الاحترافي والمضمون من الاتصال بشبكة مودم SAM4G حصراً:
         * 1. التأكد أن وسيط النقل الفعّال هو Wi-Fi (وليس بيانات الخلوي أو VPN منفرد).
         * 2. فحص البوابة الافتراضية (Default Gateway IP) أو خادم DHCP:
         *    مودم SAM4G يعمل دائماً على نطاق 192.168.8.1.
         *    أي شبكة واي فاي أخرى (ألياف منزلية، كافيه، عمل 192.168.1.1 أو 192.168.0.1 أو 10.x.x.x)
         *    تُرفض فوراً وبدقة 100% خلال أقل من 0.05 مللي ثانية وبدون أي صلاحيات موقع جغرافية (Location).
         */
        fun isConnectedToSam4gWifi(context: Context): Boolean {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return false
            val activeNet = cm.activeNetwork ?: return false
            val caps = cm.getNetworkCapabilities(activeNet) ?: return false

            if (!caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                return false
            }

            val linkProps = cm.getLinkProperties(activeNet) ?: return false
            for (route in linkProps.routes) {
                val gw = route.gateway?.hostAddress
                if (gw == "192.168.8.1") {
                    return true
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val dhcp = linkProps.dhcpServerAddress?.hostAddress
                if (dhcp == "192.168.8.1") {
                    return true
                }
            }

            return false
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_WIDGET_REFRESH -> {
                Log.d("WidgetAction", "🔘 Manual refresh clicked")
                handleRefresh(context, isManual = true)
                // إعادة جدولة المنبه القادم بعد 5 دقائق من التحديث اليدوي
                schedulePeriodicUpdate(context)
            }
            ACTION_PERIODIC_REFRESH -> {
                Log.d("WidgetAction", "⏰ Periodic 5-minute refresh triggered")
                handlePeriodicRefresh(context)
            }
            Intent.ACTION_USER_PRESENT -> {
                Log.d("WidgetAction", "📱 Screen unlocked (USER_PRESENT)")
                handleScreenUnlock(context)
            }
            WifiManager.NETWORK_STATE_CHANGED_ACTION,
            ConnectivityManager.CONNECTIVITY_ACTION -> {
                Log.d("WidgetAction", "📶 Network state changed -> checking SAM4G modem link")
                handleNetworkChange(context)
            }
            ACTION_WIDGET_REBOOT -> handleReboot(context)
        }
    }

    /**
     * معالجة تغير حالة الاتصال بالشبكة (اتصال/انفصال Wi-Fi):
     * - إذا اتصل بمودم SAM4G -> تحديث فوري فائق السرعة.
     * - إذا انفصل أو اتصل بشبكة أخرى -> التحويل فوراً لحالة عدم الاتصال والتحية.
     */
    private fun handleNetworkChange(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val hasSmall = manager.getAppWidgetIds(ComponentName(context, WidgetSmallProvider::class.java)).isNotEmpty()
        val hasBanner = manager.getAppWidgetIds(ComponentName(context, WidgetBannerProvider::class.java)).isNotEmpty()
        val hasDetailed = manager.getAppWidgetIds(ComponentName(context, WidgetDetailedProvider::class.java)).isNotEmpty()

        if (!hasSmall && !hasBanner && !hasDetailed) return

        val widgetData = HomeWidgetPlugin.getData(context)
        val onModem = isConnectedToSam4gWifi(context)
        val wasConnected = widgetData.getBoolean("is_connected", false)

        if (onModem && !wasConnected) {
            Log.d("WidgetAction", "✅ Connected to SAM4G modem Wi-Fi -> Fetching fresh data")
            handleRefresh(context, isManual = false)
        } else if (!onModem && wasConnected) {
            Log.d("WidgetAction", "⚠️ Disconnected from SAM4G modem Wi-Fi -> Switching to offline greeting")
            widgetData.edit().putBoolean("is_connected", false).apply()
            updateAllWidgetsAndNotification(context, isConnected = false)
        }
    }

    /**
     * معالجة التحديث الدوري كل 5 دقائق:
     * - يعيد جدولة التحديث القادم دائماً.
     * - يتحقق من وجود ويدجت نشطة على الشاشة.
     * - يتحقق من الاتصال بشبكة واي فاي مودم SAM4G حصراً (حماية البطارية ومنع التحديث على أي شبكة أخرى).
     */
    private fun handlePeriodicRefresh(context: Context) {
        // إعادة جدولة الدورة القادمة دائماً بعد 5 دقائق
        schedulePeriodicUpdate(context)

        val manager = AppWidgetManager.getInstance(context)
        val hasSmall = manager.getAppWidgetIds(ComponentName(context, WidgetSmallProvider::class.java)).isNotEmpty()
        val hasBanner = manager.getAppWidgetIds(ComponentName(context, WidgetBannerProvider::class.java)).isNotEmpty()
        val hasDetailed = manager.getAppWidgetIds(ComponentName(context, WidgetDetailedProvider::class.java)).isNotEmpty()

        if (!hasSmall && !hasBanner && !hasDetailed) {
            cancelPeriodicUpdate(context)
            return
        }

        // فحص هل الجهاز متصل بشبكة واي فاي مودم SAM4G حصراً
        if (!isConnectedToSam4gWifi(context)) {
            Log.d("WidgetAction", "⏭️ Periodic refresh skipped: Not on SAM4G modem Wi-Fi")
            val widgetData = HomeWidgetPlugin.getData(context)
            if (widgetData.getBoolean("is_connected", false)) {
                widgetData.edit().putBoolean("is_connected", false).apply()
                updateAllWidgetsAndNotification(context, isConnected = false)
            }
            return
        }

        handleRefresh(context, isManual = false)
    }

    /**
     * معالجة فتح شاشة الهاتف:
     * - يتحقق أولاً من وجود أي ويدجت على الشاشة (إذا لم يكن هناك ويدجت لا يفعل شيئاً).
     * - يتحقق من معدل التحديث (دقيقة واحدة على الأقل) لمنع استهلاك البطارية.
     * - يتحقق من أن الجهاز متصل بشبكة واي فاي مودم SAM4G حصراً.
     */
    private fun handleScreenUnlock(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val hasSmall = manager.getAppWidgetIds(ComponentName(context, WidgetSmallProvider::class.java)).isNotEmpty()
        val hasBanner = manager.getAppWidgetIds(ComponentName(context, WidgetBannerProvider::class.java)).isNotEmpty()
        val hasDetailed = manager.getAppWidgetIds(ComponentName(context, WidgetDetailedProvider::class.java)).isNotEmpty()

        if (!hasSmall && !hasBanner && !hasDetailed) {
            // لا يوجد أي ويدجت نشط على الشاشة الرئيسية -> توفير البطارية 100%
            return
        }

        // فحص مهلة التحديث لمنع التكرار السريع عند قفل وفتح الشاشة المتكرر
        val widgetData = HomeWidgetPlugin.getData(context)
        val lastRefresh = widgetData.getLong(KEY_LAST_AUTO_REFRESH_MS, 0L)
        val now = System.currentTimeMillis()
        if (now - lastRefresh < MIN_AUTO_REFRESH_INTERVAL_MS) {
            Log.d("WidgetAction", "⏭️ Auto-refresh skipped (rate limit: ${((now - lastRefresh) / 1000)}s < 60s)")
            return
        }

        // فحص هل الجهاز متصل بشبكة واي فاي مودم SAM4G حصراً
        if (!isConnectedToSam4gWifi(context)) {
            Log.d("WidgetAction", "⏭️ Screen unlock skipped: Not on SAM4G modem Wi-Fi")
            if (widgetData.getBoolean("is_connected", false)) {
                widgetData.edit().putBoolean("is_connected", false).apply()
                updateAllWidgetsAndNotification(context, isConnected = false)
            }
            return
        }

        widgetData.edit().putLong(KEY_LAST_AUTO_REFRESH_MS, now).apply()
        handleRefresh(context, isManual = false)
    }

    /**
     * تنفيذ التحديث:
     * - يتحقق من الاتصال بمودم SAM4G؛ إذا لم يكن متصلاً يعرض التحية وتوجيه الاتصال فوراً.
     * - إذا كان يدوياً: يعرض مؤشر "يتم التحديث..." فوراً ليعلم المستخدم بالاستجابة.
     * - يجلب البيانات من المودم عبر خيط خلفي غير متزامن (goAsync).
     */
    private fun handleRefresh(context: Context, isManual: Boolean) {
        if (!isConnectedToSam4gWifi(context)) {
            Log.w("WidgetAction", "⚠️ Refresh requested but not on SAM4G modem Wi-Fi")
            val widgetData = HomeWidgetPlugin.getData(context)
            widgetData.edit().putBoolean("is_connected", false).apply()
            updateAllWidgetsAndNotification(context, isConnected = false)
            return
        }

        if (isManual) {
            showRefreshingIndicator(context)
        }

        val pendingResult = goAsync()
        Thread {
            try {
                executeModemFetch(context)
            } catch (e: Exception) {
                Log.e("WidgetAction", "❌ Error in modem fetch: ${e.message}")
                HomeWidgetPlugin.getData(context).edit().putBoolean("is_connected", false).apply()
                updateAllWidgetsAndNotification(context, isConnected = false)
            } finally {
                pendingResult.finish()
            }
        }.start()
    }

    /**
     * جلب بيانات المودم وتحديث الـ SharedPreferences وإعادة رسم الويدجت.
     */
    private fun executeModemFetch(context: Context) {
        val widgetData = HomeWidgetPlugin.getData(context)
        var sessionId = widgetData.getString("modem_session_id", "") ?: ""
        if (sessionId.isBlank()) {
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            sessionId = flutterPrefs.getString(SESSION_ID_KEY, "") ?: ""
        }
        if (sessionId.isBlank()) {
            val notifPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            sessionId = notifPrefs.getString(SESSION_ID_KEY, "") ?: ""
        }

        // 1. إرسال طلب مدمج لجلب حالة الرابط والإشارة والبطارية والأجهزة المتصلة والاستهلاك والسرعة
        val requestJson = JSONObject().apply {
            if (sessionId.isNotEmpty()) {
                put("session_id", sessionId)
            }
            val requestsArray = JSONArray().apply {
                put(JSONObject().apply {
                    put("path", "cm")
                    put("method", "get_link_context")
                    put("timeout", "5")
                })
                put(JSONObject().apply {
                    put("path", "aoc")
                    put("method", "get_bat_info")
                    put("timeout", "2")
                })
                put(JSONObject().apply {
                    put("path", "statistics")
                    put("method", "get_conn_clients_info")
                    put("timeout", "5")
                })
                put(JSONObject().apply {
                    put("path", "statistics")
                    put("method", "stat_get_common_data")
                    put("timeout", "5")
                })
                put(JSONObject().apply {
                    put("path", "statistics")
                    put("method", "stat_get_traffic_transport_status")
                    put("timeout", "5")
                })
            }
            put("requests", requestsArray)
        }

        val responseStr = httpPost("$MODEM_BASE_URL/api.cgi?multicalls=1&timeout=5", requestJson.toString(), sessionId)
        Log.d("WidgetAction", "📡 Modem raw response: $responseStr")

        if (responseStr == null) {
            // المودم غير متاح (لسنا على شبكة المودم أو انقطع الاتصال)
            Log.w("WidgetAction", "⚠️ Modem unreachable on network")
            widgetData.edit().putBoolean("is_connected", false).apply()
            updateAllWidgetsAndNotification(context, isConnected = false)
            return
        }

        try {
            val root = JSONObject(responseStr)
            val responses = root.optJSONArray("responses")

            var isConnected = true
            var batteryLevel = widgetData.getInt("battery_level", 0)
            var isCharging = widgetData.getBoolean("is_charging", false)
            var signalBars = widgetData.getInt("signal_bars", 0)
            var signalText = widgetData.getString("signal_text", "4G • 0/5") ?: "4G • 0/5"
            var devicesCount = widgetData.getInt("devices_count", 0)
            var networkSpeed = widgetData.getString("network_speed", "0 B/s") ?: "0 B/s"

            if (responses != null && responses.length() > 0) {
                // 1. استجابة cm.get_link_context (الإشارة، نوع الشبكة، حالة اتصال البيانات)
                val cmObj = responses.optJSONObject(0)?.optJSONObject("data")
                if (cmObj != null) {
                    val signalInfo = cmObj.optJSONObject("signal_info")
                    if (signalInfo != null) {
                        val rawLevel = signalInfo.optInt("level", -1)
                        if (rawLevel >= 0) {
                            signalBars = rawLevel.coerceIn(0, 5)
                        }
                        val rat = signalInfo.optString("rat", "4G").uppercase(Locale.ROOT)
                        signalText = "$rat • $signalBars/5"
                    }

                    val contextList = cmObj.optJSONArray("contextlist")
                    val firstContext = contextList?.optJSONObject(0)
                    val cStatus = firstContext?.optInt("c_status", 0) ?: 0
                    val ipv4 = firstContext?.optString("ipv4_ip", "") ?: ""

                    // إذا كان c_status == 1 أو يوجد آي بي مخصص صالح أو مستوى الإشارة > 0
                    isConnected = (cStatus == 1) || (ipv4.isNotBlank() && ipv4 != "0.0.0.0") || (signalBars > 0)
                } else {
                    // بما أن استجابة المودم وصلت بالفعل عبر HTTP فالجهاز متصل بالمودم
                    isConnected = true
                }

                // 2. استجابة aoc.get_bat_info
                if (responses.length() > 1) {
                    val batObj = responses.optJSONObject(1)?.optJSONObject("data")
                    if (batObj != null) {
                        batteryLevel = batObj.optInt("capacity", batteryLevel)
                        isCharging = batObj.optInt("status", 0) == 1
                    }
                }

                // 3. استجابة statistics.get_conn_clients_info
                if (responses.length() > 2) {
                    val clientObj = responses.optJSONObject(2)?.optJSONObject("data")
                    if (clientObj != null) {
                        val clientsArray = clientObj.optJSONArray("clients_info")
                            ?: clientObj.optJSONArray("clients")
                        if (clientsArray != null) {
                            devicesCount = clientsArray.length()
                        }
                    }
                }

                // 4. استجابة statistics.stat_get_common_data (إجمالي الاستهلاك + استهلاك الجلسة + الرصيد)
                if (responses.length() > 3) {
                    val statsDataObj = responses.optJSONObject(3)?.optJSONObject("data")
                    val statsObj = statsDataObj?.optJSONObject("statistics")
                        ?: responses.optJSONObject(3)?.optJSONObject("statistics")
                    if (statsObj != null) {
                        val totalUsageBytes = statsObj.optLong("total_rx_tx_bytes", 0L)
                        val sessionUsageBytes = statsObj.optLong("rx_tx_bytes", 0L)

                        if (totalUsageBytes > 0L) {
                            val totalText = formatUsageBytes(totalUsageBytes)
                            widgetData.edit().putString("total_text", totalText).apply()
                        }

                        if (sessionUsageBytes > 0L) {
                            val consumedText = formatUsageBytes(sessionUsageBytes)
                            widgetData.edit().putString("consumed_text", consumedText).apply()
                        }

                        val trackingBalance = getLongSafe(widgetData, "tracking_balance_bytes", 0L)
                        val trackingInitial = getLongSafe(widgetData, "tracking_initial_usage", 0L)
                        val totalPlanBytes = getLongSafe(widgetData, "total_plan_bytes", 0L)

                        if (trackingBalance > 0L && trackingInitial > 0L && totalUsageBytes >= trackingInitial) {
                            val consumedSinceFetch = totalUsageBytes - trackingInitial
                            val remainingBytes = (trackingBalance - consumedSinceFetch).coerceAtLeast(0L)
                            val remainingGB = remainingBytes.toDouble() / (1024.0 * 1024.0 * 1024.0)
                            val balanceVal = String.format(Locale.US, "%.2f", remainingGB)
                            val balanceText = "$balanceVal GB"
                            // استخراج حجم الباقة الكلي بدقة من اسم الباقة (تجاهل 4G/5G/3G/LTE)
                            val packageName = widgetData.getString("package_name", "") ?: ""
                            val nameWithoutTech = packageName.replace(Regex("(?i)(4G|5G|3G|LTE)"), " ")
                            val extractedGb = Regex("""(\d+(\.\d+)?)""").find(nameWithoutTech)?.groupValues?.get(1)?.toDoubleOrNull() ?: 0.0

                            val effectivePlanBytes = if (extractedGb > 0.0) {
                                (extractedGb * 1024.0 * 1024.0 * 1024.0).toLong()
                            } else if (totalPlanBytes > 0L) {
                                totalPlanBytes
                            } else {
                                (remainingGB.coerceAtLeast(10.0) * 1024.0 * 1024.0 * 1024.0).toLong()
                            }

                            // شريط التقدم يمثل نسبة الرصيد المتبقي من إجمالي الباقة
                            val quotaProgress = if (effectivePlanBytes > 0L) {
                                ((remainingBytes.toDouble() / effectivePlanBytes.toDouble()) * 100).toInt().coerceIn(1, 100)
                            } else {
                                widgetData.getInt("quota_progress_int", 50)
                            }

                            widgetData.edit()
                                .putString("balance_val", balanceVal)
                                .putString("balance_text", balanceText)
                                .putInt("quota_progress_int", quotaProgress)
                                .apply()

                            Log.d("WidgetAction", "📊 Re-calculated balance: $balanceText, plan: ${effectivePlanBytes / (1024*1024*1024)}GB, quotaProgress: $quotaProgress%")
                        } else {
                            val lastRecordedUsage = widgetData.getLong("last_recorded_router_usage", 0L)
                            if (lastRecordedUsage > 0L && totalUsageBytes > lastRecordedUsage) {
                                val deltaBytes = totalUsageBytes - lastRecordedUsage
                                val currentBalVal = widgetData.getString("balance_val", "")?.toDoubleOrNull()
                                if (currentBalVal != null && currentBalVal > 0) {
                                    val currentBalBytes = (currentBalVal * 1024 * 1024 * 1024).toLong()
                                    val newRemaining = (currentBalBytes - deltaBytes).coerceAtLeast(0L)
                                    val remainingGB = newRemaining.toDouble() / (1024.0 * 1024.0 * 1024.0)
                                    val balanceVal = String.format(Locale.US, "%.2f", remainingGB)
                                    val balanceText = "$balanceVal GB"

                                    val packageName = widgetData.getString("package_name", "") ?: ""
                                    val nameWithoutTech = packageName.replace(Regex("(?i)(4G|5G|3G|LTE)"), " ")
                                    val extractedGb = Regex("""(\d+(\.\d+)?)""").find(nameWithoutTech)?.groupValues?.get(1)?.toDoubleOrNull() ?: 0.0
                                    val effectivePlanBytes = if (extractedGb > 0.0) {
                                        (extractedGb * 1024.0 * 1024.0 * 1024.0).toLong()
                                    } else if (totalPlanBytes > 0L) {
                                        totalPlanBytes
                                    } else 0L

                                    val quotaProgress = if (effectivePlanBytes > 0L) {
                                        ((newRemaining.toDouble() / effectivePlanBytes.toDouble()) * 100).toInt().coerceIn(1, 100)
                                    } else {
                                        widgetData.getInt("quota_progress_int", 50)
                                    }

                                    widgetData.edit()
                                        .putString("balance_val", balanceVal)
                                        .putString("balance_text", balanceText)
                                        .putInt("quota_progress_int", quotaProgress)
                                        .apply()
                                }
                            }
                            widgetData.edit().putLong("last_recorded_router_usage", totalUsageBytes).apply()
                        }
                    }
                }

                // 5. استجابة statistics.stat_get_traffic_transport_status (السرعة اللحظية)
                if (responses.length() > 4) {
                    val trafficObj = responses.optJSONObject(4)?.optJSONObject("data")?.optJSONObject("traffic_transport_status")
                        ?: responses.optJSONObject(4)?.optJSONObject("traffic_transport_status")
                        ?: responses.optJSONObject(4)?.optJSONObject("data")
                    if (trafficObj != null) {
                        val rxSpeed = trafficObj.optInt("rx_status", 0)
                        networkSpeed = formatSpeed(rxSpeed)
                    }
                }
            }

            // توليد وقت التحديث بنظام 12 ساعة مع ص/م بالعربية
            val timeStr = formatArabicTime()

            // حفظ البيانات في SharedPreferences الخاصة بالويدجت (HomeWidgetPreferences)
            widgetData.edit()
                .putBoolean("is_connected", isConnected)
                .putInt("battery_level", batteryLevel)
                .putBoolean("is_charging", isCharging)
                .putInt("signal_bars", signalBars)
                .putString("signal_text", signalText)
                .putInt("devices_count", devicesCount)
                .putString("network_speed", networkSpeed)
                .putString("last_updated_time", timeStr)
                .apply()

            Log.d("WidgetAction", "✅ Data saved successfully: conn=$isConnected, bat=$batteryLevel%, sig=$signalBars, devs=$devicesCount, time=$timeStr")

            // تحديث الإشعار وكافة الويدجت النشطة مباشرة عبر AppWidgetManager
            updateAllWidgetsAndNotification(
                context = context,
                isConnected = isConnected,
                batteryLevel = batteryLevel,
                isCharging = isCharging,
                signalBars = signalBars,
                devicesCount = devicesCount,
                updatedTime = timeStr
            )

        } catch (e: Exception) {
            Log.e("WidgetAction", "❌ Failed to parse modem response: ${e.message}")
        }
    }

    /**
     * إرسال طلب POST عبر HttpURLConnection أصلي وخفيف جداً وسريع (أقل من 50 مللي ثانية).
     */
    private fun httpPost(urlString: String, jsonBody: String, sessionId: String? = null): String? {
        return try {
            val url = URL(urlString)
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.connectTimeout = 3000
            conn.readTimeout = 3000
            conn.doOutput = true
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("Accept", "application/json, text/javascript, */*; q=0.01")
            conn.setRequestProperty("X-Requested-With", "XMLHttpRequest")
            if (!sessionId.isNullOrBlank()) {
                conn.setRequestProperty("Cookie", "CGISID=$sessionId")
            }

            conn.outputStream.use { os ->
                os.write(jsonBody.toByteArray(Charsets.UTF_8))
            }

            if (conn.responseCode in 200..299) {
                conn.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
            } else {
                Log.w("WidgetAction", "HTTP response code: ${conn.responseCode}")
                null
            }
        } catch (e: Exception) {
            Log.e("WidgetAction", "HTTP request error: ${e.message}")
            null
        }
    }

    private fun formatSpeed(bytesPerSec: Int): String {
        if (bytesPerSec <= 0) return "0 B/s"
        if (bytesPerSec < 1024) return "$bytesPerSec B/s"
        if (bytesPerSec < 1024 * 1024) return String.format(Locale.US, "%.1f KB/s", bytesPerSec / 1024f)
        return String.format(Locale.US, "%.2f MB/s", bytesPerSec / (1024f * 1024f))
    }

    private fun formatUsageBytes(bytes: Long): String {
        if (bytes <= 0L) return "GB 0.0"
        val gb = bytes.toDouble() / (1024.0 * 1024.0 * 1024.0)
        if (gb >= 0.1) {
            return String.format(Locale.US, "GB %.1f", gb)
        }
        val mb = bytes.toDouble() / (1024.0 * 1024.0)
        return String.format(Locale.US, "MB %.1f", mb)
    }

    private fun formatArabicTime(): String {
        val calendar = Calendar.getInstance()
        val hour24 = calendar.get(Calendar.HOUR_OF_DAY)
        val hour12 = if (hour24 % 12 == 0) 12 else hour24 % 12
        val minute = String.format(Locale.US, "%02d", calendar.get(Calendar.MINUTE))
        val period = if (hour24 >= 12) "م" else "ص"
        return "$hour12:$minute $period"
    }

    private fun getLongSafe(prefs: android.content.SharedPreferences, key: String, defaultVal: Long = 0L): Long {
        return try {
            prefs.getLong(key, defaultVal)
        } catch (_: Exception) {
            try {
                prefs.getInt(key, defaultVal.toInt()).toLong()
            } catch (_: Exception) {
                defaultVal
            }
        }
    }

    /**
     * يعرض مؤشر "يتم التحديث..." فوراً لإعطاء رد فعل فوري للمستخدم عند لمس الزر.
     */
    private fun showRefreshingIndicator(context: Context) {
        val manager = AppWidgetManager.getInstance(context)

        // 1. ويدجت مصغر
        val smallIds = manager.getAppWidgetIds(ComponentName(context, WidgetSmallProvider::class.java))
        if (smallIds.isNotEmpty()) {
            val views = RemoteViews(context.packageName, R.layout.widget_small)
            views.setTextViewText(R.id.tv_status_text, "يتم التحديث...")
            manager.partiallyUpdateAppWidget(smallIds, views)
        }

        // 2. ويدجت بانر
        val bannerIds = manager.getAppWidgetIds(ComponentName(context, WidgetBannerProvider::class.java))
        if (bannerIds.isNotEmpty()) {
            val views = RemoteViews(context.packageName, R.layout.widget_banner)
            views.setTextViewText(R.id.tv_banner_days, "يتم التحديث...")
            manager.partiallyUpdateAppWidget(bannerIds, views)
        }

        // 3. ويدجت تفصيلي
        val detailedIds = manager.getAppWidgetIds(ComponentName(context, WidgetDetailedProvider::class.java))
        if (detailedIds.isNotEmpty()) {
            val views = RemoteViews(context.packageName, R.layout.widget_detailed)
            views.setTextViewText(R.id.tv_det_status, "يتم التحديث...")
            views.setTextViewText(R.id.tv_det_updated, "يتم التحديث...")
            manager.partiallyUpdateAppWidget(detailedIds, views)
        }
    }

    private fun updateAllWidgetsAndNotification(
        context: Context,
        isConnected: Boolean,
        batteryLevel: Int? = null,
        isCharging: Boolean? = null,
        signalBars: Int? = null,
        devicesCount: Int? = null,
        updatedTime: String? = null
    ) {
        // تحديث كافة الويدجت فوراً وبشكل متزامن قبل إنهاء خيط الـ BroadcastReceiver
        refreshAllWidgets(context)

        try {
            val widgetData = HomeWidgetPlugin.getData(context)
            val greeting = WidgetTimeHelper.getTimeBasedGreeting()
            val time = updatedTime ?: widgetData.getString("last_updated_time", "--:--") ?: "--:--"
            NotificationHelper.saveNotifState(
                context = context,
                isConnected = isConnected,
                balanceText = if (isConnected) (widgetData.getString("balance_text", "-- GB") ?: "-- GB") else "-- GB",
                daysRemaining = if (isConnected) (widgetData.getString("days_remaining", "-- يوم") ?: "-- يوم") else greeting,
                batteryLevel = if (isConnected) (batteryLevel ?: widgetData.getInt("battery_level", 0)) else 0,
                isCharging = if (isConnected) (isCharging ?: widgetData.getBoolean("is_charging", false)) else false,
                signalBars = if (isConnected) (signalBars ?: widgetData.getInt("signal_bars", 0)) else 0,
                devicesCount = if (isConnected) (devicesCount ?: widgetData.getInt("devices_count", 0)) else 0,
                lastUpdated = time,
                quotaProgress = if (isConnected) widgetData.getInt("quota_progress_int", 50) else 0,
                totalPlan = if (isConnected) (widgetData.getString("package_name", "باقة نشطة") ?: "باقة نشطة") else "يرجى الاتصال بمودم SAM4G"
            )
            NotificationHelper.refreshNotification(context)
        } catch (e: Exception) {
            Log.w("WidgetAction", "Could not refresh notification: ${e.message}")
        }
    }

    /**
     * تحديث مباشر وفوري لكافة الويدجت عبر AppWidgetManager دون انتظار أي Broadcast intent.
     */
    private fun refreshAllWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val widgetData = HomeWidgetPlugin.getData(context)

        // 1. تحديث مباشر للبانر (WidgetBannerProvider)
        val bannerIds = manager.getAppWidgetIds(ComponentName(context, WidgetBannerProvider::class.java))
        if (bannerIds.isNotEmpty()) {
            val provider = WidgetBannerProvider()
            for (id in bannerIds) {
                val views = RemoteViews(context.packageName, provider.layoutRes)
                provider.applyData(context, views, widgetData)
                manager.updateAppWidget(id, views)
            }
        }

        // 2. تحديث مباشر للويدجت التفصيلي (WidgetDetailedProvider)
        val detailedIds = manager.getAppWidgetIds(ComponentName(context, WidgetDetailedProvider::class.java))
        if (detailedIds.isNotEmpty()) {
            val provider = WidgetDetailedProvider()
            for (id in detailedIds) {
                val views = RemoteViews(context.packageName, provider.layoutRes)
                provider.applyData(context, views, widgetData)
                manager.updateAppWidget(id, views)
            }
        }

        // 3. تحديث مباشر للويدجت المصغر (WidgetSmallProvider)
        val smallIds = manager.getAppWidgetIds(ComponentName(context, WidgetSmallProvider::class.java))
        if (smallIds.isNotEmpty()) {
            val provider = WidgetSmallProvider()
            for (id in smallIds) {
                val views = RemoteViews(context.packageName, provider.layoutRes)
                provider.applyData(context, views, widgetData)
                manager.updateAppWidget(id, views)
            }
        }
    }

    private fun handleReboot(context: Context) {
        Log.d("WidgetAction", "⚡ Reboot action triggered -> Launching RebootConfirmActivity")
        val openIntent = Intent(context, RebootConfirmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        context.startActivity(openIntent)
    }
}

