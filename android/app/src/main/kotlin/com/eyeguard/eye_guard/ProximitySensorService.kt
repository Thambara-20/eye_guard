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

class ProximitySensorService : Service(), SensorEventListener {
    private lateinit var sensorManager: SensorManager
    private var proximitySensor: Sensor? = null
    private lateinit var wakeLock: PowerManager.WakeLock
    private val binder = LocalBinder()

    companion object {
        const val CHANNEL_ID = "ProximitySensorServiceChannel"
        const val NOTIFICATION_ID = 2
        private var currentDistance: Float = 0.0f

        @JvmStatic
        fun getCurrentDistance(): Float {
            return currentDistance
        }
    }

    inner class LocalBinder : Binder() {
        fun getService(): ProximitySensorService = this@ProximitySensorService
    }

    override fun onCreate() {
        super.onCreate()
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "EyeGuard::ProximityWakeLock")
        wakeLock.acquire()
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        proximitySensor = sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("EyeGuard Proximity Active")
            .setContentText("Monitoring viewing distance")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setContentIntent(pendingIntent)
            .build()
        startForeground(NOTIFICATION_ID, notification)
        
        if (proximitySensor != null) {
            // Try with different sampling rates if the default fails
            val registrationSuccess = sensorManager.registerListener(
                this,
                proximitySensor,
                SensorManager.SENSOR_DELAY_NORMAL
            )
            
            if (!registrationSuccess) {
                // First retry with a different delay
                val retrySuccess = sensorManager.registerListener(
                    this,
                    proximitySensor,
                    SensorManager.SENSOR_DELAY_UI
                )
                
                if (!retrySuccess) {
                    // Second retry with an even different delay
                    val finalAttempt = sensorManager.registerListener(
                        this,
                        proximitySensor,
                        SensorManager.SENSOR_DELAY_GAME
                    )
                    
                    if (!finalAttempt) {
                        android.util.Log.e("ProximitySensorService", "Failed to register proximity sensor after multiple attempts")
                    }
                }
            }
        } else {
            android.util.Log.e("ProximitySensorService", "No proximity sensor available on this device")
            stopSelf()
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
        if (event.sensor.type == Sensor.TYPE_PROXIMITY) {
            currentDistance = event.values[0]
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID, "Proximity Sensor Service Channel", NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}
