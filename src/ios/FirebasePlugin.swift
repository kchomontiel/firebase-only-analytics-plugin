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
        getId(command)
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
            
            // Set screen name in Firebase Analytics
            Analytics.setScreenName(name, screenClass: nil)
            
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
            if let dynamicLinkData = lastDynamicLinkData as? [String: Any], !dynamicLinkData.isEmpty {
                print("\(FirebasePlugin.TAG) - Returning cached dynamic link data")
                let result = CDVPluginResult(status: .ok, messageAs: dynamicLinkData)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } else {
                print("\(FirebasePlugin.TAG) - No dynamic link data available")
                let result = CDVPluginResult(status: .ok, messageAs: NSNull())
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }
}
