import Flutter
import UIKit
import KlaviyoSwift

public class KlaviyoSdkPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "klaviyo_sdk", binaryMessenger: registrar.messenger())
    let instance = KlaviyoSdkPlugin()

    if #available(OSX 10.14, *) {
        let center = UNUserNotificationCenter.current()
        center.delegate = instance
    }

    registrar.addMethodCallDelegate(instance, channel: channel)
    
    
  }

  public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {

        if #available(iOS 16.0, *) {
          UNUserNotificationCenter.current().setBadgeCount(UIApplication.shared.applicationIconBadgeNumber - 1)
        } else {
          UIApplication.shared.applicationIconBadgeNumber -= 1
        }
        // If this notification is Klaviyo's notification we'll handle it
        // else pass it on to the next push notification service to which it may belong
        let handled = KlaviyoSDK().handle(notificationResponse: response, withCompletionHandler: completionHandler)
        if !handled {
            completionHandler()
        }
    }

    // below method is called when the app receives push notifications when the app is the foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        if #available(iOS 14.0, *) {
            completionHandler([.list, .banner])
        } else {
            completionHandler([.alert])
        }
    }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "initialize":
      guard let args = call.arguments as? [String: Any],
            let apiKey = args["apiKey"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "API key is required", details: nil))
        return
      }
      
      // Initialize Klaviyo with the API key
      do {
        KlaviyoSDK().initialize(with: apiKey)
        result(true)
      } catch let error {
        result(FlutterError(code: "INITIALIZATION_ERROR", message: "Failed to initialize Klaviyo: \(error.localizedDescription)", details: nil))
      }
    case "setProfile":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      
      let email = args["email"] as? String
      let phoneNumber = args["phoneNumber"] as? String
      let externalId = args["externalId"] as? String
      let firstName = args["firstName"] as? String
      let lastName = args["lastName"] as? String
      let properties = args["properties"] as? [String: Any]
      
      // Create a profile object
      let profile = Profile(
        email: email,
        phoneNumber: phoneNumber,
        externalId: externalId,
        firstName: firstName,
        lastName: lastName,
        properties: properties
      )
      
      // Set the profile
      do {
        try KlaviyoSDK().set(profile: profile)
        result(true)
      } catch let error {
        result(FlutterError(code: "SET_PROFILE_ERROR", message: "Failed to set profile: \(error.localizedDescription)", details: nil))
      }
    case "resetProfile":
      do {
        try KlaviyoSDK().resetProfile()
        result(true)
      } catch let error {
        result(FlutterError(code: "RESET_PROFILE_ERROR", message: "Failed to reset profile: \(error.localizedDescription)", details: nil))
      }
    case "createEvent":
      guard let args = call.arguments as? [String: Any],
            let eventName = args["name"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Event name is required", details: nil))
        return
      }
      
      let properties = args["properties"] as? [String: Any]
      let value = args["value"] as? Double
      
      // Create a custom event
      let event = Event(
        name: .customEvent(eventName),
        properties: properties,
        value: value
      )
      
      // Create the event
      do {
        try KlaviyoSDK().create(event: event)
        result(true)
      } catch let error {
        result(FlutterError(code: "CREATE_EVENT_ERROR", message: "Failed to create event: \(error.localizedDescription)", details: nil))
      }
    case "registerForPushNotifications":
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
        
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        center.requestAuthorization(options: options) { granted, error in
          if let error = error {
            print("Error requesting notification permission: \(error)")
            result(FlutterError(code: "NOTIFICATION_ERROR", message: error.localizedDescription, details: nil))
          } else {
            DispatchQueue.main.async {
              UIApplication.shared.registerForRemoteNotifications()
              result(true)
            }
          }
        }
      }
    case "setPushToken":
      guard let args = call.arguments as? [String: Any],
            let tokenString = args["token"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Push token is required", details: nil))
        return
      }
      
      // Convert the hex string to Data
      if let tokenData = Data(hexString: tokenString) {
        do {
          try KlaviyoSDK().set(pushToken: tokenData)
          result(true)
        } catch let error {
          result(FlutterError(code: "SET_PUSH_TOKEN_ERROR", message: "Failed to set push token: \(error.localizedDescription)", details: nil))
        }
      } else {
        result(FlutterError(code: "INVALID_TOKEN", message: "Could not parse token string", details: nil))
      }
    case "handlePush":
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// Extension to convert hex string to Data
extension Data {
  init?(hexString: String) {
    let len = hexString.count / 2
    var data = Data(capacity: len)
    for i in 0..<len {
      let j = hexString.index(hexString.startIndex, offsetBy: i * 2)
      let k = hexString.index(j, offsetBy: 2)
      let bytes = hexString[j..<k]
      if let num = UInt8(bytes, radix: 16) {
        data.append(num)
      } else {
        return nil
      }
    }
    self = data
  }
}
