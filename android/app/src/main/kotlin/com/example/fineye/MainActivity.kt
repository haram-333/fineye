package com.example.fineye

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.fineye/security"
    private var screenPrivacyEnabled = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "enableScreenPrivacy" -> {
                    enableScreenPrivacy()
                    result.success(true)
                }
                "disableScreenPrivacy" -> {
                    disableScreenPrivacy()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun enableScreenPrivacy() {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        screenPrivacyEnabled = true
    }

    private fun disableScreenPrivacy() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        screenPrivacyEnabled = false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Apply screen privacy if needed (load from preferences in actual implementation)
    }
}
