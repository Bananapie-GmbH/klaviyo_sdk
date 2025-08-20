package com.bananapie.klaviyo_sdk

import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.Serializable
import kotlin.reflect.KVisibility

// Klaviyo SDK imports
import com.klaviyo.analytics.Klaviyo
import com.klaviyo.analytics.model.Event
import com.klaviyo.analytics.model.EventKey
import com.klaviyo.analytics.model.EventMetric
import com.klaviyo.analytics.model.Keyword
import com.klaviyo.analytics.model.Profile
import com.klaviyo.analytics.model.ProfileKey
 

/**
 * Flutter plugin bridging Klaviyo Android SDK via MethodChannel/EventChannel.
 */
class KlaviyoSdkPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler, ActivityAware {

    companion object {
        private const val METHOD_CHANNEL_NAME = "klaviyo_sdk"
        private const val EVENT_CHANNEL_NAME = "klaviyo_sdk/notification_events"

        private const val LOCATION = "location"
        private const val PROPERTIES = "properties"
        
        // Static reference to the plugin instance for MainActivity access
        @JvmStatic
        private var instance: KlaviyoSdkPlugin? = null
        
        @JvmStatic
        fun getInstance(): KlaviyoSdkPlugin? = instance

        
        /**
         * Handle push notification intent for tracking opens.
         * Similar to iOS handleNotificationResponse method.
         * This can be called from MainActivity if automatic handling is not sufficient.
         * 
         * Example usage in MainActivity:
         * ```
         * override fun onCreate(savedInstanceState: Bundle?) {
         *     super.onCreate(savedInstanceState)
         *     // ... other initialization code
         *     
         *     // Handle intent if app was launched from notification
         *     KlaviyoSdkPlugin.handlePushIntentFromActivity(intent)
         * }
         * 
         * override fun onNewIntent(intent: Intent?) {
         *     super.onNewIntent(intent)
         *     // Handle new intent (e.g., from notification tap)
         *     KlaviyoSdkPlugin.handlePushIntentFromActivity(intent)
         * }
         * ```
         */
        @JvmStatic
        fun handlePushIntent(intent: Intent?) {
            instance?.let { plugin ->
                try {
                    // Call Klaviyo SDK to track push notification opens
                    Klaviyo.handlePush(intent)
                    
                    // Extract notification data and emit to event stream
                    intent?.extras?.let { extras ->
                        val payload = mutableMapOf<String, Any?>()
                        for (key in extras.keySet()) {
                            val value = extras.get(key)
                            if (value is Serializable) {
                                payload[key] = value
                            }
                        }
                        plugin.eventSink?.success(payload)
                    }
                } catch (e: Exception) {
                    Log.e("KlaviyoSDK", "Error handling push intent from activity", e)
                }
            }
        }
        
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private var activity: Activity? = null
    private var applicationContext: Context? = null


    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)
        
        // Set static instance for MainActivity access
        instance = this

        // Keep a reference to Application Context for initialization
        applicationContext = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        
        // Clear static instance
        instance = null

