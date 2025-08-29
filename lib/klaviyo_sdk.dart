import 'package:flutter/services.dart';
import 'klaviyo_sdk_platform_interface.dart';
import 'klaviyo_sdk_method_channel.dart';
import 'dart:async';

class KlaviyoSdk {
  KlaviyoSdk._internal();
  static final KlaviyoSdk instance = KlaviyoSdk._internal();

  /// Foreground and data messages (FirebaseMessaging.onMessage equivalent)
  Stream<Map<String, dynamic>?> get onMessage {
    if (KlaviyoSdkPlatform.instance is MethodChannelKlaviyoSdk) {
      final stream =
          (KlaviyoSdkPlatform.instance as MethodChannelKlaviyoSdk).onMessage;
      return stream.map((event) {
        return event;
      });
    }
    return const Stream.empty();
  }

  /// Notification tap/open events (FirebaseMessaging.onMessageOpenedApp equivalent)
  Stream<Map<String, dynamic>?> get onMessageOpenedApp {
    if (KlaviyoSdkPlatform.instance is MethodChannelKlaviyoSdk) {
      return (KlaviyoSdkPlatform.instance as MethodChannelKlaviyoSdk)
          .onMessageOpenedApp;
    }
    return const Stream.empty();
  }

  Future<String?> getPlatformVersion() {
    return KlaviyoSdkPlatform.instance.getPlatformVersion();
  }

  Future<bool> initialize(String apiKey) async {
    return KlaviyoSdkPlatform.instance.initialize(apiKey);
  }

  Future<bool> setProfile({
    String? email,
    String? phoneNumber,
    String? externalId,
    String? firstName,
    String? lastName,
    Map<String, dynamic>? location,
    Map<String, dynamic>? properties,
  }) {
    return KlaviyoSdkPlatform.instance.setProfile(
      email: email,
      phoneNumber: phoneNumber,
      externalId: externalId,
      firstName: firstName,
      lastName: lastName,
      properties: properties,
    );
  }

  Future<bool> resetProfile() {
    return KlaviyoSdkPlatform.instance.resetProfile();
  }

  Future<bool> createEvent({
    required String name,
    Map<String, dynamic>? properties,
    double? value,
  }) {
    return KlaviyoSdkPlatform.instance.createEvent(
      name: name,
      properties: properties,
      value: value,
    );
  }

  Future<bool> registerForPushNotifications() {
    return KlaviyoSdkPlatform.instance.registerForPushNotifications();
  }

  Future<bool> setPushToken(String token) {
    return KlaviyoSdkPlatform.instance.setPushToken(token);
  }

  // Convenience attribute setters/getters using the iOS bridge methods
  Future<void> setExternalId(String value) async {
    const channel = MethodChannel('klaviyo_sdk');
    await channel.invokeMethod('setExternalId', {'value': value});
  }

  Future<String> getExternalId() async {
    const channel = MethodChannel('klaviyo_sdk');
    return (await channel.invokeMethod<String>('getExternalId')) ?? '';
  }

  Future<void> setEmail(String value) async {
    const channel = MethodChannel('klaviyo_sdk');
    await channel.invokeMethod('setEmail', {'value': value});
  }

  Future<String> getEmail() async {
    const channel = MethodChannel('klaviyo_sdk');
    return (await channel.invokeMethod<String>('getEmail')) ?? '';
  }

  Future<void> setPhoneNumber(String value) async {
    const channel = MethodChannel('klaviyo_sdk');
    await channel.invokeMethod('setPhoneNumber', {'value': value});
  }

  Future<String> getPhoneNumber() async {
    const channel = MethodChannel('klaviyo_sdk');
    return (await channel.invokeMethod<String>('getPhoneNumber')) ?? '';
  }

  Future<void> setBadgeCount(int count) async {
    const channel = MethodChannel('klaviyo_sdk');
    await channel.invokeMethod('setBadgeCount', {'count': count});
  }

  Future<Map<String, String>> getEventTypesKeys() async {
    const channel = MethodChannel('klaviyo_sdk');
    final map =
        await channel.invokeMethod<Map<dynamic, dynamic>>('getEventTypesKeys');
    return map?.map((key, value) => MapEntry(key as String, value as String)) ??
        <String, String>{};
  }

  Future<Map<String, String>> getProfilePropertyKeys() async {
    const channel = MethodChannel('klaviyo_sdk');
    final map = await channel
        .invokeMethod<Map<dynamic, dynamic>>('getProfilePropertyKeys');
    return map?.map((key, value) => MapEntry(key as String, value as String)) ??
        <String, String>{};
  }

  KlaviyoPushNotification? getPushNotification(Map<String, dynamic> map) {
    if (map.isEmpty) {
      return null;
    }
    if (map.containsKey('_k')) {
      return KlaviyoPushNotification.fromMap(map);
    }
    return null;
  }
}
