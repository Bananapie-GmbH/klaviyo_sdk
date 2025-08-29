import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:klaviyo_sdk/klaviyo_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _klaviyoSdk = KlaviyoSdk.instance;
  StreamSubscription<Map<String, dynamic>?>? _pushNotificationSubscription;
  List<String> _notificationLogs = [];

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

  // Initialize Klaviyo SDK
  Future<void> _initializeKlaviyo() async {
    await _klaviyoSdk.initialize('YOUR_KLAVIYO_PUBLIC_API_KEY');

    // Optional: Register for push notifications
    await _klaviyoSdk.registerForPushNotifications();
  }

  // Listen to push notification events from FCM service
  void _listenToPushNotifications() {}

  // Example of setting a profile
  Future<void> _setProfile() async {
    await _klaviyoSdk.setProfile(
      email: 'user@example.com',
      firstName: 'John',
      lastName: 'Doe',
      properties: {
        'favoriteColor': 'blue',
        'age': 30,
      },
    );
  }

  // Example of tracking an event
  Future<void> _trackEvent() async {
    await _klaviyoSdk.createEvent(
      name: 'Viewed Product',
      properties: {
        'productName': 'Cool T-Shirt',
        'color': 'blue',
        'size': 'medium',
      },
      value: 29.99,
    );
  }

  // Clear notification logs
  void _clearLogs() {
    setState(() {
      _notificationLogs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Klaviyo SDK Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _setProfile,
                      child: const Text('Set Profile'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _trackEvent,
                      child: const Text('Track Event'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Notification logs section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Push Notification Logs:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearLogs,
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Logs display
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _notificationLogs.isEmpty
                      ? const Center(
                          child: Text(
                            'No push notifications received yet.\n\n'
                            'Send a test push notification to see events here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _notificationLogs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _notificationLogs[index],
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
