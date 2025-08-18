import Flutter
import UIKit
import UserNotifications

@objc public class KlaviyoSdkPlugin: NSObject, FlutterPlugin {
    private static let channelName = "klaviyo_sdk"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = KlaviyoSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)

        case "initialize":
            guard let args = call.arguments as? [String: Any],
                  let apiKey = args["apiKey"] as? String,
                  !apiKey.isEmpty else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "API key is required", details: nil))
                return
            }
            KlaviyoBridge.initialize(apiKey)
            result(true)

        case "registerForInAppForms":
            // Forms integration disabled; no-op
            result(true)

        case "unregisterFromInAppForms":
            // Forms integration disabled; no-op
            result(true)

        case "setProfile":
            guard var properties = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Profile properties map is required", details: nil))
                return
            }
            // Normalize keys to snake_case expected by KlaviyoBridge
            properties = Self.normalizeProfileKeys(properties)
            KlaviyoBridge.setProfile(Self.toAnyObjectDict(properties))
            result(true)

        case "setProfileAttribute":
            guard let args = call.arguments as? [String: Any],
                  let key = args["key"] as? String,
                  let value = args["value"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "key and value are required", details: nil))
                return
            }
            KlaviyoBridge.setProfileAttribute(key, value: value)
            result(true)

        case "setExternalId":
            guard let args = call.arguments as? [String: Any],
                  let value = args["value"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "value is required", details: nil))
                return
            }
            KlaviyoBridge.setExternalId(value)
            result(true)

        case "getExternalId":
            result(KlaviyoBridge.getExternalId())

        case "setEmail":
            guard let args = call.arguments as? [String: Any],
                  let value = args["value"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "value is required", details: nil))
                return
            }
            KlaviyoBridge.setEmail(value)
            result(true)

        case "getEmail":
            result(KlaviyoBridge.getEmail())

        case "setPhoneNumber":
            guard let args = call.arguments as? [String: Any],
                  let value = args["value"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "value is required", details: nil))
                return
            }
            KlaviyoBridge.setPhoneNumber(value)
            result(true)

        case "getPhoneNumber":
            result(KlaviyoBridge.getPhoneNumber())

        case "setPushToken":
            guard let args = call.arguments as? [String: Any],
                  let token = args["token"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "token is required", details: nil))
                return
            }
            KlaviyoBridge.setPushToken(token)
            result(true)

        case "getPushToken":
            result(KlaviyoBridge.getPushToken())

        case "setBadgeCount":
            guard let args = call.arguments as? [String: Any],
                  let count = args["count"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "count is required", details: nil))
                return
            }
            KlaviyoBridge.setBadgeCount(count)
            result(true)

        case "resetProfile":
            KlaviyoBridge.resetProfile()
            result(true)

        case "createEvent":
            guard let args = call.arguments as? [String: Any],
                  let name = args["name"] as? String, !name.isEmpty else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "name is required", details: nil))
                return
            }
            var event: [String: Any] = ["name": name]
            if let properties = args["properties"] as? [String: Any] {
                event["properties"] = properties
            }
            if let value = args["value"] as? Double {
                event["value"] = value
            }
            if let uniqueId = args["uniqueId"] as? String {
                event["uniqueId"] = uniqueId
            }
            KlaviyoBridge.createEvent(event: Self.toAnyObjectDict(event))
            result(true)

        case "getEventTypesKeys":
            result(KlaviyoBridge.getEventTypesKeys)

        case "getProfilePropertyKeys":
            result(KlaviyoBridge.getProfilePropertyKeys)

        case "registerForPushNotifications":
            requestPushAuthorization(result: result)

        case "handlePush":
            // No-op on iOS for now; return true to indicate handled
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func requestPushAuthorization(result: @escaping FlutterResult) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                    result(granted)
                }
            }
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
            result(true)
        }
    }

    private static func toAnyObjectDict(_ dict: [String: Any]) -> [String: AnyObject] {
        var out: [String: AnyObject] = [:]
        for (k, v) in dict {
            out[k] = v as AnyObject
        }
        return out
    }

    private static func normalizeProfileKeys(_ input: [String: Any]) -> [String: Any] {
        var output: [String: Any] = [:]
        for (key, value) in input {
            let normalizedKey: String
            switch key {
            case "phoneNumber":
                normalizedKey = "phone_number"
            case "externalId":
                normalizedKey = "external_id"
            case "firstName":
                normalizedKey = "first_name"
            case "lastName":
                normalizedKey = "last_name"
            default:
                normalizedKey = key
            }

            if normalizedKey == "location", let location = value as? [String: Any] {
                output[normalizedKey] = location // location keys already match bridge expectations
            } else {
                output[normalizedKey] = value
            }
        }
        return output
    }
}


