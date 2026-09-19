package com.sam4g.app_settings

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Toast
import java.net.HttpURLConnection
import java.net.URL

/**
 * نشاط خفيف وشفاف (Transparent Dialog Activity) يعرض مربع تأكيد إعادة تشغيل المودم
 * مباشرة فوق الشاشة الرئيسية أو أي تطبيق يعمل، دون فتح تطبيق Linkary الرئيسي.
 * متوافق 100% مع معايير ومتطلبات Google Play الرسمية.
 */
class RebootConfirmActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        showConfirmationDialog()
    }

    private fun showConfirmationDialog() {
        val dialog = AlertDialog.Builder(this, android.R.style.Theme_DeviceDefault_Dialog_Alert)
            .setTitle("إعادة تشغيل المودم")
            .setMessage("هل أنت متأكد من رغبتك في إعادة تشغيل المودم؟ ستفقد الاتصال بالإنترنت لفترة وجيزة.")
            .setPositiveButton("إعادة التشغيل") { _, _ ->
                performReboot()
                finish()
            }
            .setNegativeButton("إلغاء") { _, _ ->
                finish()
            }
            .setOnCancelListener {
                finish()
            }
            .create()

        dialog.setCanceledOnTouchOutside(true)
        dialog.show()
    }

    private fun performReboot() {
        Toast.makeText(this, "جاري إرسال أمر إعادة تشغيل المودم...", Toast.LENGTH_SHORT).show()

        Thread {
            try {
                // 1. استخراج الـ Session ID من SharedPreferences
                val notifPrefs = getSharedPreferences(NotificationHelper.PREFS_NAME, Context.MODE_PRIVATE)
                var sessionId = notifPrefs.getString(WidgetActionReceiver.SESSION_ID_KEY, null)

                if (sessionId.isNullOrBlank()) {
                    val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    sessionId = flutterPrefs.getString(WidgetActionReceiver.SESSION_ID_KEY, null)
                }

                if (sessionId.isNullOrBlank()) {
                    Handler(Looper.getMainLooper()).post {
                        Toast.makeText(
                            this,
                            "يرجى فتح التطبيق وتسجيل الدخول أولاً لتفعيل أمر إعادة التشغيل.",
                            Toast.LENGTH_LONG
                        ).show()
                    }
                    return@Thread
                }

                // 2. إرسال طلب إعادة التشغيل المباشر للمودم
                val timestamp = System.currentTimeMillis()
                val url = URL("${WidgetActionReceiver.MODEM_BASE_URL}/api.cgi?path=router&method=router_call_reboot&timeout=20&_=$timestamp")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "GET"
                conn.connectTimeout = 5000
                conn.readTimeout = 5000
                conn.setRequestProperty("Accept", "application/json, text/javascript, */*; q=0.01")
                conn.setRequestProperty("X-Requested-With", "XMLHttpRequest")
                conn.setRequestProperty("Cookie", "CGISID=$sessionId")
                conn.setRequestProperty("reset_time", "1")

                val responseCode = conn.responseCode
                conn.disconnect()

                Handler(Looper.getMainLooper()).post {
                    if (responseCode in 200..299) {
                        Toast.makeText(this, "تم إرسال أمر إعادة التشغيل بنجاح", Toast.LENGTH_SHORT).show()
                    } else {
                        Toast.makeText(this, "تعذر إعادة التشغيل. يرجى التحقق من اتصالك بالمودم.", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                Log.e("RebootConfirm", "Error sending reboot command: ${e.message}")
                Handler(Looper.getMainLooper()).post {
                    Toast.makeText(this, "حدث خطأ في الاتصال بالمودم: ${e.localizedMessage ?: e.message}", Toast.LENGTH_SHORT).show()
                }
            }
        }.start()
    }
}
