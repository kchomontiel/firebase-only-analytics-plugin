import Foundation
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import objc

// MARK: - AppDelegate Extension for Firebase Plugin
extension AppDelegate {
    
    // MARK: - Associated Objects Keys
    private static let kApplicationInBackgroundKey = "applicationInBackground"
    private static let kDelegateKey = "delegate"
    
    // MARK: - Associated Objects Properties
    @objc var applicationInBackground: NSNumber? {
        get {
            return objc_getAssociatedObject(self, &AppDelegate.kApplicationInBackgroundKey) as? NSNumber
        }
        set {
            objc_setAssociatedObject(self, &AppDelegate.kApplicationInBackgroundKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc var delegate: Any? {
        get {
            return objc_getAssociatedObject(self, &AppDelegate.kDelegateKey)
        }
        set {
            objc_setAssociatedObject(self, &AppDelegate.kDelegateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - Method Swizzling (matching Objective-C logic)
    @objc static func swizzleMethods() {
        // Swizzle application:didFinishLaunchingWithOptions:
        let originalMethod = class_getInstanceMethod(self, #selector(application(_:didFinishLaunchingWithOptions:)))
        let swizzledMethod = class_getInstanceMethod(self, #selector(application(_:swizzledDidFinishLaunchingWithOptions:)))
        
        if let original = originalMethod, let swizzled = swizzledMethod {
            method_exchangeImplementations(original, swizzled)
        }
        
        // Swizzle application:openURL:options: for Dynamic Links
        let originalDLMethod = class_getInstanceMethod(self, #selector(application(_:open:options:)))
        let swizzledDLMethod = class_getInstanceMethod(self, #selector(swizzled_application(_:open:options:)))
        
        if let originalDL = originalDLMethod, let swizzledDL = swizzledDLMethod {
            method_exchangeImplementations(originalDL, swizzledDL)
        }
        
        // Swizzle application:continueUserActivity:restorationHandler: for Dynamic Links
        let originalMDLMethod = class_getInstanceMethod(self, #selector(application(_:continue:restorationHandler:)))
        let swizzledMDLMethod = class_getInstanceMethod(self, #selector(swizzled_application(_:continue:restorationHandler:)))
        
        if let originalMDL = originalMDLMethod, let swizzledMDL = swizzledMDLMethod {
            method_exchangeImplementations(originalMDL, swizzledMDL)
        }
    }
    
    // MARK: - Dynamic Links Methods (matching Objective-C logic)
    @objc func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return false
    }
    
    @objc func swizzled_application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Always call original method implementation first
        let handled = self.swizzled_application(app, open: url, options: options)
        
        // Get FirebasePlugin instance
        if let viewController = self.window?.rootViewController as? CDVViewController,
           let firebasePlugin = viewController.getCommandInstance("FirebasePlugin") as? FirebasePlugin {
            
            // Parse Firebase Dynamic Link
            DynamicLinks.dynamicLinks().handleUniversalLink(url) { dynamicLink, error in
                if let dynamicLink = dynamicLink {
                    firebasePlugin.postDynamicLink(dynamicLink)
                }
            }
            return true
        }
        
        return handled
    }
    
    @objc func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return false
    }
    
    @objc func swizzled_application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Always call original method implementation first
        let handled = self.swizzled_application(application, continue: userActivity, restorationHandler: restorationHandler)
        
        // Get FirebasePlugin instance
        if let viewController = self.window?.rootViewController as? CDVViewController,
           let firebasePlugin = viewController.getCommandInstance("FirebasePlugin") as? FirebasePlugin,
           let url = userActivity.webpageURL {
            
            // Handle Firebase Dynamic Link
            return DynamicLinks.dynamicLinks().handleUniversalLink(url) { dynamicLink, error in
                if let dynamicLink = dynamicLink {
                    firebasePlugin.postDynamicLink(dynamicLink)
                } else {
                    // Try alternative method
                    DynamicLinks.dynamicLinks().dynamicLink(fromUniversalLink: url) { dynamicLink, error in
                        if let dynamicLink = dynamicLink {
                            firebasePlugin.postDynamicLink(dynamicLink)
                        }
                    }
                }
            } || handled
        }
        
        return handled
    }
    
    // MARK: - App Lifecycle Methods (matching Objective-C logic)
    @objc func application(_ application: UIApplication, swizzledDidFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("FirebasePlugin - Finished launching")
        
        // Call original method
        let result = self.application(application, swizzledDidFinishLaunchingWithOptions: launchOptions)
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set up messaging delegate
        Messaging.messaging().delegate = self
        
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        // Add observer for token refresh
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(tokenRefreshNotification(_:)),
            name: .InstanceIDTokenRefresh,
            object: nil
        )
        
        self.applicationInBackground = NSNumber(value: true)
        
        return result
    }
    
    @objc func applicationDidBecomeActive(_ application: UIApplication) {
        self.applicationInBackground = NSNumber(value: false)
    }
    
    @objc func applicationDidEnterBackground(_ application: UIApplication) {
        self.applicationInBackground = NSNumber(value: true)
    }
    
    // MARK: - Token Refresh (matching Objective-C logic)
    @objc func tokenRefreshNotification(_ notification: Notification) {
        // Get instance ID token
        InstanceID.instanceID().instanceID { result, error in
            var token: String?
            if let result = result, error == nil {
                token = result.token
            }
            
            // Send token to FirebasePlugin
            if let viewController = self.window?.rootViewController as? CDVViewController,
               let firebasePlugin = viewController.getCommandInstance("FirebasePlugin") as? FirebasePlugin {
                firebasePlugin.sendToken(token)
            }
        }
    }
    
    // MARK: - Remote Notifications (matching Objective-C logic)
    @objc func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("FirebasePlugin - deviceToken1 = \(deviceToken)")
    }
    
    @objc func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        var mutableUserInfo = userInfo
        mutableUserInfo["tap"] = self.applicationInBackground
        
        print("FirebasePlugin - didReceiveRemoteNotification - before")
        print("FirebasePlugin - Response \(mutableUserInfo)")
        print("FirebasePlugin - didReceiveRemoteNotification - after")
        
        // Send notification to FirebasePlugin
        if let viewController = self.window?.rootViewController as? CDVViewController,
           let firebasePlugin = viewController.getCommandInstance("FirebasePlugin") as? FirebasePlugin {
            firebasePlugin.sendNotification(mutableUserInfo)
        }
    }
    
    @objc func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        var mutableUserInfo = userInfo
        mutableUserInfo["tap"] = self.applicationInBackground
        
        print("FirebasePlugin - didReceiveRemoteNotification:fetchCompletionHandler - before")
        print("FirebasePlugin - Response \(mutableUserInfo)")
        print("FirebasePlugin - didReceiveRemoteNotification:fetchCompletionHandler - after")
        
        completionHandler(.newData)
        
        // Send notification to FirebasePlugin
        if let viewController = self.window?.rootViewController as? CDVViewController,
           let firebasePlugin = viewController.getCommandInstance("FirebasePlugin") as? FirebasePlugin {
            firebasePlugin.sendNotification(mutableUserInfo)
        }
    }
    
    @objc func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("FirebasePlugin - Unable to register for remote notifications: \(error)")
    }
}

// MARK: - UNUserNotificationCenterDelegate (matching Objective-C logic)
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    @objc func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("FirebasePlugin - willPresentNotification:withCompletionHandler - 1")
        
        // Call delegate if available
        if let delegate = self.delegate as? UNUserNotificationCenterDelegate {
            delegate.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
        }
        
        // Check if it's a push notification
        guard notification.request.trigger is UNPushNotificationTrigger else {
            return
        }
        
        var mutableUserInfo = notification.request.content.userInfo
        mutableUserInfo["tap"] = self.applicationInBackground
        
        print("FirebasePlugin - willPresentNotification:withCompletionHandler - before")
        print("FirebasePlugin - Response \(mutableUserInfo)")
        print("FirebasePlugin - willPresentNotification:withCompletionHandler - after")
        
        completionHandler(.alert)
        
        // Send notification to FirebasePlugin
        if let viewController = self.window?.rootViewController as? CDVViewController,
           let firebasePlugin = viewController.getCommandInstance("FirebasePlugin") as? FirebasePlugin {
            firebasePlugin.sendNotification(mutableUserInfo)
        }
    }
    
    @objc func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("FirebasePlugin - didReceiveNotificationResponse:withCompletionHandler - 1")
        
        // Call delegate if available
        if let delegate = self.delegate as? UNUserNotificationCenterDelegate {
            delegate.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
        }
        
        // Check if it's a push notification
        guard response.notification.request.trigger is UNPushNotificationTrigger else {
            return
        }
        
        var mutableUserInfo = response.notification.request.content.userInfo
        mutableUserInfo["tap"] = NSNumber(value: true)
        
        print("FirebasePlugin - didReceiveNotificationResponse:withCompletionHandler - before")
        print("FirebasePlugin - Response \(mutableUserInfo)")
        print("FirebasePlugin - didReceiveNotificationResponse:withCompletionHandler - after")
        
        // Send notification to FirebasePlugin
        if let viewController = self.window?.rootViewController as? CDVViewController,
           let firebasePlugin = viewController.getCommandInstance("FirebasePlugin") as? FirebasePlugin {
            firebasePlugin.sendNotification(mutableUserInfo)
        }
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate (matching Objective-C logic)
extension AppDelegate: MessagingDelegate {
    
    @objc func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FirebasePlugin - FCM registration token: \(fcmToken ?? "nil")")
        
        // Send token to FirebasePlugin
        if let viewController = self.window?.rootViewController as? CDVViewController,
           let firebasePlugin = viewController.getCommandInstance("FirebasePlugin") as? FirebasePlugin {
            firebasePlugin.sendToken(fcmToken)
        }
    }
}

// MARK: - Load Method (matching Objective-C logic)
extension AppDelegate {
    @objc static func load() {
        swizzleMethods()
    }
}
