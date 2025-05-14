import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:klayvio_sdk/klayvio_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _klaviyoSdk = KlayvioSdk.instance;

  @override
  void initState() {
    super.initState();
    _initializeKlaviyo();
  }

  // Initialize Klaviyo SDK
  Future<void> _initializeKlaviyo() async {
    await _klaviyoSdk.initialize('YOUR_KLAVIYO_PUBLIC_API_KEY');

    // Optional: Register for push notifications
    await _klaviyoSdk.registerForPushNotifications();
  }

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Klaviyo SDK Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _setProfile,
                child: const Text('Set Profile'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _trackEvent,
                child: const Text('Track Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
