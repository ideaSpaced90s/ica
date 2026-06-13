package com.dsamok.ideaspacechess

import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val PATH_CHANNEL = "com.dsamok.ideaspacechess/native_path"
    private val DEVICE_CHANNEL = "com.dsamok.ideaspacechess/device_info"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val isPlayGamesPC = packageManager.hasSystemFeature("com.google.android.play.feature.HPE_EXPERIENCE")
        val isChromebook = packageManager.hasSystemFeature("org.chromium.arc.device_management")
        
        if (!isPlayGamesPC && !isChromebook) {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PATH_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getNativeLibraryDir") {
                result.success(applicationInfo.nativeLibraryDir)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isPlayGamesPC") {
                val isPC = packageManager.hasSystemFeature("com.google.android.play.feature.HPE_EXPERIENCE")
                result.success(isPC)
            } else {
                result.notImplemented()
            }
        }
    }
}
