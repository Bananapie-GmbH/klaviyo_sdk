package com.bananapie.klaviyo_sdk

import android.content.Intent
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.klaviyo.analytics.Klaviyo
import com.klaviyo.pushFcm.KlaviyoRemoteMessage
import com.klaviyo.pushFcm.KlaviyoPushService

class KlaviyoFirebaseMessagingService : KlaviyoPushService() {
    private val TAG = "KlaviyoFCM"

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        Log.d(TAG, "Klaviyo SDK onMessageReceived: ${message.from}")

        try {
            // Check if message contains a data payload
            if (message.data.isNotEmpty()) {
                Log.d(TAG, "Message data payload: ${message.data}")
                
                // Forward to our plugin if available
                val plugin = KlaviyoSdkPlugin.getInstance()
                if (plugin != null) {
                    plugin.handleRemoteMessage(message, true)
                } else {
                    Log.e(TAG, "Klaviyo SDK Plugin instance not available")
                }
            }

            // Check if message contains a notification payload
            message.notification?.let {
                Log.d(TAG, "Klaviyo SDK onMessageReceived: Message Notification Body: ${it.body}")
                
                // Even if there's no data payload, we should still forward notification-only messages
                val plugin = KlaviyoSdkPlugin.getInstance()
                if (plugin != null) {
                    plugin.handleRemoteMessage(message, true)
                } else {
                    Log.e(TAG, "Klaviyo SDK Plugin instance not available")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Klaviyo SDK Error handling message: ${e.message}", e)
        }
    }

    override fun onKlaviyoNotificationMessageReceived(message: RemoteMessage) {
        Log.d(TAG, "Klaviyo SDK onKlaviyoNotificationMessageReceived: $message")
        
        // Forward to our plugin if available
        val plugin = KlaviyoSdkPlugin.getInstance()
        if (plugin != null) {
            plugin.handleRemoteMessage(message, true)
        } else {
            Log.e(TAG, "Klaviyo SDK Plugin instance not available")
        }
    }

    override fun onKlaviyoCustomDataMessageReceived(customData: Map<String, String>, message: RemoteMessage) {
        Log.d(TAG, "Klaviyo SDK onKlaviyoCustomDataMessageReceived: $customData")
        
        // Forward to our plugin if available
        val plugin = KlaviyoSdkPlugin.getInstance()
        if (plugin != null) {
            plugin.handleRemoteMessage(message, true)
        } else {
            Log.e(TAG, "Klaviyo SDK Plugin instance not available")
        }
    }

    override fun onNewToken(newToken: String) {
        super.onNewToken(newToken)
        Log.d(TAG, "Klaviyo SDK onNewToken: $newToken")
        
        try {
            // Send token to Klaviyo
            Klaviyo.setPushToken(newToken)
            
            // Forward to our plugin if available
            val plugin = KlaviyoSdkPlugin.getInstance()
            if (plugin != null) {
                plugin.handleFcmToken(newToken)
            } else {
                Log.e(TAG, "Klaviyo SDK Plugin instance not available for token handling")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Klaviyo SDK Error handling new token: ${e.message}", e)
        }
    }
} 