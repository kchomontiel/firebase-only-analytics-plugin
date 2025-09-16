import Foundation
import FirebaseAnalytics
import FirebaseCore
import FirebaseMessaging
import FirebaseInstallations

@objc(FirebasePlugin)
class FirebasePlugin: CDVPlugin {
    
    // MARK: - Properties
    @objc var notificationCallbackId: String?
    @objc var tokenRefreshCallbackId: String?
    @objc var notificationStack: [Any] = []
    @objc var traces: [String: Any] = [:]
    @objc var dynamicLinkCallbackId: String?
    @objc var lastDynamicLinkData: [String: Any] = [:]
    
    // MARK: - Constants
    private static let kNotificationStackSize = 10
    private static let TAG = "FirebasePlugin"

    override func pluginInitialize() {
        super.pluginInitialize()
        print("\(FirebasePlugin.TAG) - Starting Firebase plugin initialization")
        
        // Initialize Firebase Analytics synchronously
        do {
            FirebaseApp.configure()
            print("\(FirebasePlugin.TAG) - Firebase App configured successfully")
        } catch {
            print("\(FirebasePlugin.TAG) - Failed to configure Firebase App: \(error.localizedDescription)")
        }
    }

    // MARK: - Cloud Messaging FCM
    @objc(getId:)
    func getId(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("\(FirebasePlugin.TAG) - Error fetching FCM registration token: \(error)")
                    let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                } else if let token = token {
                    print("\(FirebasePlugin.TAG) - FCM registration token: \(token)")
                    let result = CDVPluginResult(status: .ok, messageAs: token)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                } else {
                    let result = CDVPluginResult(status: .error, messageAs: "No token available")
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                }
            }
        }
    }

    @objc(getToken:)
    func getToken(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            // ✅ FIREBASE 11.15.0 FIX: Verify APNS token before FCM token
            print("\(FirebasePlugin.TAG) - Checking APNS token availability...")
            
            // Check if APNS token is available
            if Messaging.messaging().apnsToken == nil {
                print("\(FirebasePlugin.TAG) - APNS token not available, forcing registration...")
                
                // Check notification permissions first
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    if settings.authorizationStatus == .notDetermined {
                        print("\(FirebasePlugin.TAG) - APNS not configured, requesting permissions...")
                        // Request permissions and register for remote notifications
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                            if granted {
                                print("\(FirebasePlugin.TAG) - Permissions granted, registering for remote notifications...")
                                DispatchQueue.main.async {
                                    UIApplication.shared.registerForRemoteNotifications()
                                }
                                // Wait for APNS token
                                self.waitForAPNSTokenAndGetFCM(command)
                            } else {
                                let result = CDVPluginResult(status: .error, messageAs: "APNS permission denied")
                                self.commandDelegate.send(result, callbackId: command.callbackId)
                            }
                        }
                    } else {
                        // Permissions granted but APNS token not ready, force register
                        print("\(FirebasePlugin.TAG) - Permissions granted, forcing remote notification registration...")
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                        // Wait for APNS token
                        self.waitForAPNSTokenAndGetFCM(command)
                    }
                }
            } else {
                print("\(FirebasePlugin.TAG) - APNS token available, getting FCM token...")
                // APNS token available, get FCM token
                self.getFCMToken(command)
            }
        }
    }
    
    private func waitForAPNSTokenAndGetFCM(_ command: CDVInvokedUrlCommand) {
        var attempts = 0
        let maxAttempts = 20
        let delay = 1.0
        
        func checkAPNS() {
            attempts += 1
            print("\(FirebasePlugin.TAG) - APNS token check attempt \(attempts)/\(maxAttempts)")
            
            if Messaging.messaging().apnsToken != nil {
                print("\(FirebasePlugin.TAG) - APNS token ready, getting FCM token")
                self.getFCMToken(command)
            } else if attempts < maxAttempts {
                // Force re-registration every 5 attempts
                if attempts % 5 == 0 {
                    print("\(FirebasePlugin.TAG) - Forcing re-registration for remote notifications (attempt \(attempts))")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    checkAPNS()
                }
            } else {
                print("\(FirebasePlugin.TAG) - APNS token timeout after \(maxAttempts) attempts")
                let result = CDVPluginResult(status: .error, messageAs: "APNS token not available after \(maxAttempts) seconds. Please check device network and notification settings.")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
        
        checkAPNS()
    }
    
    private func getFCMToken(_ command: CDVInvokedUrlCommand) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("\(FirebasePlugin.TAG) - Error fetching FCM registration token: \(error)")
                let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } else if let token = token {
                print("\(FirebasePlugin.TAG) - FCM registration token: \(token)")
                let result = CDVPluginResult(status: .ok, messageAs: token)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } else {
                let result = CDVPluginResult(status: .error, messageAs: "No token available")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    @objc(hasPermission:)
    func hasPermission(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let hasPermission = settings.authorizationStatus == .authorized
                print("\(FirebasePlugin.TAG) - Has permission: \(hasPermission)")
                let result = CDVPluginResult(status: .ok, messageAs: hasPermission)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    @objc(grantPermission:)
    func grantPermission(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error = error {
                    print("\(FirebasePlugin.TAG) - Error requesting permission: \(error)")
                    let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                } else {
                    print("\(FirebasePlugin.TAG) - Permission granted: \(granted)")
                    let result = CDVPluginResult(status: .ok, messageAs: granted)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                }
            }
        }
    }

    @objc(setBadgeNumber:)
    func setBadgeNumber(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let number = command.arguments[0] as? Int else {
                let result = CDVPluginResult(status: .error, messageAs: "Invalid badge number")
                self.commandDelegate.send(result, callbackId: command.callbackId)
                return
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = number
                print("\(FirebasePlugin.TAG) - Badge number set to: \(number)")
                let result = CDVPluginResult(status: .ok)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    @objc(getBadgeNumber:)
    func getBadgeNumber(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            let badgeNumber = UIApplication.shared.applicationIconBadgeNumber
            print("\(FirebasePlugin.TAG) - Current badge number: \(badgeNumber)")
            let result = CDVPluginResult(status: .ok, messageAs: badgeNumber)
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }

    @objc(subscribe:)
    func subscribe(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let topic = command.arguments[0] as? String else {
                let result = CDVPluginResult(status: .error, messageAs: "Invalid topic")
                self.commandDelegate.send(result, callbackId: command.callbackId)
                return
            }
            
            Messaging.messaging().subscribe(toTopic: topic) { error in
                if let error = error {
                    print("\(FirebasePlugin.TAG) - Error subscribing to topic \(topic): \(error)")
                    let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                } else {
                    print("\(FirebasePlugin.TAG) - Successfully subscribed to topic: \(topic)")
                    let result = CDVPluginResult(status: .ok)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                }
            }
        }
    }

    @objc(unsubscribe:)
    func unsubscribe(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let topic = command.arguments[0] as? String else {
                let result = CDVPluginResult(status: .error, messageAs: "Invalid topic")
                self.commandDelegate.send(result, callbackId: command.callbackId)
                return
            }
            
            Messaging.messaging().unsubscribe(fromTopic: topic) { error in
                if let error = error {
                    print("\(FirebasePlugin.TAG) - Error unsubscribing from topic \(topic): \(error)")
                    let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                } else {
                    print("\(FirebasePlugin.TAG) - Successfully unsubscribed from topic: \(topic)")
                    let result = CDVPluginResult(status: .ok)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                }
            }
        }
    }

    @objc(unregister:)
    func unregister(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            Messaging.messaging().deleteToken { error in
                if let error = error {
                    print("\(FirebasePlugin.TAG) - Error deleting token: \(error)")
                    let result = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                } else {
                    print("\(FirebasePlugin.TAG) - Token deleted successfully")
                    let result = CDVPluginResult(status: .ok)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                }
            }
        }
    }

    @objc(onNotificationOpen:)
    func onNotificationOpen(_ command: CDVInvokedUrlCommand) {
        notificationCallbackId = command.callbackId
        print("\(FirebasePlugin.TAG) - Notification callback registered")
    }

    @objc(onTokenRefresh:)
    func onTokenRefresh(_ command: CDVInvokedUrlCommand) {
        tokenRefreshCallbackId = command.callbackId
        print("\(FirebasePlugin.TAG) - Token refresh callback registered")
    }

    @objc(clearAllNotifications:)
    func clearAllNotifications(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                print("\(FirebasePlugin.TAG) - All notifications cleared")
                let result = CDVPluginResult(status: .ok)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    // MARK: - Analytics
    @objc(logEvent:)
    func logEvent(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let name = command.arguments[0] as? String,
                  let parameters = command.arguments[1] as? [String: Any] else {
                let result = CDVPluginResult(status: .error, messageAs: "Invalid arguments for logEvent")
                self.commandDelegate.send(result, callbackId: command.callbackId)
                return
            }
            
            print("\(FirebasePlugin.TAG) - Logging event: \(name) with parameters: \(parameters)")
            
            // Send real event to Firebase Analytics
            Analytics.logEvent(name, parameters: parameters)
            
            let result = CDVPluginResult(status: .ok)
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }

    @objc(setScreenName:)
    func setScreenName(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let name = command.arguments[0] as? String else {
                let result = CDVPluginResult(status: .error, messageAs: "Invalid screen name")
                self.commandDelegate.send(result, callbackId: command.callbackId)
                return
            }
            
            print("\(FirebasePlugin.TAG) - Setting screen name: \(name)")
            
            // FIXED: Use logEvent instead of deprecated setScreenName
            // Firebase 11 removed setScreenName, use logEvent with screen_view
            Analytics.logEvent("screen_view", parameters: [
                "screen_name": name,
                "screen_class": "Screen"
            ])
            
            let result = CDVPluginResult(status: .ok)
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }

    @objc(setUserId:)
    func setUserId(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let userId = command.arguments[0] as? String else {
                let result = CDVPluginResult(status: .error, messageAs: "Invalid user ID")
                self.commandDelegate.send(result, callbackId: command.callbackId)
                return
            }
            
            print("\(FirebasePlugin.TAG) - Setting user ID: \(userId)")
            
            // Set user ID in Firebase Analytics
            Analytics.setUserID(userId)
            
            let result = CDVPluginResult(status: .ok)
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }

    @objc(setUserProperty:)
    func setUserProperty(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let name = command.arguments[0] as? String,
                  let value = command.arguments[1] as? String else {
                let result = CDVPluginResult(status: .error, messageAs: "Invalid user property arguments")
                self.commandDelegate.send(result, callbackId: command.callbackId)
                return
            }
            
            print("\(FirebasePlugin.TAG) - Setting user property: \(name) = \(value)")
            
            // Set user property in Firebase Analytics
            Analytics.setUserProperty(value, forName: name)
            
            let result = CDVPluginResult(status: .ok)
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }

    @objc(setAnalyticsCollectionEnabled:)
    func setAnalyticsCollectionEnabled(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let enabled = command.arguments[0] as? Bool else {
                let result = CDVPluginResult(status: .error, messageAs: "Invalid enabled parameter")
                self.commandDelegate.send(result, callbackId: command.callbackId)
                return
            }
            
            print("\(FirebasePlugin.TAG) - Setting analytics collection enabled: \(enabled)")
            
            // Set analytics collection enabled in Firebase Analytics
            Analytics.setAnalyticsCollectionEnabled(enabled)
            
            let result = CDVPluginResult(status: .ok)
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }

    @objc(isFirebaseInitialized:)
    func isFirebaseInitialized(_ command: CDVInvokedUrlCommand) {
        print("\(FirebasePlugin.TAG) - Checking if Firebase is initialized")
        let isInitialized = FirebaseApp.app() != nil
        print("\(FirebasePlugin.TAG) - Firebase initialized: \(isInitialized ? "YES" : "NO")")
        let result = CDVPluginResult(status: .ok, messageAs: isInitialized ? 1 : 0)
        commandDelegate.send(result, callbackId: command.callbackId)
    }

    // MARK: - Dynamic Links
    @objc(onDynamicLink:)
    func onDynamicLink(_ command: CDVInvokedUrlCommand) {
        dynamicLinkCallbackId = command.callbackId
        print("\(FirebasePlugin.TAG) - Dynamic link callback registered")
    }

    @objc(getDynamicLink:)
    func getDynamicLink(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            if let dynamicLinkData = self.lastDynamicLinkData as? [String: Any], !dynamicLinkData.isEmpty {
                print("\(FirebasePlugin.TAG) - Returning cached dynamic link data")
                let result = CDVPluginResult(status: .ok, messageAs: dynamicLinkData)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } else {
                print("\(FirebasePlugin.TAG) - No dynamic link data available")
                // FIXED: Use empty string instead of nil for CDVPluginResult compatibility
                let result = CDVPluginResult(status: .ok, messageAs: "")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }
}
