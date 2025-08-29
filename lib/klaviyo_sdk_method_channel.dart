import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'klaviyo_sdk_platform_interface.dart';

/// An implementation of [KlaviyoSdkPlatform] that uses method channels.
class MethodChannelKlaviyoSdk extends KlaviyoSdkPlatform {
  MethodChannelKlaviyoSdk() {
    // Ensure handler is registered as soon as the instance is created
    setupMethodCallHandler();
  }
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('klaviyo_sdk');

  /// The event channel used for streaming messages.
  @visibleForTesting
  final eventChannel = const EventChannel('klaviyo_sdk/notification_events');

  /// Stream controllers for push notifications
  final StreamController<Map<String, dynamic>?> _messageController =
      StreamController<Map<String, dynamic>?>.broadcast();
  final StreamController<Map<String, dynamic>?> _messageOpenedAppController =
      StreamController<Map<String, dynamic>?>.broadcast();

  /// Flag to track if method call handler is set up
  bool _isMethodCallHandlerSetup = false;

  /// Set up method call handler to receive push notifications from native side
  void setupMethodCallHandler() {
    if (_isMethodCallHandlerSetup) return;

    debugPrint('Klaviyo SDK: Setting up method call handler');
    methodChannel.setMethodCallHandler(_handleMethodCall);
    _isMethodCallHandlerSetup = true;
  }

  /// Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('Klaviyo SDK: Received method call: ${call.method}');
    debugPrint('Klaviyo SDK: Method call arguments: ${call.arguments}');

    switch (call.method) {
      case 'onPushNotificationReceived':
        debugPrint('Klaviyo SDK: Processing onPushNotificationReceived');
        final data = call.arguments as Map<dynamic, dynamic>?;
        if (data != null) {
          final mappedData = Map<String, dynamic>.from(data);
          debugPrint('Klaviyo SDK: Push notification received: $mappedData');

          // Determine which stream to emit to based on the type
          final type = mappedData['type'] as String?;
          debugPrint('Klaviyo SDK: Notification type: $type');

          if (type == 'notification_opened') {
            debugPrint('Klaviyo SDK: Adding to messageOpenedApp stream');
            _messageOpenedAppController.add(mappedData);
          } else {
            debugPrint('Klaviyo SDK: Adding to message stream');
            _messageController.add(mappedData);
          }
        } else {
          debugPrint('Klaviyo SDK: No data received in method call');
        }
        return true;
      default:
        debugPrint('Klaviyo SDK: Unknown method call: ${call.method}');
        return false;
    }
  }

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
    Map<String, dynamic>? location,
    Map<String, dynamic>? properties,
  }) async {
    try {
      final Map<String, dynamic> args = {
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (externalId != null) 'externalId': externalId,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (location != null) 'location': location,
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

  Stream<Map<String, dynamic>?> get _allEvents =>
      eventChannel.receiveBroadcastStream().map((event) {
        debugPrint('Klaviyo SDK Received event: $event');
        if (event is Map) {
          return Map<String, dynamic>.from(event);
        }
        return null;
      }).where((e) => e != null);

  @override
  Stream<Map<String, dynamic>?> get onMessage {
    debugPrint('Klaviyo SDK: onMessage stream accessed');

    return _messageController.stream.map((event) {
      debugPrint('Klaviyo SDK: onMessage stream emitted event: $event');
      return event;
    });
  }

  @override
  Stream<Map<String, dynamic>?> get onMessageOpenedApp {
    debugPrint('Klaviyo SDK: onMessageOpenedApp stream accessed');

    return _messageOpenedAppController.stream.map((event) {
      debugPrint(
          'Klaviyo SDK: onMessageOpenedApp stream emitted event: $event');
      return event;
    });
  }

  /// Clean up resources
  void dispose() {
    _messageController.close();
    _messageOpenedAppController.close();
  }
}
