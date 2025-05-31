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
    private val CHANNEL = "com.eyeguard.eye_guard/sensor"
    private val REQUEST_CODE_PERMISSIONS = 1001
    private var serviceIntent: Intent? = null
    private var serviceBound = false
    private var lightSensorService: LightSensorService? = null
    
    private val connection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            val binder = service as LightSensorService.LocalBinder
            lightSensorService = binder.getService()
            serviceBound = true
        }

        override fun onServiceDisconnected(arg0: ComponentName) {
            serviceBound = false
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {                "startLightSensorService" -> {
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
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        serviceIntent = Intent(this, LightSensorService::class.java)
    }

    private fun startLightSensorService() {
        serviceIntent?.let { intent ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent!!)
            } else {
                startService(intent!!)
            }
            bindService(intent!!, connection, Context.BIND_AUTO_CREATE)
        }
    }
    
    private fun stopLightSensorService() {
        if (serviceBound) {
            unbindService(connection)
            serviceBound = false
        }
        stopService(serviceIntent)
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
            }
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        if (serviceBound) {
            unbindService(connection)
            serviceBound = false
        }
    }
}
