package com.eyeguard.eye_guard

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class LightSensorService : Service(), SensorEventListener {
    private lateinit var sensorManager: SensorManager
    private var lightSensor: Sensor? = null
    private lateinit var wakeLock: PowerManager.WakeLock
    private val binder = LocalBinder()

    companion object {
        const val CHANNEL_ID = "LightSensorServiceChannel"
        const val NOTIFICATION_ID = 1
        
        private var currentLuxValue: Float = 0.0f
        
        // Public method to get the current lux value
        @JvmStatic
        fun getCurrentLuxValue(): Float {
            return currentLuxValue
        }
    }
    
    inner class LocalBinder : Binder() {
        fun getService(): LightSensorService = this@LightSensorService
    }
    
    override fun onCreate() {
        super.onCreate()
        
        // Acquire wake lock to keep the service running in background
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "EyeGuard::LightSensorWakeLock"
        )
        wakeLock.acquire()
        
        // Initialize sensor manager and light sensor
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        lightSensor = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)
        
        createNotificationChannel()
    }
      override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("EyeGuard Active")
            .setContentText("Monitoring ambient light")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setContentIntent(pendingIntent)
            .build()
            
        startForeground(NOTIFICATION_ID, notification)
        
        // Register sensor listener with multiple retry attempts and sampling rate
        if (lightSensor != null) {
            // Try with different sampling rates if the default fails
            val registrationSuccess = sensorManager.registerListener(
                this,
                lightSensor,
                SensorManager.SENSOR_DELAY_NORMAL
            )
            
            if (!registrationSuccess) {
                // First retry with a different delay
                val retrySuccess = sensorManager.registerListener(
                    this,
                    lightSensor,
                    SensorManager.SENSOR_DELAY_UI
                )
                
                if (!retrySuccess) {
                    // Second retry with an even different delay
                    val finalAttempt = sensorManager.registerListener(
                        this,
                        lightSensor,
                        SensorManager.SENSOR_DELAY_GAME
                    )
                    
                    if (!finalAttempt) {
                        android.util.Log.e("LightSensorService", "Failed to register light sensor after multiple attempts")
                    }
                }
            }
        } else {
            // No light sensor available
            android.util.Log.e("LightSensorService", "No light sensor available on this device")
            stopSelf() // Stop service if no sensor is available
        }
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder {
        return binder
    }
    
    override fun onDestroy() {
        super.onDestroy()
        sensorManager.unregisterListener(this)
        if (wakeLock.isHeld) {
            wakeLock.release()
        }
    }
    
    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type == Sensor.TYPE_LIGHT) {
            val luxValue = event.values[0]
            currentLuxValue = luxValue
            
            // The value will be retrieved via the method channel in MainActivity
        }
    }
    
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not needed for this implementation
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Light Sensor Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}
