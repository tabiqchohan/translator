package com.tabiqchohan.translater

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ChatTranslatorPlugin().onAttach(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
        ChatTranslatorPlugin.setActivity(this)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        ChatTranslatorPlugin.setActivity(null)
        ChatTranslatorPlugin().onDetached(flutterEngine.dartExecutor.binaryMessenger)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}