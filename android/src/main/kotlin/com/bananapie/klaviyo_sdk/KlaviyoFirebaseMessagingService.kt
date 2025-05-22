package com.bananapie.klaviyo_sdk

import android.content.Intent
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.klaviyo.analytics.Klaviyo
import com.klaviyo.pushFcm.KlaviyoRemoteMessage

class KlaviyoFirebaseMessagingService : FirebaseMessagingService() {
    private val TAG = "KlaviyoFCM"

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d(TAG, "From: ${remoteMessage.from}")

        // Check if message contains a data payload
        if (remoteMessage.data.isNotEmpty()) {
            Log.d(TAG, "Message data payload: ${remoteMessage.data}")
                        
            // Forward to our plugin if available
            val plugin = KlaviyoSdkPlugin.getInstance()
            plugin?.handleRemoteMessage(remoteMessage, true)
            
        }

        // Check if message contains a notification payload
        remoteMessage.notification?.let {
            Log.d(TAG, "Message Notification Body: ${it.body}")
        }
    }

    override fun onNewToken(token: String) {
        Log.d(TAG, "Refreshed FCM token: $token")
        
        // Send token to Klaviyo
        Klaviyo.setPushToken(token)
        
        // Forward to our plugin if available
        val plugin = KlaviyoSdkPlugin.getInstance()
        plugin?.handleFcmToken(token)
    }
} 