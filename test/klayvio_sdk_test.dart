// import 'package:flutter_test/flutter_test.dart';
// import 'package:klayvio_sdk/klayvio_sdk.dart';
// import 'package:klayvio_sdk/klayvio_sdk_platform_interface.dart';
// import 'package:klayvio_sdk/klayvio_sdk_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockKlayvioSdkPlatform
//     with MockPlatformInterfaceMixin
//     implements KlayvioSdkPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final KlayvioSdkPlatform initialPlatform = KlayvioSdkPlatform.instance;

//   test('$MethodChannelKlayvioSdk is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelKlayvioSdk>());
//   });

//   test('getPlatformVersion', () async {
//     KlayvioSdk klayvioSdkPlugin = KlayvioSdk();
//     MockKlayvioSdkPlatform fakePlatform = MockKlayvioSdkPlatform();
//     KlayvioSdkPlatform.instance = fakePlatform;

//     expect(await klayvioSdkPlugin.getPlatformVersion(), '42');
//   });
// }
