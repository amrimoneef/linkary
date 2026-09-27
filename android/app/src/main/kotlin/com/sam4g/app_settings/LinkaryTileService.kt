package com.sam4g.app_settings

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * خدمة Quick Settings Tile المدمجة في ستارة إشعارات أندرويد لـ Linkary.
 *
 * المزايا:
 * 1. عرض حي ومباشر لرصيد مودم SAM4G المتبقي في ستارة الإشعارات دون فتح التطبيق.
 * 2. إمكانية النقر لتحديث البيانات فورياً في الخلفية مع تأثير تفاعلي حي.
 * 3. فتح التطبيق تلقائياً عند النقر في وضع عدم الاتصال لتنبيه المستخدم.
 * 4. متوافق بنسبة 100% مع أندرويد 7.0 (API 24) وحتى أندرويد 15 (API 35).
 */
class LinkaryTileService : TileService() {

    companion object {
        private const val TAG = "LinkaryTile"

        /**
         * طلب إعادة رسم وتحديث بيانات الـ Tile من أي مكان في التطبيق (BroadcastReceiver أو SyncService)
         */
        fun requestUpdate(context: Context) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    requestListeningState(context, ComponentName(context, LinkaryTileService::class.java))
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to request tile update: ${e.message}")
            }
        }
    }

    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }

    override fun onStopListening() {
        super.onStopListening()
    }

    override fun onClick() {
        super.onClick()
        val tile = qsTile ?: return

        val isConnected = WidgetActionReceiver.isConnectedToSam4gWifi(this)
        if (!isConnected) {
            // إذا لم يكن متصلاً بالمودم: فتح التطبيق
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            if (launchIntent != null) {
                if (Build.VERSION.SDK_INT >= 34) {
                    val pendingIntent = PendingIntent.getActivity(
                        this, 0, launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    startActivityAndCollapse(pendingIntent)
                } else {
                    @Suppress("DEPRECATION")
                    startActivityAndCollapse(launchIntent)
                }
            }
            return
        }

        // عند الاتصال: تعيين حالة التحديث فوراً
        tile.state = Tile.STATE_ACTIVE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = "جاري التحديث..."
        } else {
            tile.label = "جاري التحديث..."
        }
        tile.updateTile()

        // إرسال أمر التحديث اليدوي لـ WidgetActionReceiver
        val refreshIntent = Intent(this, WidgetActionReceiver::class.java).apply {
            action = WidgetActionReceiver.ACTION_WIDGET_REFRESH
        }
        sendBroadcast(refreshIntent)

        // إعادة فحص الحالة وتحديث النص بعد 1500 مللي ثانية
        Handler(Looper.getMainLooper()).postDelayed({
            updateTileState()
        }, 1500L)
    }

    private fun updateTileState() {
        val tile = qsTile ?: return
        val widgetData = HomeWidgetPlugin.getData(this)
        val isConnected = WidgetActionReceiver.isConnectedToSam4gWifi(this)
        val balanceText = widgetData.getString("balance_text", "") ?: ""
        val daysRemaining = widgetData.getString("days_remaining", "") ?: ""

        val iconRes = R.drawable.ic_qs_modem
        tile.icon = Icon.createWithResource(this, iconRes)

        if (isConnected) {
            tile.state = Tile.STATE_ACTIVE
            tile.label = "مودم SAM4G"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                tile.subtitle = if (balanceText.isNotBlank()) balanceText else "متصل"
            } else {
                tile.label = if (balanceText.isNotBlank()) "SAM4G: $balanceText" else "مودم SAM4G"
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                tile.stateDescription = if (balanceText.isNotBlank()) {
                    "$balanceText • $daysRemaining"
                } else {
                    "متصل بمودم SAM4G"
                }
            }
        } else {
            tile.state = Tile.STATE_INACTIVE
            tile.label = "مودم SAM4G"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                tile.subtitle = "غير متصل"
            } else {
                tile.label = "SAM4G (غير متصل)"
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                tile.stateDescription = "غير متصل بمودم SAM4G"
            }
        }

        tile.updateTile()
    }
}
