import Flutter
import UIKit
import KlaviyoSwift
import UserNotifications

public class KlaviyoFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var initialPushNotification: [String: Any]?
    private var channel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "klaviyo_sdk", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "klaviyo_sdk/push_events", binaryMessenger: registrar.messenger())
        
        let instance = KlaviyoFlutterPlugin()
        instance.channel = channel
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        
        // Handle app launch from terminated state
        instance.handleAppLaunchFromPush()
    }
    
    private func handleAppLaunchFromPush() {
        if let launchOptions = (UIApplication.shared.delegate as? FlutterAppDelegate)?.launchOptions,
           let userInfo = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            self.initialPushNotification = self.formatPushNotificationData(
                userInfo: userInfo,
                interactionType: "opened",
                fromBackground: false,
                fromTerminated: true
            )
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(call, result: result)
        case "setProfile":
            handleSetProfile(call, result: result)
        case "trackEvent":
            handleTrackEvent(call, result: result)
        case "requestPushPermissions":
            handleRequestPushPermissions(result: result)
        case "registerForPushNotifications":
            handleRegisterForPushNotifications(result: result)
        case "getPushToken":
            handleGetPushToken(result: result)
        case "getInitialPushNotification":
            handleGetInitialPushNotification(result: result)
        case "resetProfile":
            handleResetProfile(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let apiKey = args["apiKey"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "API key is required", details: nil))
            return
        }
        
        KlaviyoSDK().initialize(with: apiKey)
        setupPushNotificationHandling()
        result(nil)
    }
    
    private func handleSetProfile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are required", details: nil))
            return
        }
        
        let profile = Profile()
        
        if let email = args["email"] as? String {
            profile.email = email
        }
        
        if let phoneNumber = args["phoneNumber"] as? String {
            profile.phoneNumber = phoneNumber
        }
        
        if let externalId = args["externalId"] as? String {
            profile.externalId = externalId
        }
        
        if let properties = args["properties"] as? [String: Any] {
            for (key, value) in properties {
                profile.setProfileAttribute(propertyKey: ProfilePropertyKey(rawValue: key), value: value)
            }
        }
        
        KlaviyoSDK().set(profile: profile)
        result(nil)
    }
    
    private func handleTrackEvent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let eventName = args["eventName"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Event name is required", details: nil))
            return
        }
        
        let event = Event(name: EventName(rawValue: eventName))
        
        if let properties = args["properties"] as? [String: Any] {
            for (key, value) in properties {
                event.setEventAttribute(propertyKey: EventPropertyKey(rawValue: key), value: value)
            }
        }
        
        if let value = args["value"] as? Double {
            event.setValue(value)
        }
        
        KlaviyoSDK().create(event: event)
        result(nil)
    }
    
    private func handleRequestPushPermissions(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "PERMISSION_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    result(granted)
                }
            }
        }
    }
    
    private func handleRegisterForPushNotifications(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            result(nil)
        }
    }
    
    private func handleGetPushToken(result: @escaping FlutterResult) {
        // The token will be available through the AppDelegate methods
        // This is a placeholder - you might want to store the token when received
        result(nil)
    }
    
    private func handleGetInitialPushNotification(result: @escaping FlutterResult) {
        result(initialPushNotification)
        initialPushNotification = nil // Clear after first access
    }
    
    private func handleResetProfile(result: @escaping FlutterResult) {
        KlaviyoSDK().resetProfile()
        result(nil)
    }
    
    private func setupPushNotificationHandling() {
        UNUserNotificationCenter.current().delegate = self
        
        // Handle push token registration
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didRegisterForRemoteNotifications(_:)),
            name: NSNotification.Name("DidRegisterForRemoteNotifications"),
            object: nil
        )
    }
    
    @objc private func didRegisterForRemoteNotifications(_ notification: Notification) {
        if let token = notification.object as? Data {
            KlaviyoSDK().set(pushToken: token)
        }
    }
    
    private func formatPushNotificationData(
        userInfo: [AnyHashable: Any],
        interactionType: String,
        actionId: String? = nil,
        fromBackground: Bool = false,
        fromTerminated: Bool = false
    ) -> [String: Any] {
        var data: [String: Any] = [:]
        
        // Extract standard notification data
        if let aps = userInfo["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? [String: Any] {
                data["title"] = alert["title"]
                data["body"] = alert["body"]
            } else if let alertString = aps["alert"] as? String {
                data["body"] = alertString
            }
        }
        
        // Extract custom data (excluding aps)
        var customData: [String: Any] = [:]
        for (key, value) in userInfo {
            if let keyString = key as? String, keyString != "aps" {
                customData[keyString] = value
            }
        }
        
        return [
            "data": customData,
            "title": data["title"] as Any,
            "body": data["body"] as Any,
            "interactionType": interactionType,
            "actionId": actionId as Any,
            "fromBackground": fromBackground,
            "fromTerminated": fromTerminated
        ]
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension KlaviyoFlutterPlugin: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        // Handle Klaviyo tracking
        KlaviyoSDK().handle(notificationResponse: UNNotificationResponse(notification: notification, actionIdentifier: UNNotificationDefaultActionIdentifier))
        
        let notificationData = formatPushNotificationData(
            userInfo: userInfo,
            interactionType: "opened",
            fromBackground: false,
            fromTerminated: false
        )
        
        eventSink?(notificationData)
        
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    // Handle notification interaction (tap, action buttons)
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        // Handle Klaviyo tracking
        KlaviyoSDK().handle(notificationResponse: response)
        
        var interactionType = "opened"
        var actionId: String?
        
        if actionIdentifier == UNNotificationDismissActionIdentifier {
            interactionType = "dismissed"
        } else if actionIdentifier != UNNotificationDefaultActionIdentifier {
            interactionType = "actionClicked"
            actionId = actionIdentifier
        }
        
        let notificationData = formatPushNotificationData(
            userInfo: userInfo,
            interactionType: interactionType,
            actionId: actionId,
            fromBackground: UIApplication.shared.applicationState != .active,
            fromTerminated: false
        )
        
        eventSink?(notificationData)
        
        completionHandler()
    }
}