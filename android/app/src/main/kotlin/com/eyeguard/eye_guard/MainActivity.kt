package com.eyeguard.eye_guard

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest

class MainActivity: FlutterActivity() {
    private val LIGHT_SENSOR_CHANNEL = "com.eyeguard.eye_guard/sensor"
    private val PROXIMITY_SENSOR_CHANNEL = "com.eyeguard.eye_guard/proximity"
    private val REQUEST_CODE_PERMISSIONS = 1001
    
    private var lightServiceIntent: Intent? = null
    private var proximityServiceIntent: Intent? = null
    
    private var lightServiceBound = false
    private var proximityServiceBound = false
    
    private var lightSensorService: LightSensorService? = null
    private var proximitySensorService: ProximitySensorService? = null
    
    private val lightServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            val binder = service as LightSensorService.LocalBinder
            lightSensorService = binder.getService()
            lightServiceBound = true
        }

        override fun onServiceDisconnected(arg0: ComponentName) {
            lightServiceBound = false
        }
    }
    
    private val proximityServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            val binder = service as ProximitySensorService.LocalBinder
            proximitySensorService = binder.getService()
            proximityServiceBound = true
        }

        override fun onServiceDisconnected(arg0: ComponentName) {
            proximityServiceBound = false
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Light sensor channel handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LIGHT_SENSOR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startLightSensorService" -> {
                    // Check if light sensor is available
                    val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
                    val lightSensor = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)
                    
                    if (lightSensor == null) {
                        result.error("NO_SENSOR", "Light sensor is not available on this device", null)
                        return@setMethodCallHandler
                    }
                    
                    if (checkAndRequestPermissions()) {
                        startLightSensorService()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stopLightSensorService" -> {
                    stopLightSensorService()
                    result.success(true)
                }
                "getCurrentLightValue" -> {
                    val value = LightSensorService.getCurrentLuxValue()
                    result.success(value)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Proximity sensor channel handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PROXIMITY_SENSOR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startProximitySensorService" -> {
                    // Check if proximity sensor is available
                    val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
                    val proximitySensor = sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)
                    
                    if (proximitySensor == null) {
                        result.error("NO_SENSOR", "Proximity sensor is not available on this device", null)
                        return@setMethodCallHandler
                    }
                    
                    if (checkAndRequestPermissions()) {
                        startProximitySensorService()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stopProximitySensorService" -> {
                    stopProximitySensorService()
                    result.success(true)
                }
                "getCurrentDistance" -> {
                    val value = ProximitySensorService.getCurrentDistance()
                    result.success(value)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        lightServiceIntent = Intent(this, LightSensorService::class.java)
        proximityServiceIntent = Intent(this, ProximitySensorService::class.java)
    }

    private fun startLightSensorService() {
        lightServiceIntent?.let { intent ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            bindService(intent, lightServiceConnection, Context.BIND_AUTO_CREATE)
        }
    }
    
    private fun stopLightSensorService() {
        if (lightServiceBound) {
            unbindService(lightServiceConnection)
            lightServiceBound = false
        }
        stopService(lightServiceIntent)
    }
    
    private fun startProximitySensorService() {
        proximityServiceIntent?.let { intent ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            bindService(intent, proximityServiceConnection, Context.BIND_AUTO_CREATE)
        }
    }
    
    private fun stopProximitySensorService() {
        if (proximityServiceBound) {
            unbindService(proximityServiceConnection)
            proximityServiceBound = false
        }
        stopService(proximityServiceIntent)
    }
    
    private fun checkAndRequestPermissions(): Boolean {
        val requiredPermissions = arrayOf(
            Manifest.permission.BODY_SENSORS,
            Manifest.permission.POST_NOTIFICATIONS
        )
        
        val permissionsToRequest = ArrayList<String>()
        
        for (permission in requiredPermissions) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(permission)
            }
        }
        
        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissionsToRequest.toTypedArray(),
                REQUEST_CODE_PERMISSIONS
            )
            return false
        }
        
        return true
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                startLightSensorService()
                startProximitySensorService()
            }
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        if (lightServiceBound) {
            unbindService(lightServiceConnection)
            lightServiceBound = false
        }
        if (proximityServiceBound) {
            unbindService(proximityServiceConnection)
            proximityServiceBound = false
        }
    }
}
