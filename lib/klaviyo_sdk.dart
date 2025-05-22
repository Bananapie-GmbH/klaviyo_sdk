import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Enum for push notification interaction types
enum KlaviyoPushInteractionType {
  opened,
  dismissed,
  actionClicked,
}

/// Class representing push notification data
class KlaviyoPushNotificationData {
  final Map<String, dynamic> data;
  final String? title;
  final String? body;
  final KlaviyoPushInteractionType interactionType;
  final String? actionId;
  final bool fromBackground;
  final bool fromTerminated;

  const KlaviyoPushNotificationData({
    required this.data,
    this.title,
    this.body,
    required this.interactionType,
    this.actionId,
    required this.fromBackground,
    required this.fromTerminated,
  });

  factory KlaviyoPushNotificationData.fromMap(Map<String, dynamic> map) {
    return KlaviyoPushNotificationData(
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      title: map['title'],
      body: map['body'],
      interactionType: _parseInteractionType(map['interactionType']),
      actionId: map['actionId'],
      fromBackground: map['fromBackground'] ?? false,
      fromTerminated: map['fromTerminated'] ?? false,
    );
  }

  static KlaviyoPushInteractionType _parseInteractionType(String? type) {
    switch (type) {
      case 'opened':
        return KlaviyoPushInteractionType.opened;
      case 'dismissed':
        return KlaviyoPushInteractionType.dismissed;
      case 'actionClicked':
        return KlaviyoPushInteractionType.actionClicked;
      default:
        return KlaviyoPushInteractionType.opened;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'title': title,
      'body': body,
      'interactionType': interactionType.name,
      'actionId': actionId,
      'fromBackground': fromBackground,
      'fromTerminated': fromTerminated,
    };
  }
}

/// Main Klaviyo Flutter plugin class
class KlaviyoSdk {
  static const MethodChannel _channel = MethodChannel('klaviyo_sdk');
  static const EventChannel _eventChannel =
      EventChannel('klaviyo_sdk/push_events');

  static KlaviyoSdk? _instance;
  static KlaviyoSdk get instance => _instance ??= KlaviyoSdk._();

  KlaviyoSdk._();

  Stream<KlaviyoPushNotificationData>? _pushNotificationStream;

  /// Initialize Klaviyo SDK with API key
  Future<void> initialize(String apiKey) async {
    try {
      await _channel.invokeMethod('initialize', {'apiKey': apiKey});
    } on PlatformException catch (e) {
      throw Exception('Failed to initialize Klaviyo: ${e.message}');
    }
  }

  /// Set user profile
  Future<void> setProfile({
    String? email,
    String? phoneNumber,
    String? externalId,
    Map<String, dynamic>? properties,
  }) async {
    try {
      await _channel.invokeMethod('setProfile', {
        'email': email,
        'phoneNumber': phoneNumber,
        'externalId': externalId,
        'properties': properties,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to set profile: ${e.message}');
    }
  }

  /// Track event
  Future<void> trackEvent({
    required String eventName,
    Map<String, dynamic>? properties,
    double? value,
  }) async {
    try {
      await _channel.invokeMethod('trackEvent', {
        'eventName': eventName,
        'properties': properties,
        'value': value,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to track event: ${e.message}');
    }
  }

  /// Request push notification permissions (iOS only)
  Future<bool> requestPushPermissions() async {
    if (!Platform.isIOS) return true;
    
    try {
      final result = await _channel.invokeMethod('requestPushPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to request push permissions: ${e.message}');
    }
  }

  /// Register for push notifications
  Future<void> registerForPushNotifications() async {
    try {
      await _channel.invokeMethod('registerForPushNotifications');
    } on PlatformException catch (e) {
      throw Exception(
          'Failed to register for push notifications: ${e.message}');
    }
  }

  /// Get the push notification token
  Future<String?> getPushToken() async {
    try {
      return await _channel.invokeMethod('getPushToken');
    } on PlatformException catch (e) {
      throw Exception('Failed to get push token: ${e.message}');
    }
  }

  /// Stream of push notification interactions
  Stream<KlaviyoPushNotificationData> get onPushNotificationReceived {
    _pushNotificationStream ??= _eventChannel.receiveBroadcastStream().map(
        (data) => KlaviyoPushNotificationData.fromMap(
            Map<String, dynamic>.from(data)));
    return _pushNotificationStream!;
  }

  /// Handle push notification when app is launched from terminated state
  Future<KlaviyoPushNotificationData?> getInitialPushNotification() async {
    try {
      final result = await _channel.invokeMethod('getInitialPushNotification');
      if (result != null) {
        return KlaviyoPushNotificationData.fromMap(
            Map<String, dynamic>.from(result));
      }
      return null;
    } on PlatformException catch (e) {
      throw Exception('Failed to get initial push notification: ${e.message}');
    }
  }

  /// Reset user profile
  Future<void> resetProfile() async {
    try {
      await _channel.invokeMethod('resetProfile');
    } on PlatformException catch (e) {
      throw Exception('Failed to reset profile: ${e.message}');
    }
  }
}
