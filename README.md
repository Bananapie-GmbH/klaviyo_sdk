# Klaviyo SDK Flutter Plugin

A Flutter plugin that provides a bridge to the Klaviyo SDK for both iOS and Android platforms.

## Features

- Initialize Klaviyo SDK with your API key
- Set user profiles with various attributes
- Track custom events
- Push notification support via Firebase Cloud Messaging (FCM)
- Real-time push notification event streaming to Flutter

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  klaviyo_sdk: ^1.0.0
```

## Usage

### Basic Setup

```dart
import 'package:klaviyo_sdk/klaviyo_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _klaviyoSdk = KlaviyoSdk.instance;

  @override
  void initState() {
    super.initState();
    _initializeKlaviyo();
  }

  Future<void> _initializeKlaviyo() async {
    await _klaviyoSdk.initialize('YOUR_KLAVIYO_PUBLIC_API_KEY');
    await _klaviyoSdk.registerForPushNotifications();
  }
}
```

### Push Notification Events

The plugin provides real-time streaming of push notification events from the FCM service to Flutter. You can listen to these events to handle push notifications in your app:

```dart
class _MyAppState extends State<MyApp> {
  StreamSubscription<Map<String, dynamic>?>? _pushNotificationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeKlaviyo();
    _listenToPushNotifications();
  }

  @override
  void dispose() {
    _pushNotificationSubscription?.cancel();
    super.dispose();
  }

  void _listenToPushNotifications() {
    _pushNotificationSubscription = _klaviyoSdk.onMessageReceived.listen(
      (notificationData) {
        if (notificationData != null) {
          final type = notificationData['type'];
          final title = notificationData['title'];
          final body = notificationData['body'];
          final messageId = notificationData['messageId'];
          
          print('Push notification received: $type - $title: $body');
          
          // Handle different types of notifications
          switch (type) {
            case 'klaviyo_notification_received':
              // Handle Klaviyo notification
              break;
            case 'klaviyo_custom_data_received':
              // Handle Klaviyo custom data
              break;
            case 'non_klaviyo_message_received':
              // Handle non-Klaviyo messages
              break;
          }
        }
      },
      onError: (error) {
        print('Error listening to push notifications: $error');
      },
    );
  }
}
```

### Event Types

The plugin sends different types of events based on the push notification source:

- **`klaviyo_notification_received`**: Standard Klaviyo push notifications with title and body
- **`klaviyo_custom_data_received`**: Klaviyo messages with custom key-value pairs
- **`non_klaviyo_message_received`**: Push notifications from other sources

### Profile Management

```dart
// Set user profile
await _klaviyoSdk.setProfile(
  email: 'user@example.com',
  firstName: 'John',
  lastName: 'Doe',
  properties: {
    'favoriteColor': 'blue',
    'age': 30,
  },
);

// Reset profile
await _klaviyoSdk.resetProfile();
```

### Event Tracking

```dart
// Track custom events
await _klaviyoSdk.createEvent(
  name: 'Viewed Product',
  properties: {
    'productName': 'Cool T-Shirt',
    'color': 'blue',
    'size': 'medium',
  },
  value: 29.99,
);
```

### Push Token Management

```dart
// Set push token (usually handled automatically)
await _klaviyoSdk.setPushToken('your_fcm_token');

// Get current push token
final token = await _klaviyoSdk.getPushToken();
```

## Android Setup

### Firebase Configuration

1. Add your `google-services.json` file to `android/app/`
2. Ensure your app is registered for FCM in the Firebase console
3. The plugin automatically handles FCM token registration and message reception

### Manifest Configuration

The plugin automatically registers the FCM service. No additional manifest configuration is required.

## iOS Setup

### Firebase Configuration

1. Add your `GoogleService-Info.plist` file to your iOS project
2. Ensure your app is registered for FCM in the Firebase console

### Capabilities

Enable the following capabilities in your iOS project:
- Push Notifications
- Background Modes (Remote notifications)

## Example

See the `example/` directory for a complete working example that demonstrates:
- SDK initialization
- Profile management
- Event tracking
- Push notification event listening
- Real-time notification logs

## Troubleshooting

### Push Notifications Not Working

1. Ensure Firebase is properly configured
2. Check that the FCM service is registered in your app
3. Verify that you're listening to the `onMessageReceived` stream
4. Check the console logs for any error messages

### Event Channel Issues

If you're not receiving push notification events:
1. Make sure the plugin is properly initialized
2. Verify that the event channel is set up correctly
3. Check that you're not disposing of the subscription too early

## License

This project is licensed under the MIT License - see the LICENSE file for details.

