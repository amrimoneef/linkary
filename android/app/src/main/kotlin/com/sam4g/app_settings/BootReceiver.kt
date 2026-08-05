package com.sam4g.app_settings

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log

/**
 * يستقبل إشعار إعادة تشغيل الجهاز لإعادة تشغيل خدمات الجدار الناري والمراقبة تلقائياً.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val FLUTTER_PREFIX = "flutter."
        const val FIREWALL_ENABLED_KEY = "${FLUTTER_PREFIX}mifi_firewall_enabled"
        const val BLOCKED_APPS_KEY = "${FLUTTER_PREFIX}mifi_firewall_blocked_apps"
        const val AUTO_BLOCK_KEY = "${FLUTTER_PREFIX}mifi_monitor_app_auto_block"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.QUICKBOOT_POWERON" &&
            intent.action != "com.htc.intent.action.QUICKBOOT_POWERON") {
            return
        }

        Log.d("LinkaryBoot", "📱 Device boot completed - checking firewall state")

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val firewallEnabled = prefs.getBoolean(FIREWALL_ENABLED_KEY, false)
        val hasAutoBlock = hasAnyAutoBlock(prefs)

        if (firewallEnabled) {
            val blockedApps = readBlockedApps(prefs)
            if (blockedApps.isNotEmpty()) {
                Log.d("LinkaryBoot", "🛡️ Restarting firewall with ${blockedApps.size} blocked apps")
                val serviceIntent = Intent(context, LinkaryFirewallService::class.java)
                    .setAction("START")
                    .putStringArrayListExtra("apps", ArrayList(blockedApps))
                startServiceSafely(context, serviceIntent)
                return
            }
        }

        if (hasAutoBlock) {
            Log.d("LinkaryBoot", "👁️ Restarting monitor-only mode")
            val serviceIntent = Intent(context, LinkaryFirewallService::class.java)
                .setAction("MONITOR")
            startServiceSafely(context, serviceIntent)
        }
    }

    private fun startServiceSafely(context: Context, intent: Intent) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        } catch (e: Exception) {
            Log.e("LinkaryBoot", "Failed to start service on boot: ${e.message}")
        }
    }

    private fun readBlockedApps(prefs: SharedPreferences): List<String> {
        val json = prefs.getString(BLOCKED_APPS_KEY, null) ?: return emptyList()
        val result = mutableListOf<String>()
        val regex = """"packageName"\s*:\s*"([^"]+)"""".toRegex()
        for (match in regex.findAll(json)) {
            val pkg = match.groupValues[1]
            if (pkg != "com.sam4g.app_settings") {
                result.add(pkg)
            }
        }
        return result
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
}
