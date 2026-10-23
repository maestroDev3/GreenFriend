package de.maestrodev.green_friend

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var lightSensor: LightSensorHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        lightSensor = LightSensorHandler(applicationContext).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        lightSensor?.stop()
        lightSensor = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
