package com.sam4g.app_settings

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import kotlin.math.pow
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import android.content.pm.ServiceInfo

class AntiLossService : Service() {

    companion object {
        var isRunning = false
            private set
        const val CHANNEL_ID = "antiloss_service_channel"
        const val ALERT_CHANNEL_ID = "antiloss_alert_channel_v2"
    }

    private val handler = Handler(Looper.getMainLooper())
    private var consecutiveWeakReadings = 0
    private var isAlerting = false
    private var mediaPlayer: MediaPlayer? = null
    private var soundName: String = "alarm1"

    private val monitorRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return
            checkWifiSignal()
            handler.postDelayed(this, 2000) // كل 2 ثانية
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            stopSelf()
            return START_NOT_STICKY
        } else if (intent?.action == "STOP_ALARM_ONLY") {
            stopAlarm()
            consecutiveWeakReadings = -5 // يعطيه 10 ثواني مهلة قبل أن يرن مرة أخرى إذا لم تتحسن الإشارة
            return START_STICKY
        }

        isRunning = true
        consecutiveWeakReadings = 0
        isAlerting = false
        soundName = intent?.getStringExtra("soundName") ?: "alarm1"
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceCompat.startForeground(
                    this,
                    9002,
                    createStatusNotification("جاري المراقبة..."),
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                    else 0
                )
            } else {
                startForeground(9002, createStatusNotification("جاري المراقبة..."))
            }
        } catch (e: Exception) {
            Log.e("AntiLossService", "Foreground error: ${e.message}")
        }
        
        handler.removeCallbacks(monitorRunnable)
        handler.postDelayed(monitorRunnable, 2000)
        
        Log.d("AntiLossService", "🛡️ Anti-Loss Service Started")
        
        return START_STICKY
    }

    private fun checkWifiSignal() {
        try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiInfo = wifiManager.connectionInfo
            val rssi = wifiInfo.rssi

            Log.d("AntiLossService", "📡 Current RSSI: $rssi")

            if (rssi < -65 && rssi != -127) { // Only weak signal, NOT completely disconnected
                consecutiveWeakReadings++
            } else {
                consecutiveWeakReadings = 0
                if (isAlerting) {
                    isAlerting = false
                    stopAlarm()
                }
            }

            // إذا انقطعت الإشارة تماماً أو ضعفت جداً لمدة 6 ثواني (3 قراءات متتالية)
            if (consecutiveWeakReadings >= 5 && !isAlerting) {
                isAlerting = true
                triggerAlarmNotification()
            }

            // Update foreground notification with current RSSI
            if (!isAlerting) {
                val distance = calculateDistance(rssi)
                val distanceStr = formatDistance(distance)
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(9002, createStatusNotification("البعد التقريبي: $distanceStr"))
            }

        } catch (e: Exception) {
            Log.e("AntiLossService", "Error reading RSSI: ${e.message}")
        }
    }

    private fun calculateDistance(rssi: Int): Double {
        if (rssi >= 0 || rssi <= -100) return 0.0
        val txPower = -50.0
        val n = 2.5
        return 10.0.pow((txPower - rssi) / (10.0 * n))
    }

    private fun formatDistance(distance: Double): String {
        if (distance < 1.0) {
            return "${(distance * 100).toInt()} سم"
        }
        return String.format(java.util.Locale.US, "%.1f متر", distance)
    }

    private fun triggerAlarmNotification() {
        Log.d("AntiLossService", "🚨 TRIGGERING ALARM!")
        
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // تحديد مصدر الصوت
        val soundResId = when (soundName) {
            "alarm1" -> resources.getIdentifier("alarm1", "raw", packageName)
            "alarm2" -> resources.getIdentifier("alarm2", "raw", packageName)
            "alarm3" -> resources.getIdentifier("alarm3", "raw", packageName)
            else -> 0
        }

        // تشغيل الصوت يدوياً باستخدام MediaPlayer لضمان القدرة على تغييره بدون إنشاء قناة إشعارات جديدة
        if (mediaPlayer == null) {
            mediaPlayer = MediaPlayer().apply {
                try {
                    if (soundResId != 0) {
                        setDataSource(this@AntiLossService, android.net.Uri.parse("android.resource://$packageName/$soundResId"))
                    } else {
                        setDataSource(this@AntiLossService, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
                    }
                    setAudioAttributes(AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .build())
                    
                    isLooping = false
                    var playCount = 1
                    setOnCompletionListener {
                        if (playCount < 2) {
                            playCount++
                            it.start()
                        }
                    }
                    prepare()
                    start()
                } catch (e: Exception) {
                    Log.e("AntiLossService", "Error playing alarm sound: ${e.message}")
                }
            }
        }

        val stopIntent = Intent(this, AntiLossService::class.java).apply {
            action = "STOP_ALARM_ONLY"
        }
        val stopPendingIntent = PendingIntent.getService(this, 1, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, ALERT_CHANNEL_ID)
            .setContentTitle("⚠️ تنبيه نسيان المودم!")
            .setContentText("إشارة المودم ضعيفة جداً. تأكد أنك لم تنسه!")
            .setSmallIcon(R.drawable.ic_notification) // Use existing icon
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true) // Wakes up screen
            .setVibrate(longArrayOf(0, 1000, 500, 1000, 500, 1000))
            .addAction(android.R.drawable.ic_media_pause, "إيقاف الإنذار 🔕", stopPendingIntent)
            .setAutoCancel(true)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(9003, notification)
    }

    private fun createStatusNotification(text: String): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("حماية من فقدان المودم مفعلة")
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun stopAlarm() {
        isAlerting = false
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(9003) // إغلاق إشعار الإنذار
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            
            // Status Channel (Silent)
            val serviceChannel = NotificationChannel(
                CHANNEL_ID, 
                "Anti-Loss Status", 
                NotificationManager.IMPORTANCE_LOW
            )
            manager?.createNotificationChannel(serviceChannel)
            
            // Alert Channel (Loud!)
            val alertChannel = NotificationChannel(
                ALERT_CHANNEL_ID, 
                "Anti-Loss Alerts", 
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Critical alerts when modem is left behind"
                setSound(null, null) // الصوت يتم تشغيله برمجياً عبر MediaPlayer
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 1000, 500, 1000, 500, 1000)
            }
            manager?.createNotificationChannel(alertChannel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.d("AntiLossService", "🛑 Anti-Loss Service Stopped")
        isRunning = false
        handler.removeCallbacks(monitorRunnable)
        stopAlarm()
        super.onDestroy()
    }
}
