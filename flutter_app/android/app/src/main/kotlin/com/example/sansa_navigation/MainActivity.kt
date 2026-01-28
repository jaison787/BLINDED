package com.example.sansa_navigation

import android.Manifest
import android.content.pm.PackageManager
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "emergency_sms"
    private val SMS_PERMISSION_CODE = 101

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "sendSms" -> {
                    val number = call.argument<String>("number")
                    val message = call.argument<String>("message")

                    if (ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.SEND_SMS
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.SEND_SMS),
                            SMS_PERMISSION_CODE
                        )
                        result.error("NO_PERMISSION", "SMS permission not granted", null)
                        return@setMethodCallHandler
                    }

                    try {
                        SmsManager.getDefault().sendTextMessage(
                            number,
                            null,
                            message,
                            null,
                            null
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
