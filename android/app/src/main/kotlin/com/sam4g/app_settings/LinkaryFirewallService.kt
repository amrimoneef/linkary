package com.sam4g.app_settings

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.NetworkCapabilities
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.Calendar
import kotlin.math.abs

/**
 * خدمة الجدار الناري (VPN) مع مراقبة الاستهلاك المدمجة.
 *
 * الأوضاع:
 * - START:   VPN نشط + مراقبة نشطة (حظر التطبيقات + مراقبة السقف)
 * - MONITOR: لا يوجد VPN tunnel لكن المراقبة نشطة (الخدمة تبقى حية لأنها VpnService)
 * - UPDATE:  تحديث قائمة التطبيقات المحظورة
 * - STOP:    إيقاف كل شيء (فقط عند عدم وجود أي حظر تلقائي)
 */
class LinkaryFirewallService : VpnService() {

    companion object {
        var isRunning = false
            private set
        var isMonitoring = false
            private set
        var isVpnActive = false
            private set

        const val CHANNEL_ID = "linkary_firewall"
        const val ALERT_CHANNEL_ID = "linkary_alerts"
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val FLUTTER_PREFIX = "flutter."
        const val GOALS_KEY = "${FLUTTER_PREFIX}mifi_monitor_app_goals"
        const val AUTO_BLOCK_KEY = "${FLUTTER_PREFIX}mifi_monitor_app_auto_block"
        const val BLOCKED_APPS_KEY = "${FLUTTER_PREFIX}mifi_firewall_blocked_apps"
        const val FIREWALL_ENABLED_KEY = "${FLUTTER_PREFIX}mifi_firewall_enabled"

        /**
         * بادئة VFI (Value Format Identifier) التي يستخدمها Flutter shared_preferences
         * لتمييز القوائم. الصيغة الفعلية في الملف:
         * VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!["item1","item2"]
         */
        private const val VFI_LIST_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu"

        /**
         * 🔑 تحليل قائمة Flutter المخزنة كـ String بصيغة VFI
         * الصيغة: VFI_PREFIX!["entry1","entry2"] أو ["entry1","entry2"]
         */
        fun parseFlutterStringList(rawValue: String?): List<String> {
            if (rawValue.isNullOrBlank()) return emptyList()

            // 1. إزالة بادئة VFI إذا وُجدت
            val jsonPart = if (rawValue.contains("!")) {
                rawValue.substringAfter("!")
            } else if (rawValue.startsWith(VFI_LIST_PREFIX)) {
                rawValue.removePrefix(VFI_LIST_PREFIX)
            } else {
                rawValue
            }

            // 2. تحليل JSON Array البسيط: ["item1","item2"]
            val trimmed = jsonPart.trim()
            if (!trimmed.startsWith("[")) return emptyList()

            val inner = trimmed.removePrefix("[").removeSuffix("]")
            if (inner.isBlank()) return emptyList()

            // تقسيم حسب "," مع مراعاة أن القيم مغلفة بـ "
            val entries = mutableListOf<String>()
            val sb = StringBuilder()
            var inQuote = false
            for (ch in inner) {
                when {
                    ch == '"' -> inQuote = !inQuote
                    ch == ',' && !inQuote -> {
                        entries.add(sb.toString().trim())
                        sb.clear()
                    }
                    else -> sb.append(ch)
                }
            }
            if (sb.isNotEmpty()) {
                entries.add(sb.toString().trim())
            }

            return entries
        }
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private var lastBlockedApps = mutableSetOf<String>()
    private val handler = Handler(Looper.getMainLooper())
    private val monitorRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return
            try {
                checkUsageAndAutoBlock()
            } catch (e: Exception) {
                Log.e("LinkaryVPN", "Monitor error: ${e.message}")
            }
            handler.postDelayed(this, 5000) // كل 5 ثوانٍ
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START" -> {
                val apps = intent.getStringArrayListExtra("apps") ?: arrayListOf()
                lastBlockedApps = apps.toMutableSet()
                startVpn(lastBlockedApps.toList())
                startMonitoring()
                isVpnActive = true
            }
            "MONITOR" -> {
                closeVpnTunnel()
                isVpnActive = false
                isRunning = true
                showMonitorOnlyNotification()
                startMonitoring()
                Log.d("LinkaryVPN", "👁️ Monitor-only mode activated")
            }
            "UPDATE" -> {
                val apps = intent.getStringArrayListExtra("apps") ?: arrayListOf()
                lastBlockedApps = apps.toMutableSet()
                if (isVpnActive) {
                    restartVpn(lastBlockedApps.toList())
                }
            }
            "STOP" -> stopAll()
        }
        return START_STICKY
    }

    /**
     * 🔥 عندما يسحب المستخدم التطبيق من قائمة التطبيقات الأخيرة
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d("LinkaryVPN", "⚠️ App task removed (swiped away)")
        
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val hasAutoBlock = hasAnyAutoBlock(prefs)
        val firewallEnabled = prefs.getBoolean(FIREWALL_ENABLED_KEY, false)
        
        if (hasAutoBlock || firewallEnabled) {
            Log.d("LinkaryVPN", "🔄 Rescheduling service after task removal")
            val restartIntent = Intent(this, LinkaryFirewallService::class.java)
            if (firewallEnabled && lastBlockedApps.isNotEmpty()) {
                restartIntent.action = "START"
                restartIntent.putStringArrayListExtra("apps", ArrayList(lastBlockedApps))
            } else if (hasAutoBlock) {
                restartIntent.action = "MONITOR"
            }
            handler.postDelayed({
                try { startService(restartIntent) } catch (e: Exception) {
                    Log.e("LinkaryVPN", "Failed to restart service: ${e.message}")
                }
            }, 1000)
        }
        super.onTaskRemoved(rootIntent)
    }

    private fun startMonitoring() {
        if (!isMonitoring) {
            isMonitoring = true
            handler.removeCallbacks(monitorRunnable)
            handler.postDelayed(monitorRunnable, 5000)
            Log.d("LinkaryVPN", "📡 Monitoring started")
        }
    }

    private fun checkUsageAndAutoBlock() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // 1. قراءة الأهداف (Goals)
        val goalsMap = readGoalsMap(prefs)
        if (goalsMap.isEmpty()) {
            Log.d("LinkaryVPN", "📊 No goals found, skipping check")
            return
        }

        // 2. قراءة إعدادات الحظر التلقائي
        val autoBlockMap = readAutoBlockMap(prefs)
        if (autoBlockMap.isEmpty()) {
            Log.d("LinkaryVPN", "📊 No auto-block prefs found, skipping check")
            return
        }

        // 3. قراءة التطبيقات المحظورة حالياً
        val currentBlockedApps = readCurrentBlockedApps(prefs)

        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager

        val newlyBlockedApps = mutableListOf<String>()

        for ((pkgName, limitBytes) in goalsMap) {
            if (autoBlockMap[pkgName] != true) {
                Log.d("LinkaryVPN", "⏭️ $pkgName - auto-block not enabled, skip")
                continue
            }
            if (currentBlockedApps.contains(pkgName)) continue
            if (lastBlockedApps.contains(pkgName)) continue

            try {
                val appInfo = packageManager.getApplicationInfo(pkgName, 0)
                val uid = appInfo.uid

                val usage = getUidUsage(networkStatsManager, uid, startTime, endTime)
                val baseline = getBaselineForApp(prefs, pkgName)
                val actualUsage = (usage - baseline).coerceAtLeast(0)

                Log.d("LinkaryVPN", "📊 $pkgName: usage=$actualUsage limit=$limitBytes (raw=$usage baseline=$baseline)")

                if (actualUsage >= limitBytes) {
                    newlyBlockedApps.add(pkgName)
                    showAutoBlockNotification(pkgName)
                    Log.d("LinkaryVPN", "🛡️ Threshold breached for $pkgName: $actualUsage/$limitBytes")
                }
            } catch (e: Exception) {
                Log.e("LinkaryVPN", "Error checking $pkgName: ${e.message}")
            }
        }

        if (newlyBlockedApps.isNotEmpty()) {
            lastBlockedApps.addAll(newlyBlockedApps)
            syncBlockedAppsToFlutter(prefs, lastBlockedApps)
            prefs.edit().putBoolean(FIREWALL_ENABLED_KEY, true).apply()

            startVpn(lastBlockedApps.toList())
            isVpnActive = true
            Log.d("LinkaryVPN", "🔥 VPN auto-activated with ${lastBlockedApps.size} blocked apps")
        }
    }

    // ======== Flutter SharedPreferences Readers ========

    /**
     * قراءة خريطة الأهداف: packageName -> limitBytes
     */
    private fun readGoalsMap(prefs: SharedPreferences): Map<String, Long> {
        val rawValue = prefs.getString(GOALS_KEY, null)
        val entries = parseFlutterStringList(rawValue)
        val result = mutableMapOf<String, Long>()

        for (entry in entries) {
            val parts = entry.split("|")
            if (parts.size >= 2) {
                val bytes = parts[1].toLongOrNull()
                if (bytes != null) {
                    result[parts[0]] = bytes
                }
            }
        }

        Log.d("LinkaryVPN", "📊 Goals: ${result.entries.joinToString { "${it.key}=${it.value}" }}")
        return result
    }

    /**
     * قراءة خريطة الحظر التلقائي: packageName -> enabled
     */
    private fun readAutoBlockMap(prefs: SharedPreferences): Map<String, Boolean> {
        val rawValue = prefs.getString(AUTO_BLOCK_KEY, null)
        val entries = parseFlutterStringList(rawValue)
        val result = mutableMapOf<String, Boolean>()

        for (entry in entries) {
            val parts = entry.split("|")
            if (parts.size >= 2) {
                result[parts[0]] = parts[1] == "true"
            }
        }

        Log.d("LinkaryVPN", "📊 AutoBlock: ${result.entries.joinToString { "${it.key}=${it.value}" }}")
        return result
    }

    private fun hasAnyAutoBlock(prefs: SharedPreferences): Boolean {
        return readAutoBlockMap(prefs).values.any { it }
    }

    private fun readCurrentBlockedApps(prefs: SharedPreferences): Set<String> {
        val json = prefs.getString(BLOCKED_APPS_KEY, null) ?: return emptySet()
        val result = mutableSetOf<String>()
        val regex = """"packageName"\s*:\s*"([^"]+)"""".toRegex()
        for (match in regex.findAll(json)) {
            result.add(match.groupValues[1])
        }
        return result
    }

    private fun getBaselineForApp(prefs: SharedPreferences, pkgName: String): Long {
        val calendar = Calendar.getInstance()
        val dateStr = String.format("%d-%02d-%02d", calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH) + 1, calendar.get(Calendar.DAY_OF_MONTH))
        val baselineKey = "${FLUTTER_PREFIX}mifi_monitor_daily_baseline_$dateStr"

        val rawValue = prefs.getString(baselineKey, null)
        val entries = parseFlutterStringList(rawValue)

        for (entry in entries) {
            val parts = entry.split("|")
            if (parts.size >= 3 && parts[0] == pkgName) {
                return (parts[1].toLongOrNull() ?: 0L) + (parts[2].toLongOrNull() ?: 0L)
            }
        }
        return 0L
    }

    // ======== VPN Tunnel Control ========

    private fun startVpn(blockedApps: List<String>) {
        closeVpnTunnel()

        if (blockedApps.isEmpty()) {
            isRunning = true
            showStatusNotification(0)
            return
        }

        val builder = Builder()
            .setSession("Linkary Shield")
            .addAddress("10.1.10.1", 32)
            .addRoute("0.0.0.0", 0)
            .allowBypass()

        for (pkg in blockedApps) {
            if (pkg == packageName) continue
            try {
                builder.addAllowedApplication(pkg)
            } catch (_: PackageManager.NameNotFoundException) {}
        }

        try {
            vpnInterface = builder.establish()
            isRunning = true
            showStatusNotification(blockedApps.size)
        } catch (e: Exception) {
            Log.e("LinkaryVPN", "VPN Start Error: ${e.message}")
        }
    }

    private fun closeVpnTunnel() {
        try { vpnInterface?.close() } catch (_: Exception) {}
        vpnInterface = null
    }

    private fun restartVpn(blockedApps: List<String>) {
        startVpn(blockedApps)
    }

    private fun stopAll() {
        handler.removeCallbacks(monitorRunnable)
        isMonitoring = false
        closeVpnTunnel()
        isRunning = false
        isVpnActive = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.d("LinkaryVPN", "🛑 Service fully stopped")
    }

    // ======== Data Helpers ========

    private fun getUidUsage(nsm: NetworkStatsManager, uid: Int, start: Long, end: Long): Long {
        return try {
            val stats = nsm.querySummary(NetworkCapabilities.TRANSPORT_WIFI, null, start, end)
            val bucket = NetworkStats.Bucket()
            var total = 0L
            while (stats.hasNextBucket()) {
                stats.getNextBucket(bucket)
                if (bucket.uid == uid) {
                    total += bucket.rxBytes + bucket.txBytes
                }
            }
            stats.close()
            total
        } catch (e: Exception) { 0L }
    }

    private fun syncBlockedAppsToFlutter(prefs: SharedPreferences, blockedApps: Set<String>) {
        val sb = StringBuilder("[")
        blockedApps.forEachIndexed { index, pkg ->
            val name = try {
                val info = packageManager.getApplicationInfo(pkg, 0)
                packageManager.getApplicationLabel(info).toString()
            } catch (e: Exception) { pkg }

            sb.append("{\"packageName\":\"$pkg\",\"appName\":\"$name\"}")
            if (index < blockedApps.size - 1) sb.append(",")
        }
        sb.append("]")
        prefs.edit().putString(BLOCKED_APPS_KEY, sb.toString()).apply()
    }

    // ======== Notifications ========

    private fun showAutoBlockNotification(pkgName: String) {
        val appName = try {
            val info = packageManager.getApplicationInfo(pkgName, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (e: Exception) { pkgName }

        val notification = NotificationCompat.Builder(this, ALERT_CHANNEL_ID)
            .setContentTitle("تم الحظر التلقائي 🛡️")
            .setContentText("تم حظر $appName لتجاوزه سقف الاستهلاك")
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        val manager = getSystemService(NotificationManager::class.java)
        manager?.notify(abs(pkgName.hashCode()), notification)
    }

    private fun showStatusNotification(count: Int) {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("حماية Sam4G نشطة")
            .setContentText(if (count > 0) "$count تطبيقات محظورة من الإنترنت" else "جدار الحماية في وضع الاستعداد")
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        try {
            startForeground(9001, notification)
        } catch (e: Exception) {
            Log.e("LinkaryVPN", "Foreground error: ${e.message}")
        }
    }

    private fun showMonitorOnlyNotification() {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("مراقب التطبيقات نشط")
            .setContentText("يتم مراقبة استهلاك البيانات لتطبيقاتك")
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .build()

        try {
            startForeground(9001, notification)
        } catch (e: Exception) {
            Log.e("LinkaryVPN", "Foreground error: ${e.message}")
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val serviceChannel = NotificationChannel(CHANNEL_ID, "Linkary Firewall Status", NotificationManager.IMPORTANCE_LOW)
            manager?.createNotificationChannel(serviceChannel)
            val alertChannel = NotificationChannel(ALERT_CHANNEL_ID, "Linkary Usage Alerts", NotificationManager.IMPORTANCE_HIGH)
            manager?.createNotificationChannel(alertChannel)
        }
    }

    override fun onRevoke() {
        stopAll()
    }

    override fun onDestroy() {
        Log.d("LinkaryVPN", "⚠️ Service onDestroy called")
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val hasAutoBlock = hasAnyAutoBlock(prefs)
        val firewallEnabled = prefs.getBoolean(FIREWALL_ENABLED_KEY, false)

        if (hasAutoBlock || firewallEnabled) {
            Log.d("LinkaryVPN", "🔄 Service destroyed but should be running - scheduling restart")
            val restartIntent = Intent(this, LinkaryFirewallService::class.java)
            if (firewallEnabled && lastBlockedApps.isNotEmpty()) {
                restartIntent.action = "START"
                restartIntent.putStringArrayListExtra("apps", ArrayList(lastBlockedApps))
            } else if (hasAutoBlock) {
                restartIntent.action = "MONITOR"
            }
            try { startService(restartIntent) } catch (e: Exception) {
                Log.e("LinkaryVPN", "Failed to restart in onDestroy: ${e.message}")
            }
        }

        handler.removeCallbacks(monitorRunnable)
        isMonitoring = false
        isRunning = false
        super.onDestroy()
    }
}
