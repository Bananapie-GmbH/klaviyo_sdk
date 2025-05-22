package com.example.klaviyo_sdk_example

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import com.bananapie.klaviyo_sdk.KlaviyoNotificationHelper

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        onNewIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        // Check if app was launched from notification
        KlaviyoNotificationHelper.checkForNotificationLaunch(applicationContext, intent)
    }
} 