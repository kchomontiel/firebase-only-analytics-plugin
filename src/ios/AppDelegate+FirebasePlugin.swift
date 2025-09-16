import Foundation
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import ObjectiveC

// MARK: - AppDelegate Extension for Firebase Plugin
extension AppDelegate {
    
    // MARK: - Associated Objects Keys
    private static let kApplicationInBackgroundKey = "applicationInBackground"
    
    // MARK: - Associated Objects Properties
    @objc var applicationInBackground: NSNumber? {
        get { return objc_getAssociatedObject(self, &AppDelegate.kApplicationInBackgroundKey) as? NSNumber }
        set { objc_setAssociatedObject(self, &AppDelegate.kApplicationInBackgroundKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FirebasePlugin - FCM registration token: \(fcmToken ?? "nil")")
        
        // Notify JavaScript if callback is registered
        if let plugin = FirebasePlugin.firebasePlugin,
           let callbackId = plugin.tokenRefreshCallbackId {
            let result = CDVPluginResult(status: .ok, messageAs: fcmToken)
            plugin.commandDelegate.send(result, callbackId: callbackId)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("FirebasePlugin - Will present notification: \(notification.request.content.userInfo)")
        
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("FirebasePlugin - Did receive notification response: \(response.notification.request.content.userInfo)")
        
        // Notify JavaScript if callback is registered
        if let plugin = FirebasePlugin.firebasePlugin,
           let callbackId = plugin.notificationCallbackId {
            let userInfo = response.notification.request.content.userInfo
            let result = CDVPluginResult(status: .ok, messageAs: userInfo)
            plugin.commandDelegate.send(result, callbackId: callbackId)
        }
        
        completionHandler()
    }
}

// MARK: - Static reference to FirebasePlugin
extension FirebasePlugin {
    static var firebasePlugin: FirebasePlugin?
}
