import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'klayvio_sdk_method_channel.dart';

abstract class KlayvioSdkPlatform extends PlatformInterface {
  /// Constructs a KlayvioSdkPlatform.
  KlayvioSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static KlayvioSdkPlatform _instance = MethodChannelKlayvioSdk();

  /// The default instance of [KlayvioSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelKlayvioSdk].
  static KlayvioSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KlayvioSdkPlatform] when
  /// they register themselves.
  static set instance(KlayvioSdkPlatform instance) {
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
}
