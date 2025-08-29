import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'klaviyo_sdk_method_channel.dart';
import 'dart:async' as asy;

class KlaviyoPushNotification {
  final String? notificationTag;
  final String? sound;
  final Map<String, dynamic>? keyValuePairs;
  final String? body;
  final String? title;
  final String? url;

  KlaviyoPushNotification({
    this.title,
    this.body,
    this.notificationTag,
    this.sound,
    this.keyValuePairs,
    this.url,
  });

  factory KlaviyoPushNotification.fromMap(Map<String, dynamic> map) {
    return KlaviyoPushNotification(
      title: map['title'] as String?,
      body: map['body'] as String?,
      notificationTag: map['notificationTag'] as String?,
      sound: map['sound'] as String?,
      keyValuePairs: map['keyValuePairs'] as Map<String, dynamic>?,
      url: map['url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'notificationTag': notificationTag,
      'sound': sound,
      'keyValuePairs': keyValuePairs,
      'url': url,
    };
  }
}

abstract class KlaviyoSdkPlatform extends PlatformInterface {
  /// Constructs a KlaviyoSdkPlatform.
  KlaviyoSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static KlaviyoSdkPlatform _instance = MethodChannelKlaviyoSdk();

  /// The default instance of [KlaviyoSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelKlaviyoSdk].
  static KlaviyoSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KlaviyoSdkPlatform] when
  /// they register themselves.
  static set instance(KlaviyoSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Initialize the Klaviyo SDK with your public API key
  Future<bool> initialize(String apiKey) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Set a profile for identification
  Future<bool> setProfile({
    String? email,
    String? phoneNumber,
    String? externalId,
    String? firstName,
    String? lastName,
    Map<String, dynamic>? location,
    Map<String, dynamic>? properties,
  }) {
    throw UnimplementedError('setProfile() has not been implemented.');
  }

  /// Reset the current profile
  Future<bool> resetProfile() {
    throw UnimplementedError('resetProfile() has not been implemented.');
  }

  /// Track an event
  Future<bool> createEvent({
    required String name,
    Map<String, dynamic>? properties,
    double? value,
  }) {
    throw UnimplementedError('createEvent() has not been implemented.');
  }

  /// Register for push notifications
  Future<bool> registerForPushNotifications() {
    throw UnimplementedError(
        'registerForPushNotifications() has not been implemented.');
  }

  /// Set the push token for the device
  Future<bool> setPushToken(String token) {
    throw UnimplementedError('setPushToken() has not been implemented.');
  }

  static final asy.StreamController<Map<String, dynamic>?> onMessage =
      asy.StreamController<Map<String, dynamic>?>.broadcast();

  /// Notification tap/open events (similar to FirebaseMessaging.onMessageOpenedApp)
  Stream<Map<String, dynamic>?> get onMessageOpenedApp {
    throw UnimplementedError('onMessageOpenedApp() has not been implemented.');
  }
}
