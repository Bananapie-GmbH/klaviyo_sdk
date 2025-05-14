#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint klayvio_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'klayvio_sdk'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for Klaviyo SDK'
  s.description      = <<-DESC
A Flutter plugin for integrating Klaviyo's push notifications, event tracking, and user profile management.
                       DESC
  s.homepage         = 'https://github.com/yourusername/klayvio_sdk'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :git => 'https://github.com/yourusername/klayvio_sdk.git', :tag => s.version.to_s }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  
  # Specify exact versions for Klaviyo dependencies
  s.dependency 'KlaviyoSwift', '~> 4.2.1'
  s.ios.deployment_target = '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'klayvio_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
