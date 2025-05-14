package com.bananapie.klayvio_sdk

import androidx.annotation.NonNull
import com.klaviyo.analytics.Klaviyo
import com.klaviyo.analytics.model.Event
import com.klaviyo.analytics.model.Profile

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** KlayvioSdkPlugin */
class KlayvioSdkPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var klaviyo: Klaviyo
  private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "klayvio_sdk")
    channel.setMethodCallHandler(this)
    
    // Initialize Klaviyo instance
    klaviyo = Klaviyo.getInstance()
    flutterPluginBinding = binding
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
            klaviyo.initialize(apiKey, flutterPluginBinding.applicationContext)
            result.success(true)
          } else {
            result.error("INVALID_ARGUMENTS", "API key is required", null)
          }
        }
        "setProfile" -> {
          val email = call.argument<String>("email")
          val phoneNumber = call.argument<String>("phoneNumber")
          val externalId = call.argument<String>("externalId")
          val firstName = call.argument<String>("firstName")
          val lastName = call.argument<String>("lastName")
          val properties = call.argument<Map<String, Any>>("properties")
          
          // Create a profile using the Builder pattern
          val profileBuilder = Profile.Builder()
          
          email?.let { profileBuilder.setEmail(it) }
          phoneNumber?.let { profileBuilder.setPhoneNumber(it) }
          externalId?.let { profileBuilder.setExternalId(it) }
          firstName?.let { profileBuilder.setFirstName(it) }
          lastName?.let { profileBuilder.setLastName(it) }
          
          properties?.forEach { (key, value) ->
            profileBuilder.addProperty(key, value)
          }
          
          // Set the profile
          klaviyo.setProfile(profileBuilder.build())
          result.success(true)
        }
        "resetProfile" -> {
          // Reset the current profile
          klaviyo.resetProfile()
          result.success(true)
        }
        "createEvent" -> {
          val name = call.argument<String>("name")
          val properties = call.argument<Map<String, Any>>("properties") ?: mapOf()
          val value = call.argument<Double>("value")
          
          if (name != null) {
            // Create an event using the Builder pattern
            val eventBuilder = Event.Builder(name)
            
            properties.forEach { (key, value) ->
              eventBuilder.addProperty(key, value)
            }
            
            value?.let { eventBuilder.setValue(it) }
            
            // Create the event
            klaviyo.createEvent(eventBuilder.build())
            result.success(true)
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
            klaviyo.setPushToken(token)
            result.success(true)
          } else {
            result.error("INVALID_ARGUMENTS", "Push token is required", null)
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
    channel.setMethodCallHandler(null)
  }
}
