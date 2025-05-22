import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'klaviyo_sdk_platform_interface.dart';

class KlaviyoSdk {
  KlaviyoSdk._();

  static final KlaviyoSdk _instance = KlaviyoSdk._();

  bool _initialized = false;

  /// get the instance of the [KlaviyoSdk].
  static KlaviyoSdk get instance => _instance;

  Future<String?> getPlatformVersion() {
    return KlaviyoSdkPlatform.instance.getPlatformVersion();
  }

  /// Initialize the Klaviyo SDK with your public API key
  Future<bool> initialize(String apiKey) async {
    try {
      final success = await KlaviyoSdkPlatform.instance.initialize(apiKey);
      KlaviyoSdkPlatform.instance.setupNativeMethodCalls(_handleMethodCall);

      if (success) {
        _initialized = true;
        debugPrint("Klaviyo SDK: KlaviyoSdk initialized successfully");
      } else {
        debugPrint("Klaviyo SDK: KlaviyoSdk initialization returned false");
      }
      return success;
    } catch (e) {
      debugPrint("Klaviyo SDK: Error initializing KlaviyoSdk: $e");
      return false;
    }
  }

  /// Set a profile for identification
  Future<bool> setProfile({
    String? email,
    String? phoneNumber,
    String? externalId,
    String? firstName,
    String? lastName,
    Map<String, dynamic>? properties,
  }) async {
    try {
      if (!_initialized) {
        debugPrint(
            "Klaviyo SDK: Warning! KlaviyoSdk not initialized before setProfile call");
      }

      final success = await KlaviyoSdkPlatform.instance.setProfile(
        email: email,
        phoneNumber: phoneNumber,
        externalId: externalId,
        firstName: firstName,
        lastName: lastName,
        properties: properties,
      );

      if (success) {
        debugPrint("Klaviyo SDK: Profile set successfully");
      } else {
        debugPrint("Klaviyo SDK: Setting profile returned false");
      }

      return success;
    } catch (e) {
      debugPrint("Klaviyo SDK: Error setting profile: $e");
      return false;
    }
  }

  /// Reset the current profile
  Future<bool> resetProfile() async {
    try {
      if (!_initialized) {
        debugPrint(
            "Klaviyo SDK: Warning! KlaviyoSdk not initialized before resetProfile call");
      }

      final success = await KlaviyoSdkPlatform.instance.resetProfile();

      if (success) {
        debugPrint("Klaviyo SDK: Profile reset successfully");
      } else {
        debugPrint("Klaviyo SDK: Resetting profile returned false");
      }

      return success;
    } catch (e) {
      debugPrint("Klaviyo SDK: Error resetting profile: $e");
      return false;
    }
  }

  /// Track an event
  Future<bool> createEvent({
    required String name,
    Map<String, dynamic>? properties,
    double? value,
  }) async {
    try {
      if (!_initialized) {
        debugPrint(
            "Klaviyo SDK: Warning! KlaviyoSdk not initialized before createEvent call");
      }

      final success = await KlaviyoSdkPlatform.instance.createEvent(
        name: name,
        properties: properties,
        value: value,
      );

      if (success) {
        debugPrint("Klaviyo SDK: Event '$name' created successfully");
      } else {
        debugPrint("Klaviyo SDK: Creating event '$name' returned false");
      }

      return success;
    } catch (e) {
      debugPrint("Klaviyo SDK: Error creating event '$name': $e");
      return false;
    }
  }

  /// Register for push notifications
  Future<bool> registerForPushNotifications() async {
    try {
      if (!_initialized) {
        debugPrint(
            "Klaviyo SDK: Warning! KlaviyoSdk not initialized before registerForPushNotifications call");
      }

      final success =
          await KlaviyoSdkPlatform.instance.registerForPushNotifications();

      if (success) {
        debugPrint(
            "Klaviyo SDK: Registered for push notifications successfully");
      } else {
        debugPrint(
            "Klaviyo SDK: Registering for push notifications returned false");
      }

      return success;
    } catch (e) {
      debugPrint("Klaviyo SDK: Error registering for push notifications: $e");
      return false;
    }
  }

  /// Set the push token for the device
  /// Set the push token for the device
  ///
  /// For iOS, pass the APNS token converted to a hex string.
  /// For Android, pass the FCM token as received from Firebase.
  Future<bool> setPushToken(String token) async {
    try {
      if (!_initialized) {
        debugPrint(
            "Klaviyo SDK: Warning! KlaviyoSdk not initialized before setPushToken call");
      }

      final success = await KlaviyoSdkPlatform.instance.setPushToken(token);

      if (success) {
        debugPrint("Klaviyo SDK: Push token set successfully");
      } else {
        debugPrint("Klaviyo SDK: Setting push token returned false");
      }

      return success;
    } catch (e) {
      debugPrint("Klaviyo SDK: Error setting push token: $e");
      return false;
    }
  }

  Future<void> handlePush(Map<String, dynamic>? data) async {
    try {
      if (!_initialized) {
        debugPrint(
            "Klaviyo SDK: Warning! KlaviyoSdk not initialized before handlePush call");
      }

      final success = await KlaviyoSdkPlatform.instance.handlePush(data);

      if (success) {
        debugPrint("Klaviyo SDK: Push notification handled successfully");
      }
    } catch (e) {
      debugPrint("Klaviyo SDK: Error handling push notification: $e");
    }
  }

  // Handle method calls from the native layer
  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onDeepLinkReceived') {
      final deepLink = call.arguments['deepLink'];
      debugPrint("Klaviyo SDK: Deep link received: $deepLink");
    } else if (call.method == 'onPushTokenReceived') {
      final token = call.arguments['token'];
      debugPrint("Klaviyo SDK: Push token received: $token");
    }
  }
}
