package com.bananapie.klaviyo_sdk

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.klaviyo.analytics.Klaviyo

object KlaviyoNotificationHelper {
    private const val TAG = "KlaviyoNotification"
    
    /**
     * Check if the app was launched from a Klaviyo notification and handle it
     */
    @JvmStatic
    fun checkForNotificationLaunch(context: Context, intent: Intent?) {
        if (intent == null) return
        
        try {
            // Check if this is a Klaviyo intent
           
            // Let Klaviyo handle the intent
            Klaviyo.handlePush(intent)
            
            // Create notification data
            val notificationData = formatNotificationDataFromIntent(intent, true)
            
            // Set as initial notification
            KlaviyoSdkPlugin.getInstance()?.setInitialNotification(notificationData)
        
        } catch (e: Exception) {
            Log.e(TAG, "Error handling notification launch: ${e.message}", e)
        }
    }
    
    /**
     * Format notification data from intent
     */
    private fun formatNotificationDataFromIntent(intent: Intent, fromTerminated: Boolean): Map<String, Any> {
        val data = mutableMapOf<String, Any>()
        val extras = intent.extras ?: Bundle.EMPTY
        
        // Extract notification data
        val customData = mutableMapOf<String, Any>()
        extras.keySet().forEach { key ->
            extras.get(key)?.let { value ->
                if (value is String || value is Boolean || value is Number) {
                    customData[key] = value
                }
            }
        }
        
        // Build notification data
        data["data"] = customData
        data["title"] = extras.getString("title", "")
        data["body"] = extras.getString("body", "")
        data["fromBackground"] = true
        data["fromTerminated"] = fromTerminated
        
        return data
    }
} 