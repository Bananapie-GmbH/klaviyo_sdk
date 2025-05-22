import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'klaviyo_sdk_platform_interface.dart';

/// An implementation of [KlaviyoSdkPlatform] that uses method channels.
class MethodChannelKlaviyoSdk extends KlaviyoSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('klaviyo_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    try {
      final version =
          await methodChannel.invokeMethod<String>('getPlatformVersion');
      return version;
    } on PlatformException catch (e) {
      debugPrint('Error getting platform version: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<bool> initialize(String apiKey) async {
    try {

      final success = await methodChannel
          .invokeMethod<bool>('initialize', {'apiKey': apiKey});
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error initializing Klaviyo SDK: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<bool> setProfile({
    String? email,
    String? phoneNumber,
    String? externalId,
    String? firstName,
    String? lastName,
    Map<String, dynamic>? properties,
  }) async {
    try {
      final Map<String, dynamic> args = {
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (externalId != null) 'externalId': externalId,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (properties != null) 'properties': properties,
      };
      final success =
          await methodChannel.invokeMethod<bool>('setProfile', args);
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error setting profile: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<bool> resetProfile() async {
    try {
      final success = await methodChannel.invokeMethod<bool>('resetProfile');
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error resetting profile: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<bool> createEvent({
    required String name,
    Map<String, dynamic>? properties,
    double? value,
  }) async {
    try {
      final Map<String, dynamic> args = {
        'name': name,
        if (properties != null) 'properties': properties,
        if (value != null) 'value': value,
      };
      final success =
          await methodChannel.invokeMethod<bool>('createEvent', args);
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error creating event: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<bool> registerForPushNotifications() async {
    try {
      final success = await methodChannel
          .invokeMethod<bool>('registerForPushNotifications');
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error registering for push notifications: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<bool> setPushToken(String token) async {
    try {
      final success = await methodChannel
          .invokeMethod<bool>('setPushToken', {'token': token});
      debugPrint("Sent push token to Klaviyo successfully: $token");
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error setting push token: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<bool> handlePush(Map<String, dynamic>? payload) async {
    try {
      final success =
          await methodChannel
          .invokeMethod<bool>('handlePush', {'payload': payload});
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error handling push: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<bool> setupNativeMethodCalls(
      Future<dynamic> Function(MethodCall)? handler) async {
    methodChannel.setMethodCallHandler(handler);
    return true;
  }
}
