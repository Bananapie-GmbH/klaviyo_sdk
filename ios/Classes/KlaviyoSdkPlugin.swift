import Flutter
import UIKit
import KlaviyoSwift
import UserNotifications

public class KlaviyoFlutterPlugin: NSObject, FlutterPlugin {
    private var tokenEventSink: FlutterEventSink?
    private var notificationEventSink: FlutterEventSink?
    private var initialNotification: [String: Any]?
    private var channel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "klaviyo_flutter", binaryMessenger: registrar.messenger())
        let tokenEventChannel = FlutterEventChannel(name: "klaviyo_flutter/token_events", binaryMessenger: registrar.messenger())
        let notificationEventChannel = FlutterEventChannel(name: "klaviyo_flutter/notification_events", binaryMessenger: registrar.messenger())
        
        let instance = KlaviyoFlutterPlugin()
        instance.channel = channel
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        tokenEventChannel.setStreamHandler(TokenStreamHandler(plugin: instance))
        notificationEventChannel.setStreamHandler(NotificationStreamHandler(plugin: instance))
        
        // Handle app launch from terminated state
        instance.handleAppLaunchFromPush()
    }
    
    private func handleAppLaunchFromPush() {
        if let launchOptions = (UIApplication.shared.delegate as? FlutterAppDelegate)?.launchOptions,
           let userInfo = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            self.initialNotification = self.formatNotificationData(
                userInfo: userInfo,
                fromBackground: false,
                fromTerminated: true
            )
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(call, result: result)
        case "requestPushPermissions":
            handleRequestPushPermissions(result: result)
        case "getInitialNotification":
            handleGetInitialNotification(result: result)
        case "setProfile":
            handleSetProfile(call, result: result)
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
    
    private func handleRequestPushPermissions(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "PERMISSION_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                    result(granted)
                }
            }
        }
    }
    
    private func handleGetInitialNotification(result: @escaping FlutterResult) {
        result(initialNotification)
        initialNotification = nil // Clear after first access
    }

    private func handleSetProfile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let email = args["email"] as? String,
              let phoneNumber = args["phoneNumber"] as? String,
              let externalId = args["externalId"] as? String,
              let properties = args["properties"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid profile arguments", details: nil))
            return
        } 

        
        
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
            // Send token to Klaviyo
            KlaviyoSDK().set(pushToken: token)
            
            // Convert token to string and send to Flutter
            let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
            let tokenData: [String: Any] = [
                "token": tokenString,
                "receivedAt": Int64(Date().timeIntervalSince1970 * 1000)
            ]
            
            tokenEventSink?(tokenData)
        }
    }
    
    private func formatNotificationData(
        userInfo: [AnyHashable: Any],
        fromBackground: Bool = false,
        fromTerminated: Bool = false
    ) -> [String: Any] {
        var title: String?
        var body: String?
        
        // Extract standard notification data
        if let aps = userInfo["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? [String: Any] {
                title = alert["title"] as? String
                body = alert["body"] as? String
            } else if let alertString = aps["alert"] as? String {
                body = alertString
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
            "title": title as Any,
            "body": body as Any,
            "fromBackground": fromBackground,
            "fromTerminated": fromTerminated
        ]
    }
    
    // MARK: - Stream Handler Access
    
    func setTokenEventSink(_ eventSink: FlutterEventSink?) {
        self.tokenEventSink = eventSink
    }
    
    func setNotificationEventSink(_ eventSink: FlutterEventSink?) {
        self.notificationEventSink = eventSink
    }
}

// MARK: - Stream Handlers

class TokenStreamHandler: NSObject, FlutterStreamHandler {
    private weak var plugin: KlaviyoFlutterPlugin?
    
    init(plugin: KlaviyoFlutterPlugin) {
        self.plugin = plugin
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setTokenEventSink(events)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setTokenEventSink(nil)
        return nil
    }
}

class NotificationStreamHandler: NSObject, FlutterStreamHandler {
    private weak var plugin: KlaviyoFlutterPlugin?
    
    init(plugin: KlaviyoFlutterPlugin) {
        self.plugin = plugin
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setNotificationEventSink(events)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setNotificationEventSink(nil)
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
        
        let notificationData = formatNotificationData(
            userInfo: userInfo,
            fromBackground: false,
            fromTerminated: false
        )
        
        notificationEventSink?(notificationData)
        
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    // Handle notification interaction (tap)
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle Klaviyo tracking
        KlaviyoSDK().handle(notificationResponse: response)
        
        let notificationData = formatNotificationData(
            userInfo: userInfo,
            fromBackground: UIApplication.shared.applicationState != .active,
            fromTerminated: false
        )
        
        notificationEventSink?(notificationData)
        
        completionHandler()
    }
}