package com.example.klayvio_sdk

import androidx.annotation.NonNull
import com.klaviyo.analytics.Klaviyo
import com.klaviyo.analytics.model.Event
import com.klaviyo.analytics.model.EventKey
import com.klaviyo.analytics.model.Profile
import com.klaviyo.analytics.model.ProfileKey

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

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "klayvio_sdk")
    channel.setMethodCallHandler(this)
    
    // Initialize Klaviyo instance
    klaviyo = Klaviyo.getInstance()
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "initialize" -> {
        val apiKey = call.argument<String>("apiKey")
        if (apiKey != null) {
          klaviyo.initialize(apiKey)
          result.success(null)
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
        
        val profileBuilder = Profile.Builder()
        
        email?.let { profileBuilder.setEmail(it) }
        phoneNumber?.let { profileBuilder.setPhoneNumber(it) }
        externalId?.let { profileBuilder.setExternalId(it) }
        firstName?.let { profileBuilder.setFirstName(it) }
        lastName?.let { profileBuilder.setLastName(it) }
        
        properties?.forEach { (key, value) ->
          profileBuilder.addProperty(key, value)
        }
        
        klaviyo.setProfile(profileBuilder.build())
        result.success(null)
      }
      "resetProfile" -> {
        klaviyo.resetProfile()
        result.success(null)
      }
      "createEvent" -> {
        val name = call.argument<String>("name")
        val properties = call.argument<Map<String, Any>>("properties") ?: mapOf()
        val value = call.argument<Double>("value")
        
        if (name != null) {
          val eventBuilder = Event.Builder(name)
          
          properties.forEach { (key, value) ->
            eventBuilder.addProperty(key, value)
          }
          
          value?.let { eventBuilder.setValue(it) }
          
          klaviyo.createEvent(eventBuilder.build())
          result.success(null)
        } else {
          result.error("INVALID_ARGUMENTS", "Event name is required", null)
        }
      }
      "registerForPushNotifications" -> {
        // This is handled by the FCM integration
        // The app needs to request notification permissions and handle FCM token
        result.success(null)
      }
      "setPushToken" -> {
        val token = call.argument<String>("token")
        if (token != null) {
          klaviyo.setPushToken(token)
          result.success(null)
        } else {
          result.error("INVALID_ARGUMENTS", "Push token is required", null)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
} 