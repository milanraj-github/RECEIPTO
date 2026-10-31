package com.receipto.receipto

import android.os.Build
import android.content.Context
import android.os.PowerManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.receipto.receipto/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getManufacturer" -> {
                    result.success(Build.MANUFACTURER)
                }
                "isBatteryOptimized" -> {
                    val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                    val name = packageName
                    val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        powerManager.isIgnoringBatteryOptimizations(name)
                    } else {
                        true
                    }
                    result.success(!isIgnoring)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
