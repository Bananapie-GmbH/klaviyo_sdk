import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// TODO stream data back to flutter
// Dont forget to update MainActivity.kt in the target app with the example code from the example app

/// Class representing push token data
class KlaviyoPushToken {
  final String token;
  final DateTime receivedAt;

  const KlaviyoPushToken({
    required this.token,
    required this.receivedAt,
  });

  factory KlaviyoPushToken.fromMap(Map<String, dynamic> map) {
    return KlaviyoPushToken(
      token: map['token'] ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(map['receivedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'receivedAt': receivedAt.millisecondsSinceEpoch,
    };
  }
}

/// Class representing push notification data
class KlaviyoPushNotification {
  final Map<String, dynamic> data;
  final String? title;
  final String? body;
  final bool fromBackground;
  final bool fromTerminated;

  const KlaviyoPushNotification({
    required this.data,
    this.title,
    this.body,
    required this.fromBackground,
    required this.fromTerminated,
  });

  factory KlaviyoPushNotification.fromMap(Map<String, dynamic> map) {
    return KlaviyoPushNotification(
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      title: map['title'],
      body: map['body'],
      fromBackground: map['fromBackground'] ?? false,
      fromTerminated: map['fromTerminated'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'title': title,
      'body': body,
      'fromBackground': fromBackground,
      'fromTerminated': fromTerminated,
    };
  }
}

/// Main Klaviyo Flutter plugin class
class KlaviyoSdk {
  static const MethodChannel _channel = MethodChannel('klaviyo_sdk');
  static const EventChannel _tokenEventChannel =
      EventChannel('klaviyo_sdk/token_events');
  static const EventChannel _notificationEventChannel =
      EventChannel('klaviyo_sdk/notification_events');

  static KlaviyoSdk? _instance;
  static KlaviyoSdk get instance => _instance ??= KlaviyoSdk._();

  KlaviyoSdk._();

  Stream<KlaviyoPushToken>? _tokenStream;
  Stream<KlaviyoPushNotification>? _notificationStream;

  /// Initialize Klaviyo SDK with API key
  Future<void> initialize(String apiKey) async {
    try {
      await _channel.invokeMethod('initialize', {'apiKey': apiKey});
    } on PlatformException catch (e) {
      throw Exception('Failed to initialize Klaviyo: ${e.message}');
    }
  }

  /// Request push notification permissions
  Future<bool> requestPushPermissions() async {
    try {
      debugPrint('Klaviyo SDK: Requesting push permissions');
      final result = await _channel.invokeMethod('requestPushPermissions');
      debugPrint('Klaviyo SDK: Push permissions requested: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint(
          'Klaviyo SDK: Failed to request push permissions: ${e.message}');
      throw Exception(
          'Klaviyo SDK: Failed to request push permissions: ${e.message}');
    }
  }

  /// Stream of push token updates
  Stream<KlaviyoPushToken> get onTokenReceived {
    _tokenStream ??= _tokenEventChannel.receiveBroadcastStream().map(
        (data) => KlaviyoPushToken.fromMap(Map<String, dynamic>.from(data)));
    return _tokenStream!;
  }

  /// Stream of push notification received
  Stream<KlaviyoPushNotification> get onNotificationReceived {
    _notificationStream ??= _notificationEventChannel
        .receiveBroadcastStream()
        .map((data) =>
            KlaviyoPushNotification.fromMap(Map<String, dynamic>.from(data)));
    return _notificationStream!;
  }

  /// Get initial push notification if app was launched from terminated state
  Future<KlaviyoPushNotification?> getInitialNotification() async {
    try {
      debugPrint('Klaviyo SDK: Getting initial notification');
      final result = await _channel.invokeMethod('getInitialNotification');
      if (result != null) {
        debugPrint(
            'Klaviyo SDK: Initial notification received: ${result.toString()}');
        return KlaviyoPushNotification.fromMap(
            Map<String, dynamic>.from(result));
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint(
          'Klaviyo SDK: Failed to get initial notification: ${e.message}');
      throw Exception(
          'Klaviyo SDK: Failed to get initial notification: ${e.message}');
    }
  }

  /// Set profile
  Future<void> setProfile({
    String? email,
    String? phoneNumber,
    String? externalId,
    String? firstName,
    String? lastName,
  }) async {
    try {
      debugPrint(
          'Klaviyo SDK: Setting profile: $email, $phoneNumber, $externalId, $firstName, $lastName');
      await _channel.invokeMethod('setProfile', {
        'email': email,
        'phoneNumber': phoneNumber,
        'externalId': externalId,
        'firstName': firstName,
        'lastName': lastName,
      });
      debugPrint('Klaviyo SDK: Profile set successfully');
    } on PlatformException catch (e) {
      debugPrint('Klaviyo SDK: Failed to set profile: ${e.message}');
      throw Exception('Klaviyo SDK: Failed to set profile: ${e.message}');
    }
  }

  // set push token
  Future<void> setPushToken(String token) async {
    try {
      await _channel.invokeMethod('setPushToken', {'token': token});
    } on PlatformException catch (e) {
      throw Exception('Klaviyo SDK: Failed to set push token: ${e.message}');
    }
  }
  
}
