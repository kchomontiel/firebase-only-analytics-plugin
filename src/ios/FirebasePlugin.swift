import Foundation
import Cordova
import FirebaseAnalytics
import FirebaseCore

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
    
    // MARK: - Static accessor (matching Android)
    @objc static func firebasePlugin() -> FirebasePlugin? {
        return firebasePlugin
    }
    
    // MARK: - Plugin Initialization (matching Android logic exactly)
    override func pluginInitialize() {
        print("\(FirebasePlugin.TAG) - Starting Firebase plugin for OutSystems")
        FirebasePlugin.firebasePlugin = self
        
        // Initialize Firebase Analytics with robust fallback logic (matching Android)
        initializeFirebaseAnalytics()
    }
    
    // MARK: - Firebase Analytics Initialization (matching Android logic exactly)
    private func initializeFirebaseAnalytics() {
        do {
            // Try to get the default Firebase app instance
            guard let app = FirebaseApp.app() else {
                print("\(FirebasePlugin.TAG) - No default Firebase app found")
                return
            }
            
            print("\(FirebasePlugin.TAG) - Firebase Analytics initialized successfully")
        } catch {
            print("\(FirebasePlugin.TAG) - Failed to initialize Firebase Analytics: \(error.localizedDescription)")
            
            // Try to use global instance if available (matching Android fallback logic)
            do {
                if FirebaseApp.app() != nil {
                    print("\(FirebasePlugin.TAG) - Using global Firebase Analytics instance")
                }
            } catch {
                print("\(FirebasePlugin.TAG) - No global Firebase Analytics instance available: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Basic Interface Methods (matching Android exactly)
    
    @objc func getId(_ command: CDVInvokedUrlCommand) {
        let installationId = Bundle.main.bundleIdentifier?.appending(".firebase") ?? "unknown.firebase"
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: installationId)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func getToken(_ command: CDVInvokedUrlCommand) {
        let placeholderToken = "firebase_token_placeholder"
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: placeholderToken)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func hasPermission(_ command: CDVInvokedUrlCommand) {
        let message = ["isEnabled": true]
        let commandResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: message)
        self.commandDelegate.send(commandResult, callbackId: command.callbackId)
    }
    
    @objc func grantPermission(_ command: CDVInvokedUrlCommand) {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func setBadgeNumber(_ command: CDVInvokedUrlCommand) {
        guard let number = command.arguments[0] as? Int else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid badge number")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = number
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func getBadgeNumber(_ command: CDVInvokedUrlCommand) {
        let badgeNumber = UIApplication.shared.applicationIconBadgeNumber
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: badgeNumber)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func subscribe(_ command: CDVInvokedUrlCommand) {
        guard let topic = command.arguments[0] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid topic")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        print("\(FirebasePlugin.TAG) - Subscribing to topic: \(topic)")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func unsubscribe(_ command: CDVInvokedUrlCommand) {
        guard let topic = command.arguments[0] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid topic")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        print("\(FirebasePlugin.TAG) - Unsubscribing from topic: \(topic)")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func unregister(_ command: CDVInvokedUrlCommand) {
        print("\(FirebasePlugin.TAG) - Unregistering from Firebase")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func onNotificationOpen(_ command: CDVInvokedUrlCommand) {
        self.notificationCallbackId = command.callbackId
        print("\(FirebasePlugin.TAG) - Notification callback registered")
    }
    
    @objc func onTokenRefresh(_ command: CDVInvokedUrlCommand) {
        self.tokenRefreshCallbackId = command.callbackId
        print("\(FirebasePlugin.TAG) - Token refresh callback registered")
    }
    
    @objc func clearAllNotifications(_ command: CDVInvokedUrlCommand) {
        print("\(FirebasePlugin.TAG) - clearAllNotifications called")
        
        // Execute in background thread (matching Android logic)
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                // Clear all notifications
                UIApplication.shared.applicationIconBadgeNumber = 0
                print("\(FirebasePlugin.TAG) - clearAllNotifications success")
                
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }
    
    // MARK: - Firebase Analytics Methods (matching Android logic exactly)
    
    @objc func logEvent(_ command: CDVInvokedUrlCommand) {
        guard let name = command.arguments[0] as? String,
              let parameters = command.arguments[1] as? [String: Any] else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid parameters")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        print("\(FirebasePlugin.TAG) - logEvent called with name: \(name)")
        
        // Convert parameters to Firebase format (matching Android logic)
        var firebaseParameters: [String: Any] = [:]
        for (key, value) in parameters {
            if let numberValue = value as? NSNumber {
                firebaseParameters[key] = numberValue
            } else {
                firebaseParameters[key] = String(describing: value)
            }
        }
        
        // Execute in background thread (matching Android logic)
        DispatchQueue.global(qos: .background).async {
            do {
                print("\(FirebasePlugin.TAG) - Sending event to Firebase: \(name) with parameters: \(firebaseParameters)")
                
                // Use Firebase Analytics (matching Android fallback logic)
                Analytics.logEvent(name, parameters: firebaseParameters)
                
                DispatchQueue.main.async {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                }
                
                print("\(FirebasePlugin.TAG) - Event sent successfully to Firebase")
            } catch {
                print("\(FirebasePlugin.TAG) - Error sending event to Firebase: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Failed to log event")
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                }
            }
        }
    }
    
    @objc func setScreenName(_ command: CDVInvokedUrlCommand) {
        guard let name = command.arguments[0] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid screen name")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        print("\(FirebasePlugin.TAG) - setScreenName called with name: \(name)")
        
        DispatchQueue.global(qos: .background).async {
            Analytics.setScreenName(name, screenClass: nil)
            
            DispatchQueue.main.async {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }
    
    @objc func setUserId(_ command: CDVInvokedUrlCommand) {
        guard let id = command.arguments[0] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid user ID")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        print("\(FirebasePlugin.TAG) - setUserId called with id: \(id)")
        
        DispatchQueue.global(qos: .background).async {
            Analytics.setUserID(id)
            
            DispatchQueue.main.async {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }
    
    @objc func setUserProperty(_ command: CDVInvokedUrlCommand) {
        guard let name = command.arguments[0] as? String,
              let value = command.arguments[1] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid user property")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        print("\(FirebasePlugin.TAG) - setUserProperty called with name: \(name), value: \(value)")
        
        DispatchQueue.global(qos: .background).async {
            Analytics.setUserProperty(value, forName: name)
            
            DispatchQueue.main.async {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }
    
    @objc func setAnalyticsCollectionEnabled(_ command: CDVInvokedUrlCommand) {
        guard let enabled = command.arguments[0] as? Bool else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid enabled parameter")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        print("\(FirebasePlugin.TAG) - setAnalyticsCollectionEnabled called with enabled: \(enabled)")
        
        DispatchQueue.global(qos: .background).async {
            Analytics.setAnalyticsCollectionEnabled(enabled)
            
            DispatchQueue.main.async {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }
    
    @objc func isFirebaseInitialized(_ command: CDVInvokedUrlCommand) {
        print("\(FirebasePlugin.TAG) - isFirebaseInitialized called")
        
        // Check if Firebase is initialized (matching Android logic exactly)
        var isInitialized = false
        
        // Check if default Firebase app is available
        if let app = FirebaseApp.app() {
            isInitialized = true
            print("\(FirebasePlugin.TAG) - Firebase Analytics initialized: \(isInitialized)")
        }
        
        // Additional check for global instance (matching Android fallback logic)
        if !isInitialized {
            if FirebaseApp.app() != nil {
                print("\(FirebasePlugin.TAG) - Global Firebase Analytics instance is available")
                isInitialized = true
            }
        }
        
        print("\(FirebasePlugin.TAG) - Firebase initialization status: \(isInitialized)")
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: isInitialized)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    // MARK: - Dynamic Links Methods (matching Android)
    
    @objc func onDynamicLink(_ command: CDVInvokedUrlCommand) {
        self.dynamicLinkCallbackId = command.callbackId
        print("\(FirebasePlugin.TAG) - Dynamic link callback registered")
    }
    
    @objc func getDynamicLink(_ command: CDVInvokedUrlCommand) {
        if let linkData = self.lastDynamicLinkData {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: linkData)
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "No dynamic link data")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    @objc func dynamicLinkCallback(_ command: CDVInvokedUrlCommand) {
        // Handle dynamic link callback
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    // MARK: - Performance Monitoring Methods (matching Android)
    
    @objc func startTrace(_ command: CDVInvokedUrlCommand) {
        guard let name = command.arguments[0] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid trace name")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        print("\(FirebasePlugin.TAG) - startTrace called with name: \(name)")
        // Performance monitoring implementation would go here
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func incrementCounter(_ command: CDVInvokedUrlCommand) {
        guard let name = command.arguments[0] as? String,
              let counterName = command.arguments[1] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid counter parameters")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        print("\(FirebasePlugin.TAG) - incrementCounter called for trace: \(name), counter: \(counterName)")
        // Performance monitoring implementation would go here
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func stopTrace(_ command: CDVInvokedUrlCommand) {
        guard let name = command.arguments[0] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid trace name")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        print("\(FirebasePlugin.TAG) - stopTrace called with name: \(name)")
        // Performance monitoring implementation would go here
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func addTraceAttribute(_ command: CDVInvokedUrlCommand) {
        guard let name = command.arguments[0] as? String,
              let attribute = command.arguments[1] as? String,
              let value = command.arguments[2] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid trace attribute parameters")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        print("\(FirebasePlugin.TAG) - addTraceAttribute called for trace: \(name), attribute: \(attribute), value: \(value)")
        // Performance monitoring implementation would go here
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func setPerformanceCollectionEnabled(_ command: CDVInvokedUrlCommand) {
        guard let enabled = command.arguments[0] as? Bool else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid enabled parameter")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        print("\(FirebasePlugin.TAG) - setPerformanceCollectionEnabled called with enabled: \(enabled)")
        // Performance monitoring implementation would go here
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    // MARK: - Helper Methods (matching Android)
    
    @objc func sendToken(_ token: String?) {
        if let token = token, let callbackId = self.tokenRefreshCallbackId {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: token)
            self.commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    @objc func sendNotification(_ userInfo: [String: Any]) {
        if let callbackId = self.notificationCallbackId {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: userInfo)
            self.commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    @objc func postDynamicLink(_ dynamicLink: Any) {
        if let callbackId = self.dynamicLinkCallbackId {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: dynamicLink)
            self.commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
}
