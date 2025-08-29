package com.bananapie.klaviyo_sdk

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.klaviyo.analytics.Klaviyo
import com.klaviyo.pushFcm.KlaviyoNotification
import com.klaviyo.pushFcm.KlaviyoRemoteMessage.isKlaviyoNotification
import com.klaviyo.pushFcm.KlaviyoRemoteMessage.hasKlaviyoKeyValuePairs
import com.klaviyo.pushFcm.KlaviyoRemoteMessage.isKlaviyoMessage
import android.content.Intent
import android.util.Log

class KlaviyoFirebaseMessagingService : FirebaseMessagingService() {

    override fun onNewToken(newToken: String) {
        super.onNewToken(newToken)
        Klaviyo.setPushToken(newToken)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        val notification = message.notification
        val title = notification?.title
        val body = notification?.body
        val dataMap = message.data
        val dataString = if (dataMap.isNullOrEmpty()) "{}" else dataMap.toString()


        // This extension method allows you to distinguish Klaviyo from other sources
        if (message.isKlaviyoMessage) {
             if (message.isKlaviyoNotification) {
                // Handle displaying a notification from Klaviyo
                KlaviyoNotification(message).displayNotification(this)
                
                // Send notification data to Flutter via event channel
                val notificationData = mapOf(
                    "type" to "klaviyo_notification_received",
                    "title" to message.notification?.title,
                    "body" to message.notification?.body,
                    "messageId" to message.messageId,
                    "timestamp" to System.currentTimeMillis()
                ).plus(message.data ?: emptyMap())
                
                sendEventToFlutter(notificationData)
             }
             if (message.hasKlaviyoKeyValuePairs) {
                // Send custom data to Flutter
                val customData = mapOf(
                    "type" to "klaviyo_custom_data_received",
                    "messageId" to message.messageId,
                    "timestamp" to System.currentTimeMillis()
                ).plus(message.data ?: emptyMap())
                
                sendEventToFlutter(customData)
             }
        } else {
             // Send non-Klaviyo message data to Flutter
             val nonKlaviyoData = mapOf(
                 "type" to "non_klaviyo_message_received",
                 "title" to message.notification?.title,
                 "body" to message.notification?.body,
                 "messageId" to message.messageId,
                 "from" to message.from,
                 "timestamp" to System.currentTimeMillis()
             ).plus(message.data ?: emptyMap())
             
             sendEventToFlutter(nonKlaviyoData)
        }
    }
    
    private fun sendEventToFlutter(data: Map<String, Any?>) {
        try {
            Log.d("KlaviyoFCM", "sendEventToFlutter called with data: $data")
            
            // Get the plugin instance and send event to Flutter via method channel
            val pluginInstance = KlaviyoSdkPlugin.getInstance()
            Log.d("KlaviyoFCM", "Plugin instance: $pluginInstance")
            
            pluginInstance?.let { plugin ->
                Log.d("KlaviyoFCM", "Plugin instance found, sending push notification to Flutter")
                // Use the new method channel approach instead of event channel
                plugin.sendPushNotificationToFlutter(data)
                Log.d("KlaviyoFCM", "Push notification sent to Flutter successfully")
            } ?: run {
                Log.w("KlaviyoFCM", "Plugin instance not available, cannot send event to Flutter")
            }
        } catch (e: Exception) {
            Log.e("KlaviyoFCM", "Error sending event to Flutter", e)
        }
    }
}