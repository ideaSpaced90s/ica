package com.dsamok.ideaspacechess

import android.content.pm.ActivityInfo
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val PATH_CHANNEL = "com.dsamok.ideaspacechess/native_path"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
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
    }
}
