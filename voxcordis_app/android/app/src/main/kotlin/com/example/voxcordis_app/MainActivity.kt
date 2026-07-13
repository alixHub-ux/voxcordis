package com.example.voxcordis_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.voxcordis_app/tflite"
    private var tflitePlugin: TflitePlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        tflitePlugin = TflitePlugin(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                tflitePlugin?.onMethodCall(call, result)
            }
    }

    override fun onDestroy() {
        tflitePlugin = null
        super.onDestroy()
    }
}
