import Foundation
import Cordova
import FirebaseAnalytics
import FirebaseCore
import FirebaseMessaging
import FirebaseInstallations

@objc(FirebasePlugin)
class FirebasePlugin: CDVPlugin {
    
    // MARK: - Properties (matching Android logic exactly)
    @objc var notificationCallbackId: String?
    @objc var tokenRefreshCallbackId: String?
    @objc var notificationStack: [Any] = []
    @objc var traces: [String: Any] = [:]
    @objc var dynamicLinkCallbackId: String?
    @objc var lastDynamicLinkData: [String: Any] = [:]
    
    // MARK: - Constants (matching Android)
    private static let kNotificationStackSize = 10
    private static let TAG = "FirebasePlugin"
    private static var firebasePlugin: FirebasePlugin?

    override func pluginInitialize() {
        super.pluginInitialize()
        FirebasePlugin.firebasePlugin = self
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
                    command.send(CDVPluginResult(status: .error, messageAs: error.localizedDescription))
                } else if let token = token {
                    print("\(FirebasePlugin.TAG) - FCM registration token: \(token)")
                    command.send(CDVPluginResult(status: .ok, messageAs: token))
                } else {
                    command.send(CDVPluginResult(status: .error, messageAs: "No token available"))
                }
            }
        }
    }

    @objc(getToken:)
    func getToken(_ command: CDVInvokedUrlCommand) {
        getId(command) // Same implementation as getId
    }

    @objc(hasPermission:)
    func hasPermission(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let hasPermission = settings.authorizationStatus == .authorized
                print("\(FirebasePlugin.TAG) - Has permission: \(hasPermission)")
                command.send(CDVPluginResult(status: .ok, messageAs: hasPermission))
            }
        }
    }

    @objc(grantPermission:)
    func grantPermission(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error = error {
                    print("\(FirebasePlugin.TAG) - Error requesting permission: \(error)")
                    command.send(CDVPluginResult(status: .error, messageAs: error.localizedDescription))
                } else {
                    print("\(FirebasePlugin.TAG) - Permission granted: \(granted)")
                    command.send(CDVPluginResult(status: .ok, messageAs: granted))
                }
            }
        }
    }

    @objc(setBadgeNumber:)
    func setBadgeNumber(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let number = command.arguments[0] as? Int else {
                command.send(CDVPluginResult(status: .error, messageAs: "Invalid badge number"))
                return
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = number
                print("\(FirebasePlugin.TAG) - Badge number set to: \(number)")
                command.send(CDVPluginResult(status: .ok))
            }
        }
    }

    @objc(getBadgeNumber:)
    func getBadgeNumber(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            let badgeNumber = UIApplication.shared.applicationIconBadgeNumber
            print("\(FirebasePlugin.TAG) - Current badge number: \(badgeNumber)")
            command.send(CDVPluginResult(status: .ok, messageAs: badgeNumber))
        }
    }

    @objc(subscribe:)
    func subscribe(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let topic = command.arguments[0] as? String else {
                command.send(CDVPluginResult(status: .error, messageAs: "Invalid topic"))
                return
            }
            
            Messaging.messaging().subscribe(toTopic: topic) { error in
                if let error = error {
                    print("\(FirebasePlugin.TAG) - Error subscribing to topic \(topic): \(error)")
                    command.send(CDVPluginResult(status: .error, messageAs: error.localizedDescription))
                } else {
                    print("\(FirebasePlugin.TAG) - Successfully subscribed to topic: \(topic)")
                    command.send(CDVPluginResult(status: .ok))
                }
            }
        }
    }

    @objc(unsubscribe:)
    func unsubscribe(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let topic = command.arguments[0] as? String else {
                command.send(CDVPluginResult(status: .error, messageAs: "Invalid topic"))
                return
            }
            
            Messaging.messaging().unsubscribe(fromTopic: topic) { error in
                if let error = error {
                    print("\(FirebasePlugin.TAG) - Error unsubscribing from topic \(topic): \(error)")
                    command.send(CDVPluginResult(status: .error, messageAs: error.localizedDescription))
                } else {
                    print("\(FirebasePlugin.TAG) - Successfully unsubscribed from topic: \(topic)")
                    command.send(CDVPluginResult(status: .ok))
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
                    command.send(CDVPluginResult(status: .error, messageAs: error.localizedDescription))
                } else {
                    print("\(FirebasePlugin.TAG) - Token deleted successfully")
                    command.send(CDVPluginResult(status: .ok))
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
                command.send(CDVPluginResult(status: .ok))
            }
        }
    }

    // MARK: - Analytics
    @objc(logEvent:)
    func logEvent(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let name = command.arguments[0] as? String,
                  let parameters = command.arguments[1] as? [String: Any] else {
                command.send(CDVPluginResult(status: .error, messageAs: "Invalid arguments for logEvent"))
                return
            }
            
            print("\(FirebasePlugin.TAG) - Logging event: \(name) with parameters: \(parameters)")
            
            // Send real event to Firebase Analytics
            Analytics.logEvent(name, parameters: parameters)
            
            command.send(CDVPluginResult(status: .ok))
        }
    }

    @objc(setScreenName:)
    func setScreenName(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let name = command.arguments[0] as? String else {
                command.send(CDVPluginResult(status: .error, messageAs: "Invalid screen name"))
                return
            }
            
            print("\(FirebasePlugin.TAG) - Setting screen name: \(name)")
            
            // Set screen name in Firebase Analytics
            Analytics.setScreenName(name, screenClass: nil)
            
            command.send(CDVPluginResult(status: .ok))
        }
    }

    @objc(setUserId:)
    func setUserId(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let userId = command.arguments[0] as? String else {
                command.send(CDVPluginResult(status: .error, messageAs: "Invalid user ID"))
                return
            }
            
            print("\(FirebasePlugin.TAG) - Setting user ID: \(userId)")
            
            // Set user ID in Firebase Analytics
            Analytics.setUserID(userId)
            
            command.send(CDVPluginResult(status: .ok))
        }
    }

    @objc(setUserProperty:)
    func setUserProperty(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let name = command.arguments[0] as? String,
                  let value = command.arguments[1] as? String else {
                command.send(CDVPluginResult(status: .error, messageAs: "Invalid user property arguments"))
                return
            }
            
            print("\(FirebasePlugin.TAG) - Setting user property: \(name) = \(value)")
            
            // Set user property in Firebase Analytics
            Analytics.setUserProperty(value, forName: name)
            
            command.send(CDVPluginResult(status: .ok))
        }
    }

    @objc(setAnalyticsCollectionEnabled:)
    func setAnalyticsCollectionEnabled(_ command: CDVInvokedUrlCommand) {
        commandDelegate.run {
            guard let enabled = command.arguments[0] as? Bool else {
                command.send(CDVPluginResult(status: .error, messageAs: "Invalid enabled parameter"))
                return
            }
            
            print("\(FirebasePlugin.TAG) - Setting analytics collection enabled: \(enabled)")
            
            // Set analytics collection enabled in Firebase Analytics
            Analytics.setAnalyticsCollectionEnabled(enabled)
            
            command.send(CDVPluginResult(status: .ok))
        }
    }

    @objc(isFirebaseInitialized:)
    func isFirebaseInitialized(_ command: CDVInvokedUrlCommand) {
        print("\(FirebasePlugin.TAG) - Checking if Firebase is initialized")
        let isInitialized = FirebaseApp.app() != nil
        print("\(FirebasePlugin.TAG) - Firebase initialized: \(isInitialized ? "YES" : "NO")")
        command.send(CDVPluginResult(status: .ok, messageAs: isInitialized ? 1 : 0))
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
                command.send(CDVPluginResult(status: .ok, messageAs: dynamicLinkData))
            } else {
                print("\(FirebasePlugin.TAG) - No dynamic link data available")
                command.send(CDVPluginResult(status: .ok, messageAs: NSNull()))
            }
        }
    }
}

// MARK: - CDVInvokedUrlCommand Extension
extension CDVInvokedUrlCommand {
    func send(_ result: CDVPluginResult) {
        // This is a helper method to send plugin results
        // The actual implementation would depend on the Cordova framework version
    }
}
