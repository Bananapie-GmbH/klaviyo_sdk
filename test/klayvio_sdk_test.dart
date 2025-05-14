// import 'package:flutter_test/flutter_test.dart';
// import 'package:klaviyo_sdk/klaviyo_sdk.dart';
// import 'package:klaviyo_sdk/klaviyo_sdk_platform_interface.dart';
// import 'package:klaviyo_sdk/klaviyo_sdk_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockKlaviyoSdkPlatform
//     with MockPlatformInterfaceMixin
//     implements KlaviyoSdkPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final KlaviyoSdkPlatform initialPlatform = KlaviyoSdkPlatform.instance;

//   test('$MethodChannelKlaviyoSdk is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelKlaviyoSdk>());
//   });

//   test('getPlatformVersion', () async {
//     KlaviyoSdk klaviyoSdkPlugin = KlaviyoSdk();
//     MockKlaviyoSdkPlatform fakePlatform = MockKlaviyoSdkPlatform();
//     KlaviyoSdkPlatform.instance = fakePlatform;

//     expect(await klaviyoSdkPlugin.getPlatformVersion(), '42');
//   });
// }
