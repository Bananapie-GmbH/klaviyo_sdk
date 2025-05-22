package com.bananapie.klaviyo_sdk

import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import com.klaviyo.analytics.Klaviyo
import com.klaviyo.analytics.Klaviyo.isKlaviyoIntent
import com.klaviyo.analytics.model.Event
import com.klaviyo.analytics.model.EventKey
import com.klaviyo.analytics.model.EventMetric
import com.klaviyo.analytics.model.Profile
import com.klaviyo.analytics.model.ProfileKey

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import java.io.Serializable
import com.google.firebase.messaging.RemoteMessage
import com.klaviyo.pushFcm.KlaviyoRemoteMessage.isKlaviyoMessage
import java.util.concurrent.CopyOnWriteArrayList
import android.os.Handler
import android.os.Looper

private const val CHANNEL_NAME = "klaviyo_flutter"
private const val TOKEN_EVENT_CHANNEL = "klaviyo_flutter/token_events"
private const val NOTIFICATION_EVENT_CHANNEL = "klaviyo_flutter/notification_events"

/** KlaviyoSdkPlugin */
class KlaviyoSdkPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private lateinit var tokenEventChannel: EventChannel
  private lateinit var notificationEventChannel: EventChannel
  private lateinit var context: Context
  private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
  
  // Event sinks for streaming data to Flutter
  private var tokenEventSink: EventChannel.EventSink? = null
  private var notificationEventSink: EventChannel.EventSink? = null
  
  // Store pending background notifications
  private val pendingBackgroundNotifications = CopyOnWriteArrayList<Map<String, Any>>()
  
  // Store initial notification if app was launched from a notification
  private var initialNotification: Map<String, Any>? = null
  
  // Main thread handler for posting events to Flutter
  private val mainHandler = Handler(Looper.getMainLooper())

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
    channel.setMethodCallHandler(this)
    
    // Set up event channels
    tokenEventChannel = EventChannel(binding.binaryMessenger, TOKEN_EVENT_CHANNEL)
    tokenEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        tokenEventSink = events
      }
      
      override fun onCancel(arguments: Any?) {
        tokenEventSink = null
      }
    })
    
    notificationEventChannel = EventChannel(binding.binaryMessenger, NOTIFICATION_EVENT_CHANNEL)
    notificationEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        notificationEventSink = events
        deliverPendingNotifications()
      }
      
      override fun onCancel(arguments: Any?) {
        notificationEventSink = null
      }
    })
    
    flutterPluginBinding = binding
    context = binding.applicationContext
    
    // Set the static instance
    setInstance(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    try {
      when (call.method) {
        "initialize" -> {
          val apiKey = call.argument<String>("apiKey")
          if (apiKey != null) {
            // Initialize Klaviyo with the API key and application context
            Klaviyo.initialize(apiKey, context)
            Klaviyo.registerForLifecycleCallbacks(context)
            result.success(true)
          } else {
            result.error("INVALID_ARGUMENTS", "API key is required", null)
          }
        }
        "setProfile" -> {
          try {
            val profilePropertiesRaw = call.arguments<Map<String, Any>?>()

            if (profilePropertiesRaw == null) {
              result.error("Profile update error", "No properties passed", null)
              return
            }

            val profileProperties = convertMapToSeralizedMap(profilePropertiesRaw)

            val customProperties =
                    profileProperties["properties"] as Map<String, Serializable>?

            val email = profileProperties["email"] as? String
            val externalId = profileProperties["externalId"] as? String
            val phoneNumber = profileProperties["phoneNumber"] as? String
            val firstName = profileProperties["firstName"] as? String
            val lastName = profileProperties["lastName"] as? String
            val propertyMap = mutableMapOf<ProfileKey, Serializable>()

            customProperties?.forEach { (key, value) ->
              propertyMap[ProfileKey.CUSTOM(key)] = value
            }
            
            // Add firstName and lastName if provided
            firstName?.let { propertyMap[ProfileKey.FIRST_NAME] = it }
            lastName?.let { propertyMap[ProfileKey.LAST_NAME] = it }

            val profile = Profile(
              externalId = externalId,
              email = email,
              phoneNumber = phoneNumber,
              properties = if (propertyMap.isEmpty()) null else propertyMap
            )
          
            Klaviyo.setProfile(profile)

            result.success("Profile updated")
          } catch (e: Exception) {
            result.error("Profile update error", e.message, e)
          }
        }
        "resetProfile" -> {
          // Reset the current profile
          Klaviyo.resetProfile()
          result.success(true)
        }
        "createEvent" -> {
          val eventName = call.argument<String>("name")
          val metaDataRaw = call.argument<Map<String, Any>?>("properties")
          
          if (eventName != null && metaDataRaw != null) {
            val event = Event(EventMetric.CUSTOM(eventName))

            val metaData = convertMapToSeralizedMap(metaDataRaw)

            for (item in metaData) {
                event.setProperty(EventKey.CUSTOM(item.key), value = item.value)
            }
            Klaviyo.createEvent(event)

            result.success("Event[$eventName] created with metadataMap: $metaData")
          
          } else {
            result.error("INVALID_ARGUMENTS", "Event name is required", null)
          }
        }
        "requestPushPermissions" -> {
          // This is handled by the FCM integration
          // The app needs to request notification permissions and handle FCM token
          result.success(true)
        }
        "setPushToken" -> {
          val token = call.argument<String>("token")
          if (token != null) {
            // Set the push token
            Klaviyo.setPushToken(token)
            result.success(true)
          } else {
            result.error("INVALID_ARGUMENTS", "Push token is required", null)
          }
        }
        "getInitialNotification" -> {
          // Return and clear the initial notification
          result.success(initialNotification)
          initialNotification = null
        }
        "handlePush" -> {
          val payload = call.argument<Map<String, Any>?>("payload")

          if(payload != null) {
            val payloadData = convertMapToSeralizedMap(payload)
            val dataValue = payloadData["data"]
            val intentData = if (dataValue is Map<*, *>) {
                @Suppress("UNCHECKED_CAST")
                convertMapToSeralizedMap(dataValue as Map<String, Any>)
            } else {
                mapOf()
            }

            if(intentData.containsKey("_k")) {
              try {
                val intent = Intent()
                  .putExtra("com.klaviyo._k","")

                Klaviyo.handlePush(intent)
                result.success(true)
              } catch (e: Exception) {
                result.error("Push handle error", e.message, e)
              }
            }

            result.success(true)
          }
        }
        else -> {
          result.notImplemented()
        }
      }
    } catch (e: Exception) {
      val errorDetails = """
        Error: ${e.message}
        Stack trace: ${e.stackTraceToString()}
      """.trimIndent()
      result.error("KLAVIYO_ERROR", "Error in Klaviyo SDK: ${e.message}", errorDetails)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    flutterPluginBinding = null
    channel.setMethodCallHandler(null)
    tokenEventChannel.setStreamHandler(null)
    notificationEventChannel.setStreamHandler(null)
    
    // Clear the static instance if it's this instance
    if (getInstance() === this) {
      setInstance(null)
    }
  }

  private fun convertMapToSeralizedMap(map: Map<String, Any>): Map<String, Serializable> {
    val convertedMap = mutableMapOf<String, Serializable>()

    for ((key, value) in map) {
        if (value is Serializable) {
            convertedMap[key] = value
        } else if (value is Map<*, *>) {
            // Try to convert nested maps
            @Suppress("UNCHECKED_CAST")
            val nestedMap = convertMapToSeralizedMap(value as Map<String, Any>)
            convertedMap[key] = nestedMap as Serializable
        }
        // Skip non-serializable values
    }

    return convertedMap
  }
  
  // Handle FCM message and deliver to Flutter
  fun handleRemoteMessage(remoteMessage: RemoteMessage, fromBackground: Boolean = false) {
    // Format notification data
    val notificationData = formatNotificationData(remoteMessage, fromBackground)
    
    // Deliver to Flutter or store for later
    deliverNotification(notificationData)
    
  }
  
  // Format notification data for Flutter
  private fun formatNotificationData(remoteMessage: RemoteMessage, fromBackground: Boolean): Map<String, Any> {
    val data = mutableMapOf<String, Any>()
    
    // Add notification content if available
    remoteMessage.notification?.let { notification ->
      data["title"] = notification.title ?: ""
      data["body"] = notification.body ?: ""
    }
    
    // Add data payload
    data["data"] = remoteMessage.data
    
    // Add metadata
    data["fromBackground"] = fromBackground
    data["fromTerminated"] = false
    
    return data
  }
  
  // Deliver notification to Flutter or store for later
  private fun deliverNotification(notificationData: Map<String, Any>) {
    mainHandler.post {
      if (notificationEventSink != null) {
        notificationEventSink?.success(notificationData)
      } else {
        // Store for later delivery
        pendingBackgroundNotifications.add(notificationData)
      }
    }
  }
  
  // Deliver pending notifications when Flutter is ready
  private fun deliverPendingNotifications() {
    if (notificationEventSink == null || pendingBackgroundNotifications.isEmpty()) {
      return
    }
    
    mainHandler.post {
      for (notification in pendingBackgroundNotifications) {
        notificationEventSink?.success(notification)
      }
      pendingBackgroundNotifications.clear()
    }
  }
  
  // Set initial notification (called when app is launched from notification)
  fun setInitialNotification(notificationData: Map<String, Any>) {
    initialNotification = notificationData
  }
  
  // Handle FCM token and deliver to Flutter
  fun handleFcmToken(token: String) {
    // Set token in Klaviyo
    Klaviyo.setPushToken(token)
    
    // Format token data
    val tokenData = mapOf(
      "token" to token,
      "receivedAt" to System.currentTimeMillis()
    )
    
    // Deliver to Flutter
    mainHandler.post {
      tokenEventSink?.success(tokenData)
    }
  }

  companion object {
    // Static reference to the plugin instance for use in FCM service
    @JvmStatic
    private var instance: KlaviyoSdkPlugin? = null
    
    @JvmStatic
    fun getInstance(): KlaviyoSdkPlugin? {
      return instance
    }
    
    @JvmStatic
    fun setInstance(plugin: KlaviyoSdkPlugin?) {
      instance = plugin
    }
  }
}
