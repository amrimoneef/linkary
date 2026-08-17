package com.sam4g.app_settings

import android.os.Handler
import android.os.Looper
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import java.io.ByteArrayOutputStream
import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.app.usage.UsageStatsManager
import android.content.Context;
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.VpnService
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.LruCache
import android.util.Log
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.AudioAttributes
import android.net.wifi.WifiManager
import android.net.wifi.WifiInfo
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.linkary.mifi/usage"
    private val FIREWALL_CHANNEL = "com.linkary.mifi/firewall"
    private val MONITOR_CHANNEL = "com.linkary.mifi/monitor"
    private val WIFI_RSSI_CHANNEL = "com.linkary/wifi_rssi"
    private val ANTI_LOSS_CHANNEL = "com.linkary/anti_loss"
    private val VPN_REQUEST_CODE = 1001
    private var vpnPendingResult: MethodChannel.Result? = null
    
    // 🚀 Icon Cache to prevent expensive extractions on every refresh
    private val iconCache = LruCache<String, ByteArray>(1000) // Cache for 1000 icons (approx 5MB of RAM)

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsagePermission" -> {
                    result.success(hasUsagePermission())
                }
                "requestUsagePermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        startActivity(intent)
                    } catch (e: Exception) {
                        // Fallback in case the action is not supported
                    }
                    result.success(null)
                }
                "getAppUsage" -> {
                    val startTime = (call.argument<Number>("startTime")?.toLong()) ?: 0L
                    val endTime = (call.argument<Number>("endTime")?.toLong()) ?: System.currentTimeMillis()
                    
                    if (hasUsagePermission()) {
                        Thread {
                            try {
                                val usageData = getWifiUsageStats(startTime, endTime)
                                Handler(Looper.getMainLooper()).post {
                                    result.success(usageData)
                                }
                            } catch (e: Exception) {
                                Handler(Looper.getMainLooper()).post {
                                    result.error("ERROR", e.message, null)
                                }
                            }
                        }.start()
                    } else {
                        result.error("PERMISSION_DENIED", "Usage access not granted", null)
                    }
                }
                "clearIconCache" -> {
                    iconCache.evictAll()
                    result.success(true)
                }
                "getInstalledApps" -> {
                    Thread {
                        try {
                            val apps = getInstalledApps()
                            Handler(Looper.getMainLooper()).post {
                                result.success(apps)
                            }
                        } catch (e: Exception) {
                            Handler(Looper.getMainLooper()).post {
                                result.error("ERROR", e.message, null)
                            }
                        }
                    }.start()
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FIREWALL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareVpn" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        // Request notification permission silently if needed
                        if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1002)
                        }
                    }
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        vpnPendingResult = result
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                    } else {
                        result.success(true)
                    }
                }
                "startFirewall" -> {
                    val apps = call.argument<List<String>>("apps") ?: emptyList()
                    val i = Intent(this, LinkaryFirewallService::class.java)
                        .setAction("START")
                        .putStringArrayListExtra("apps", ArrayList(apps))
                    startForegroundServiceCompat(i)
                    result.success(true)
                }
                "updateFirewall" -> {
                    val apps = call.argument<List<String>>("apps") ?: emptyList()
                    val i = Intent(this, LinkaryFirewallService::class.java)
                        .setAction("UPDATE")
                        .putStringArrayListExtra("apps", ArrayList(apps))
                    startForegroundServiceCompat(i)
                    result.success(true)
                }
                "stopFirewall" -> {
                    val i = Intent(this, LinkaryFirewallService::class.java).setAction("STOP")
                    startForegroundServiceCompat(i)
                    result.success(true)
                }
                "isFirewallActive" -> {
                    result.success(LinkaryFirewallService.isRunning)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MONITOR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startMonitor" -> {
                    // تشغيل خدمة VPN في وضع المراقبة فقط (بدون tunnel)
                    val i = Intent(this, LinkaryFirewallService::class.java).setAction("MONITOR")
                    startForegroundServiceCompat(i)
                    result.success(true)
                }
                "stopMonitor" -> {
                    // إيقاف الخدمة بالكامل (فقط إذا لم يكن VPN نشطاً)
                    if (!LinkaryFirewallService.isVpnActive) {
                        val i = Intent(this, LinkaryFirewallService::class.java).setAction("STOP")
                        startForegroundServiceCompat(i)
                    }
                    result.success(true)
                }
                "isMonitorRunning" -> {
                    result.success(LinkaryFirewallService.isMonitoring)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ANTI_LOSS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAntiLoss" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1003)
                        }
                    }
                    val soundName = call.argument<String>("soundName") ?: "alarm1"
                    // Read current BSSID: prefer Flutter-provided, fallback to reading it here
                    var bssid = call.argument<String>("bssid") ?: ""
                    if (bssid.isEmpty()) {
                        try {
                            val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                            bssid = wm.connectionInfo.bssid ?: ""
                        } catch (_: Exception) {}
                    }
                    val i = Intent(this, AntiLossService::class.java).apply {
                        action = "START"
                        putExtra("soundName", soundName)
                        putExtra("bssid", bssid)
                    }
                    startForegroundServiceCompat(i)
                    result.success(true)
                }
                "previewAlarmSound" -> {
                    val soundName = call.argument<String>("soundName") ?: "alarm1"
                    previewSound(soundName)
                    result.success(true)
                }
                "stopAntiLoss" -> {
                    val i = Intent(this, AntiLossService::class.java).setAction("STOP")
                    startForegroundServiceCompat(i)
                    result.success(true)
                }
                "isAntiLossRunning" -> {
                    result.success(AntiLossService.isRunning)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIFI_RSSI_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWifiInfo" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val wifiInfo = wifiManager.connectionInfo
                        val ssid = wifiInfo.ssid?.replace("\"", "") ?: ""
                        result.success(mapOf(
                            "rssi" to wifiInfo.rssi,
                            "frequency" to wifiInfo.frequency,
                            "ssid" to ssid
                        ))
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getRssi" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val wifiInfo = wifiManager.connectionInfo
                        result.success(wifiInfo.rssi)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getFrequency" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val wifiInfo = wifiManager.connectionInfo
                        result.success(wifiInfo.frequency)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getSSID" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val wifiInfo = wifiManager.connectionInfo
                        val ssid = wifiInfo.ssid?.replace("\"", "") ?: ""
                        result.success(ssid)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getBSSID" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val wifiInfo = wifiManager.connectionInfo
                        result.success(wifiInfo.bssid ?: "")
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                vpnPendingResult?.success(true)
            } else {
                vpnPendingResult?.success(false)
            }
            vpnPendingResult = null
        }
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun startForegroundServiceCompat(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun getWifiUsageStats(startTime: Long, endTime: Long): List<Map<String, Any?>> {
        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val packageManager = packageManager
        val appUsageList = mutableListOf<Map<String, Any?>>()
        val usageStatsMap = getUsageStatsMap(startTime, endTime)

        try {
            val networkStats = networkStatsManager.querySummary(NetworkCapabilities.TRANSPORT_WIFI, null, startTime, endTime)
            val bucket = NetworkStats.Bucket()

            val uidRxMap = mutableMapOf<Int, Long>()
            val uidTxMap = mutableMapOf<Int, Long>()

            while (networkStats.hasNextBucket()) {
                networkStats.getNextBucket(bucket)
                val uid = bucket.uid

                uidRxMap[uid] = uidRxMap.getOrDefault(uid, 0L) + bucket.rxBytes
                uidTxMap[uid] = uidTxMap.getOrDefault(uid, 0L) + bucket.txBytes
            }
            networkStats.close()

            val packages = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
            for (appInfo in packages) {
                val uid = appInfo.uid
                val rxBytes = uidRxMap[uid] ?: 0L
                val txBytes = uidTxMap[uid] ?: 0L
                val totalBytes = rxBytes + txBytes

                if (totalBytes > 1024) {
                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    val packageName = appInfo.packageName
                    val stats = usageStatsMap[packageName]
                    


                    val map = mapOf(
                        "packageName" to packageName,
                        "appName" to appName,
                        "totalBytes" to totalBytes,
                        "rxBytes" to rxBytes,
                        "txBytes" to txBytes,
                        "lastActiveTime" to (stats?.get("lastTimeUsed") ?: 0L),
                        "usageTime" to (stats?.get("totalTimeInForeground") ?: 0L),
                        "iconData" to getIconByteArray(packageName)
                    )
                    appUsageList.add(map)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return appUsageList
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val packageManager = packageManager
        val appsList = mutableListOf<Map<String, Any?>>()
        val packages = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
        val usageStatsMap = getUsageStatsMap(System.currentTimeMillis() - 86400000L, System.currentTimeMillis()) // Today's stats

        for (appInfo in packages) {
            val appName = packageManager.getApplicationLabel(appInfo).toString()
            val packageName = appInfo.packageName
            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val stats = usageStatsMap[packageName]
            


            val map = mapOf(
                "packageName" to packageName,
                "appName" to appName,
                "isSystemApp" to isSystem,
                "lastActiveTime" to (stats?.get("lastTimeUsed") ?: 0L),
                "usageTime" to (stats?.get("totalTimeInForeground") ?: 0L),
                "iconData" to getIconByteArray(packageName)
            )
            appsList.add(map)
        }
        return appsList
    }

    private fun getUsageStatsMap(startTime: Long, endTime: Long): Map<String, Map<String, Long>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
        return stats.mapValues { (_, usageStats) ->
            mapOf(
                "lastTimeUsed" to usageStats.lastTimeUsed,
                "totalTimeInForeground" to usageStats.totalTimeInForeground
            )
        }
    }

    private fun getIconByteArray(packageName: String): ByteArray? {
        // 1. Check Cache first
        val cached = iconCache.get(packageName)
        if (cached != null) return cached

        try {
            val drawable = packageManager.getApplicationIcon(packageName)
            val bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                val bmp = Bitmap.createBitmap(
                    drawable.intrinsicWidth.coerceAtLeast(1),
                    drawable.intrinsicHeight.coerceAtLeast(1),
                    Bitmap.Config.ARGB_8888
                )
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bmp
            }

            // 🚀 Downscale to 64x64 (even smaller than before) for extreme efficiency
            val scaledBmp = Bitmap.createScaledBitmap(bitmap, 64, 64, true)

            val stream = ByteArrayOutputStream()
            scaledBmp.compress(Bitmap.CompressFormat.PNG, 80, stream) // 80% quality is enough for tiny icons
            val byteArray = stream.toByteArray()
            
            // 2. Save to Cache
            iconCache.put(packageName, byteArray)
            
            return byteArray
        } catch (e: Exception) {
            return null
        }
    }

    private var previewPlayer: MediaPlayer? = null

    private fun previewSound(soundName: String) {
        previewPlayer?.stop()
        previewPlayer?.release()
        previewPlayer = null

        val soundResId = when (soundName) {
            "alarm1" -> resources.getIdentifier("alarm1", "raw", packageName)
            "alarm2" -> resources.getIdentifier("alarm2", "raw", packageName)
            "alarm3" -> resources.getIdentifier("alarm3", "raw", packageName)
            else -> 0
        }

        try {
            previewPlayer = MediaPlayer().apply {
                if (soundResId != 0) {
                    setDataSource(this@MainActivity, android.net.Uri.parse("android.resource://$packageName/$soundResId"))
                } else {
                    setDataSource(this@MainActivity, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
                }
                setAudioAttributes(AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build())
                prepare()
                start()
                setOnCompletionListener {
                    it.release()
                    if (previewPlayer == it) previewPlayer = null
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error previewing sound: ${e.message}")
        }
    }
}
