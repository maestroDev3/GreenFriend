package de.maestrodev.green_friend

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        LightSensorHandler(applicationContext)
            .register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
