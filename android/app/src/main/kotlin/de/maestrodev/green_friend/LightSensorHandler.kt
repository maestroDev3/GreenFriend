package de.maestrodev.green_friend

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** Streams the ambient light sensor (lux) to Dart (`ChannelLightSensor`). */
class LightSensorHandler(context: Context) : EventChannel.StreamHandler, SensorEventListener {
    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val sensor: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)
    private var events: EventChannel.EventSink? = null

    fun register(messenger: BinaryMessenger) {
        EventChannel(messenger, LUX_CHANNEL).setStreamHandler(this)
        MethodChannel(messenger, INFO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(sensor != null)
                else -> result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        val light = sensor
        if (light == null) {
            sink.error("no_sensor", "This phone has no light sensor", null)
            return
        }
        events = sink
        sensorManager.registerListener(this, light, SensorManager.SENSOR_DELAY_NORMAL)
    }

    override fun onCancel(arguments: Any?) {
        sensorManager.unregisterListener(this)
        events = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        events?.success(event.values[0].toDouble())
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    companion object {
        const val LUX_CHANNEL = "de.maestrodev.green_friend/light"
        const val INFO_CHANNEL = "de.maestrodev.green_friend/light_info"
    }
}
