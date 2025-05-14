import 'dart:async';
import 'package:flutter/foundation.dart';
import 'klayvio_sdk_platform_interface.dart';

class KlayvioSdk {
  KlayvioSdk._();

  static final KlayvioSdk _instance = KlayvioSdk._();

  bool _initialized = false;

  /// get the instance of the [KlayvioSdk].
  static KlayvioSdk get instance => _instance;

  Future<String?> getPlatformVersion() {
    return KlayvioSdkPlatform.instance.getPlatformVersion();
  }

  /// Initialize the Klaviyo SDK with your public API key
  Future<bool> initialize(String apiKey) async {
    try {
      final success = await KlayvioSdkPlatform.instance.initialize(apiKey);
      if (success) {
        _initialized = true;
        debugPrint("Klayvio SDK: KlayvioSdk initialized successfully");
      } else {
        debugPrint("Klayvio SDK: KlayvioSdk initialization returned false");
      }
      return success;
    } catch (e) {
      debugPrint("Klayvio SDK: Error initializing KlayvioSdk: $e");
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
            "Klayvio SDK: Warning! KlayvioSdk not initialized before setProfile call");
      }

      final success = await KlayvioSdkPlatform.instance.setProfile(
        email: email,
        phoneNumber: phoneNumber,
        externalId: externalId,
        firstName: firstName,
        lastName: lastName,
        properties: properties,
      );

      if (success) {
        debugPrint("Klayvio SDK: Profile set successfully");
      } else {
        debugPrint("Klayvio SDK: Setting profile returned false");
      }

      return success;
    } catch (e) {
      debugPrint("Klayvio SDK: Error setting profile: $e");
      return false;
    }
  }

  /// Reset the current profile
  Future<bool> resetProfile() async {
    try {
      if (!_initialized) {
        debugPrint(
            "Klayvio SDK: Warning! KlayvioSdk not initialized before resetProfile call");
      }

      final success = await KlayvioSdkPlatform.instance.resetProfile();

      if (success) {
        debugPrint("Klayvio SDK: Profile reset successfully");
      } else {
        debugPrint("Klayvio SDK: Resetting profile returned false");
      }

      return success;
    } catch (e) {
      debugPrint("Klayvio SDK: Error resetting profile: $e");
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
            "Klayvio SDK: Warning! KlayvioSdk not initialized before createEvent call");
      }

      final success = await KlayvioSdkPlatform.instance.createEvent(
        name: name,
        properties: properties,
        value: value,
      );

      if (success) {
        debugPrint("Klayvio SDK: Event '$name' created successfully");
      } else {
        debugPrint("Klayvio SDK: Creating event '$name' returned false");
      }

      return success;
    } catch (e) {
      debugPrint("Klayvio SDK: Error creating event '$name': $e");
      return false;
    }
  }

  /// Register for push notifications
  Future<bool> registerForPushNotifications() async {
    try {
      if (!_initialized) {
        debugPrint(
            "Klayvio SDK: Warning! KlayvioSdk not initialized before registerForPushNotifications call");
      }

      final success =
          await KlayvioSdkPlatform.instance.registerForPushNotifications();

      if (success) {
        debugPrint(
            "Klayvio SDK: Registered for push notifications successfully");
      } else {
        debugPrint(
            "Klayvio SDK: Registering for push notifications returned false");
      }

      return success;
    } catch (e) {
      debugPrint("Klayvio SDK: Error registering for push notifications: $e");
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
            "Klayvio SDK: Warning! KlayvioSdk not initialized before setPushToken call");
      }

      final success = await KlayvioSdkPlatform.instance.setPushToken(token);

      if (success) {
        debugPrint("Klayvio SDK: Push token set successfully");
      } else {
        debugPrint("Klayvio SDK: Setting push token returned false");
      }

      return success;
    } catch (e) {
      debugPrint("Klayvio SDK: Error setting push token: $e");
      return false;
    }
  }
}
