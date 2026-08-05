package com.sam4g.app_settings

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.NetworkCapabilities
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.Calendar
import kotlin.math.abs

/**
 * خدمة مراقبة الاستهلاك المستقلة (احتياطية).
 * الخدمة الأساسية هي LinkaryFirewallService (VpnService).
 */
class UsageMonitorService : Service() {

    companion object {
        var isRunning = false
            private set

        const val CHANNEL_ID = "linkary_monitor"
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val FLUTTER_PREFIX = "flutter."
        const val GOALS_KEY = "${FLUTTER_PREFIX}mifi_monitor_app_goals"
        const val AUTO_BLOCK_KEY = "${FLUTTER_PREFIX}mifi_monitor_app_auto_block"
        const val BLOCKED_APPS_KEY = "${FLUTTER_PREFIX}mifi_firewall_blocked_apps"
        const val FIREWALL_ENABLED_KEY = "${FLUTTER_PREFIX}mifi_firewall_enabled"
    }

    private val handler = Handler(Looper.getMainLooper())
    private val monitorRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return
            try {
                checkUsageAndAutoBlock()
            } catch (e: Exception) {
                Log.e("LinkaryMonitor", "Monitor error: ${e.message}")
            }
            handler.postDelayed(this, 5000)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START" -> {
                if (!isRunning) {
                    isRunning = true
                    showMonitorNotification()
                    handler.postDelayed(monitorRunnable, 5000)
                    Log.d("LinkaryMonitor", "✅ Usage monitor service started")
                }
            }
            "STOP" -> stopMonitor()
        }
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d("LinkaryMonitor", "⚠️ App task removed")
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (hasAnyAutoBlock(prefs)) {
            val restartIntent = Intent(this, UsageMonitorService::class.java).setAction("START")
            handler.postDelayed({
                try { startService(restartIntent) } catch (e: Exception) {
                    Log.e("LinkaryMonitor", "Failed to restart: ${e.message}")
                }
            }, 1000)
        }
        super.onTaskRemoved(rootIntent)
    }

    private fun stopMonitor() {
        handler.removeCallbacks(monitorRunnable)
        isRunning = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.d("LinkaryMonitor", "🛑 Usage monitor service stopped")
    }

    private fun checkUsageAndAutoBlock() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // استخدام نفس المحلل المركزي من LinkaryFirewallService
        val goalsRaw = prefs.getString(GOALS_KEY, null)
        val goalsEntries = LinkaryFirewallService.parseFlutterStringList(goalsRaw)
        val goalsMap = mutableMapOf<String, Long>()
        for (entry in goalsEntries) {
            val parts = entry.split("|")
            if (parts.size >= 2) {
                val bytes = parts[1].toLongOrNull()
                if (bytes != null) goalsMap[parts[0]] = bytes
            }
        }
        if (goalsMap.isEmpty()) return

        val autoBlockRaw = prefs.getString(AUTO_BLOCK_KEY, null)
        val autoBlockEntries = LinkaryFirewallService.parseFlutterStringList(autoBlockRaw)
        val autoBlockMap = mutableMapOf<String, Boolean>()
        for (entry in autoBlockEntries) {
            val parts = entry.split("|")
            if (parts.size >= 2) autoBlockMap[parts[0]] = parts[1] == "true"
        }
        if (autoBlockMap.isEmpty()) return

        val currentBlockedApps = readCurrentBlockedApps(prefs)

        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val newlyBlockedApps = mutableListOf<String>()

        for ((packageName, limitBytes) in goalsMap) {
            if (autoBlockMap[packageName] != true) continue
            if (currentBlockedApps.contains(packageName)) continue

            try {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                val uid = appInfo.uid
                val usage = getUidUsage(networkStatsManager, uid, startTime, endTime)
                val baseline = getBaselineForApp(prefs, packageName)
                val actualUsage = (usage - baseline).coerceAtLeast(0)

                if (actualUsage >= limitBytes) {
                    newlyBlockedApps.add(packageName)
                    showAutoBlockNotification(packageName)
                    Log.d("LinkaryMonitor", "🛡️ Threshold breached for $packageName: $actualUsage/$limitBytes")
                }
            } catch (e: Exception) {
                Log.e("LinkaryMonitor", "Error checking $packageName: ${e.message}")
            }
        }

        if (newlyBlockedApps.isNotEmpty()) {
            val allBlocked = currentBlockedApps.toMutableSet()
            allBlocked.addAll(newlyBlockedApps)
            syncBlockedAppsToFlutter(prefs, allBlocked)
            prefs.edit().putBoolean(FIREWALL_ENABLED_KEY, true).apply()
            startFirewallAutomatically(allBlocked.toList())
        }
    }

    private fun hasAnyAutoBlock(prefs: SharedPreferences): Boolean {
        val raw = prefs.getString(AUTO_BLOCK_KEY, null)
        val entries = LinkaryFirewallService.parseFlutterStringList(raw)
        for (entry in entries) {
            val parts = entry.split("|")
            if (parts.size >= 2 && parts[1] == "true") return true
        }
        return false
    }

    private fun startFirewallAutomatically(blockedApps: List<String>) {
        val vpnIntent = VpnService.prepare(this)
        if (vpnIntent != null) {
            Log.e("LinkaryMonitor", "⚠️ VPN permission not granted")
            showVpnPermissionNeededNotification()
            return
        }
        val firewallIntent = Intent(this, LinkaryFirewallService::class.java)
            .setAction("START")
            .putStringArrayListExtra("apps", ArrayList(blockedApps))
        startService(firewallIntent)
        Log.d("LinkaryMonitor", "🔥 Firewall auto-started with ${blockedApps.size} blocked apps")
    }

    private fun readCurrentBlockedApps(prefs: SharedPreferences): Set<String> {
        val json = prefs.getString(BLOCKED_APPS_KEY, null) ?: return emptySet()
        val result = mutableSetOf<String>()
        val regex = """"packageName"\s*:\s*"([^"]+)"""".toRegex()
        for (match in regex.findAll(json)) { result.add(match.groupValues[1]) }
        return result
    }

    private fun getUidUsage(nsm: NetworkStatsManager, uid: Int, start: Long, end: Long): Long {
        return try {
            val stats = nsm.querySummary(NetworkCapabilities.TRANSPORT_WIFI, null, start, end)
            val bucket = NetworkStats.Bucket()
            var total = 0L
            while (stats.hasNextBucket()) {
                stats.getNextBucket(bucket)
                if (bucket.uid == uid) { total += bucket.rxBytes + bucket.txBytes }
            }
            stats.close()
            total
        } catch (e: Exception) { 0L }
    }

    private fun getBaselineForApp(prefs: SharedPreferences, packageName: String): Long {
        val calendar = Calendar.getInstance()
        val dateStr = String.format("%d-%02d-%02d", calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH) + 1, calendar.get(Calendar.DAY_OF_MONTH))
        val baselineKey = "${FLUTTER_PREFIX}mifi_monitor_daily_baseline_$dateStr"

        val rawValue = prefs.getString(baselineKey, null)
        val entries = LinkaryFirewallService.parseFlutterStringList(rawValue)
        for (entry in entries) {
            val parts = entry.split("|")
            if (parts.size >= 3 && parts[0] == packageName) {
                return (parts[1].toLongOrNull() ?: 0L) + (parts[2].toLongOrNull() ?: 0L)
            }
        }
        return 0L
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

    private fun showAutoBlockNotification(packageName: String) {
        val appName = try {
            val info = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (e: Exception) { packageName }
        val notification = NotificationCompat.Builder(this, LinkaryFirewallService.ALERT_CHANNEL_ID)
            .setContentTitle("تم الحظر التلقائي 🛡️")
            .setContentText("تم حظر $appName لتجاوزه سقف الاستهلاك")
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true).build()
        val manager = getSystemService(NotificationManager::class.java)
        manager?.notify(abs(packageName.hashCode()), notification)
    }

    private fun showVpnPermissionNeededNotification() {
        val notification = NotificationCompat.Builder(this, LinkaryFirewallService.ALERT_CHANNEL_ID)
            .setContentTitle("إجراء مطلوب ⚠️")
            .setContentText("تطبيق تجاوز سقف الاستهلاك! افتح Linkary لتفعيل الحظر.")
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true).build()
        val manager = getSystemService(NotificationManager::class.java)
        manager?.notify(9999, notification)
    }

    private fun showMonitorNotification() {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("مراقبة الاستهلاك نشطة")
            .setContentText("يتم مراقبة استهلاك البيانات لتطبيقاتك")
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MIN).build()
        try { startForeground(9002, notification) } catch (e: Exception) {
            Log.e("LinkaryMonitor", "Foreground error: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(CHANNEL_ID, "مراقبة الاستهلاك", NotificationManager.IMPORTANCE_MIN).apply {
                description = "خدمة مراقبة استهلاك البيانات في الخلفية"
            }
            manager?.createNotificationChannel(channel)
            val alertChannel = NotificationChannel(LinkaryFirewallService.ALERT_CHANNEL_ID, "Linkary Usage Alerts", NotificationManager.IMPORTANCE_HIGH)
            manager?.createNotificationChannel(alertChannel)
        }
    }

    override fun onDestroy() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (hasAnyAutoBlock(prefs)) {
            val restartIntent = Intent(this, UsageMonitorService::class.java).setAction("START")
            try { startService(restartIntent) } catch (e: Exception) {
                Log.e("LinkaryMonitor", "Failed to restart in onDestroy: ${e.message}")
            }
        }
        handler.removeCallbacks(monitorRunnable)
        isRunning = false
        super.onDestroy()
    }
}
