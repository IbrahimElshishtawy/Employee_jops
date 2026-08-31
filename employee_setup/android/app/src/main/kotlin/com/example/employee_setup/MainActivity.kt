package com.example.employee_setup

import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.cyberwise.employee/screen_security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkScreenSecurity" -> {
                    try {
                        var hasOverlayPermission = false
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            hasOverlayPermission = Settings.canDrawOverlays(this)
                        }

                        result.success(
                            mapOf(
                                "isSafe" to true,
                                "hasOverlayPermission" to hasOverlayPermission,
                                "filterTouchesEnabled" to true
                            )
                        )
                    } catch (e: Exception) {
                        result.error("SECURITY_CHECK_FAILED", e.message, null)
                    }
                }
                "setSecureFlag" -> {
                    val enable = call.argument<Boolean>("enable") ?: true
                    if (enable) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
