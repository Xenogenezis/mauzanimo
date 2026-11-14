package com.mauzanimo.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createRescueAlertsChannel()
    }

    // Channel used by rescue push notifications (the notifyNearbyRescuers
    // Cloud Function sends with channelId "rescue_alerts"). Creating a
    // channel that already exists is a no-op.
    private fun createRescueAlertsChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "rescue_alerts",
            "Rescue alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Rescue requests near the area you chose"
        }
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }
}
