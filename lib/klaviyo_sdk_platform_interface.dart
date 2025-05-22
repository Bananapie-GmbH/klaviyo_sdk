import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'klaviyo_sdk_method_channel.dart';

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

  /// Handle a deep link
  Future<bool> setupNativeMethodCalls(
      Future<dynamic> Function(MethodCall)? handler) {
    throw UnimplementedError(
        'setupNativeMethodCalls() has not been implemented.');
  }

  /// Set a profile for identification
  Future<bool> setProfile({
    String? email,
    String? phoneNumber,
    String? externalId,
    String? firstName,
    String? lastName,
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

  /// Handle a push notification
  Future<bool> handlePush(Map<String, dynamic>? payload) {
    throw UnimplementedError('handlePush() has not been implemented.');
  }
}