        applicationContext = null
    }

    // EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            "initialize" -> {
                val apiKey: String? = call.argument("apiKey")
                if (apiKey.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENT", "apiKey is required", null)
                    return
                }
                try {
                    // Prefer engine Application Context; fall back to Activity context if available
                    val context = applicationContext ?: activity?.applicationContext
                    if (context == null) {
                        result.error("NO_CONTEXT", "Application context is not available", null)
                        return
                    }
                    Klaviyo.initialize(apiKey, context)
                    result.success(true)
                } catch (t: Throwable) {
                    result.error("INIT_ERROR", t.message, null)
                }
            }
            "setProfile" -> {
                try {
                    val args: Map<String, Any?> = call.arguments as? Map<String, Any?> ?: emptyMap()
                    setProfileInternal(args)
                    result.success(true)
                } catch (t: Throwable) {
                    result.error("PROFILE_ERROR", t.message, null)
                }
            }
            "resetProfile" -> {
                try {
                    Klaviyo.resetProfile()
                    result.success(true)
                } catch (t: Throwable) {
                    result.error("RESET_ERROR", t.message, null)
                }
            }
            "createEvent" -> {
                try {
                    val name: String? = call.argument("name")
                    if (name.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "name is required", null)
                        return
                    }
                    val properties: Map<String, Any?>? = call.argument("properties")
                    val value: Double? = call.argument("value")

                    val event = Event(
                        metric = EventMetric.CUSTOM(name),
                        properties = properties?.mapNotNull { (key, v) ->
                            if (v is Serializable) EventKey.CUSTOM(key) as EventKey to v else null
                        }?.toMap()
                    )
                    if (value != null) {
                        event.setValue(value)
                    }
                    Klaviyo.createEvent(event)
                    result.success(true)
                } catch (t: Throwable) {
                    result.error("EVENT_ERROR", t.message, null)
                }
            }
            "registerForPushNotifications" -> {
                // Android: push registration typically handled by FCM automatically.
                result.success(true)
            }
            "setPushToken" -> {
                try {
                    val token: String? = call.argument("token")
                    if (token.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "token is required", null)
                        return
                    }
                    Klaviyo.setPushToken(token)
                    result.success(true)
                } catch (t: Throwable) {
                    result.error("PUSH_TOKEN_ERROR", t.message, null)
                }
            }
            // Convenience attribute methods used by Dart layer
            "setExternalId" -> {
                val value: String? = call.argument("value")
                if (value.isNullOrEmpty()) return result.error("INVALID_ARGUMENT", "value is required", null)
                Klaviyo.setExternalId(value)
                result.success(null)
            }
            "getExternalId" -> {
                result.success(Klaviyo.getExternalId())
            }
            "setEmail" -> {
                val value: String? = call.argument("value")
                if (value.isNullOrEmpty()) return result.error("INVALID_ARGUMENT", "value is required", null)
                Klaviyo.setEmail(value)
                result.success(null)
            }
            "getEmail" -> {
                result.success(Klaviyo.getEmail())
            }
            "setPhoneNumber" -> {
                val value: String? = call.argument("value")
                if (value.isNullOrEmpty()) return result.error("INVALID_ARGUMENT", "value is required", null)
                Klaviyo.setPhoneNumber(value)
                result.success(null)
            }
            "getPhoneNumber" -> {
                result.success(Klaviyo.getPhoneNumber())
            }
            "setProfileAttribute" -> {
                val key: String? = call.argument("propertyKey")
                val value: String? = call.argument("value")
                if (key.isNullOrEmpty() || value == null) return result.error("INVALID_ARGUMENT", "propertyKey and value are required", null)
                Klaviyo.setProfileAttribute(ProfileKey.CUSTOM(key), value)
                result.success(null)
            }
            "getPushToken" -> {
                result.success(Klaviyo.getPushToken())
            }
            "setBadgeCount" -> {
                // Android generally doesn't support app icon badges natively; no-op
                result.success(null)
            }
            "getEventTypesKeys" -> {
                result.success(extractConstants<EventMetric>())
            }
            "getProfilePropertyKeys" -> {
                val profileKeys = extractConstants<ProfileKey>().toMutableMap()
                profileKeys[LOCATION] = LOCATION
                profileKeys[PROPERTIES] = PROPERTIES
                result.success(profileKeys)
            }
            // TODO: add in-app forms support
            // Optional: in-app forms support similar to RN module
            // "registerForInAppForms" -> {
            //     // No-op without forms dependency
            //     result.success(true)
            // }
            // "unregisterFromInAppForms" -> {
            //     runOnMainThread {
            //         try {
            //             // No-op without forms dependency
            //         } finally {
            //             result.success(true)
            //         }
            //     }
            // }
            else -> result.notImplemented()
        }
    }

    private fun runOnMainThread(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            Handler(Looper.getMainLooper()).post { block() }
        }
    }

    // ActivityAware to keep current activity reference (for push intents or future use)
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun setProfileInternal(args: Map<String, Any?>) {
        val profile = Profile()

        // Flatten nested LOCATION and PROPERTIES maps into the profile
        args.forEach { (key, value) ->
            when (key) {
                LOCATION, PROPERTIES -> {
                    @Suppress("UNCHECKED_CAST")
                    (value as? Map<String, Any?>)?.forEach { (innerKey, innerValue) ->
                        if (innerValue is Serializable) {
                            profile[innerKey] = innerValue
                        }
                    }
                }
                else -> {
                    if (value is Serializable) {
                        // For known fields we could map to typed keys, but the SDK accepts custom keys by string
                        profile[key] = value
                    }
                }
            }
        }

        Klaviyo.setProfile(profile)
    }

    private inline fun <reified T> extractConstants(): Map<String, String> where T : Keyword =
        T::class
            .nestedClasses
            .filter { it.visibility == KVisibility.PUBLIC && it.objectInstance is T }
            .associate { nested ->
                val key = nested.simpleName.toString()
                val value = (nested.objectInstance as T).name
                key to value
            }
}


