import UIKit
import Flutter
import KlaviyoSwift

// This is a helper class that can be used in the iOS app's AppDelegate
// to properly handle push notifications with Klaviyo
public class KlaviyoAppDelegate {
    
  // Call this method from application:didRegisterForRemoteNotificationsWithDeviceToken:
  @discardableResult
  public static func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) -> Bool {
    KlaviyoSDK().set(pushToken: deviceToken)
    return true
  }
  
  // Call this method from userNotificationCenter:didReceive:withCompletionHandler:
  @discardableResult
  public static func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) -> Bool {
    let handled = KlaviyoSDK().handle(notificationResponse: response, withCompletionHandler: completionHandler)
    return handled
  }
  
  // Call this method from userNotificationCenter:willPresent:withCompletionHandler:
  @discardableResult
  public static func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) -> Bool {
    if #available(iOS 14.0, *) {
      completionHandler([.list, .banner])
    } else {
      completionHandler([.alert])
    }
    return true
  }
} 