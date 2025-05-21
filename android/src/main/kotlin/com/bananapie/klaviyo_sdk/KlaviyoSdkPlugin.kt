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
import java.io.Serializable
import com.google.firebase.messaging.RemoteMessage
import com.klaviyo.pushFcm.KlaviyoRemoteMessage.isKlaviyoMessage

private const val CHANNEL_NAME = "klaviyo_sdk"


/** KlaviyoSdkPlugin */
class KlaviyoSdkPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
  

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
    channel.setMethodCallHandler(this)
    flutterPluginBinding = binding
    context = binding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    try {
      when (call.method) {
        "getPlatformVersion" -> {
          result.success("Android ${android.os.Build.VERSION.RELEASE}")
        }
        "initialize" -> {
          val apiKey = call.argument<String>("apiKey")
          if (apiKey != null) {
            // Initialize Klaviyo with the API key and application context
            Klaviyo.initialize(apiKey, context)
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
            val propertyMap = mutableMapOf<ProfileKey, Serializable>()

            customProperties?.forEach { (key, value) ->
              propertyMap[ProfileKey.CUSTOM(key)] = value
            }

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
        "registerForPushNotifications" -> {
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
  }

  private fun convertMapToSeralizedMap(map: Map<String, Any>): Map<String, Serializable> {
    val convertedMap = mutableMapOf<String, Serializable>()

    for ((key, value) in map) {
        if (value is Serializable) {
            convertedMap[key] = value
        } else {
            // Handle non-serializable values here if needed
            // For example, you could skip them or throw an exception
            // depending on your requirements.
        }
    }

    return convertedMap
  }

}
