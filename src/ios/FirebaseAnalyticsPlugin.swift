import Foundation
import FirebaseAnalytics
import FirebaseCore

/**
 * Firebase Analytics Cordova Plugin for iOS
 * Provides Firebase Analytics functionality for Cordova applications
 */
@objc(FirebaseAnalyticsPlugin)
class FirebaseAnalyticsPlugin: CDVPlugin {
    
    /**
     * Initialize Firebase Analytics
     */
    override func pluginInitialize() {
        super.pluginInitialize()
        
        // Firebase is initialized automatically when the app starts
        // if GoogleService-Info.plist is present in the bundle
        print("FirebaseAnalyticsPlugin: Plugin initialized")
    }
    
    /**
     * Log a custom event to Firebase Analytics
     */
    @objc(logEvent:)
    func logEvent(_ command: CDVInvokedUrlCommand) {
        guard let eventName = command.argument(at: 0) as? String else {
            sendErrorResult(command, message: "Event name is required")
            return
        }
        
        guard !eventName.isEmpty else {
            sendErrorResult(command, message: "Event name cannot be empty")
            return
        }
        
        var parameters: [String: Any] = [:]
        
        // Parse parameters if provided
        if command.arguments.count > 1,
           let paramsDict = command.argument(at: 1) as? [String: Any] {
            parameters = paramsDict
        }
        
        // Validate and convert parameters to Firebase-compatible types
        let firebaseParameters = convertToFirebaseParameters(parameters)
        
        Analytics.logEvent(eventName, parameters: firebaseParameters)
        print("FirebaseAnalyticsPlugin: Event logged successfully: \(eventName)")
        
        sendSuccessResult(command, message: "Event logged successfully")
    }
    
    /**
     * Set user property
     */
    @objc(setUserProperty:)
    func setUserProperty(_ command: CDVInvokedUrlCommand) {
        guard let name = command.argument(at: 0) as? String else {
            sendErrorResult(command, message: "Property name is required")
            return
        }
        
        guard !name.isEmpty else {
            sendErrorResult(command, message: "Property name cannot be empty")
            return
        }
        
        let value = command.argument(at: 1) as? String ?? ""
        
        Analytics.setUserProperty(value, forName: name)
        print("FirebaseAnalyticsPlugin: User property set successfully: \(name) = \(value)")
        
        sendSuccessResult(command, message: "User property set successfully")
    }
    
    /**
     * Set user ID
     */
    @objc(setUserId:)
    func setUserId(_ command: CDVInvokedUrlCommand) {
        let userId = command.argument(at: 0) as? String ?? ""
        
        Analytics.setUserID(userId)
        print("FirebaseAnalyticsPlugin: User ID set successfully: \(userId)")
        
        sendSuccessResult(command, message: "User ID set successfully")
    }
    
    /**
     * Set analytics collection enabled
     */
    @objc(setAnalyticsCollectionEnabled:)
    func setAnalyticsCollectionEnabled(_ command: CDVInvokedUrlCommand) {
        guard let enabled = command.argument(at: 0) as? Bool else {
            sendErrorResult(command, message: "Enabled parameter is required")
            return
        }
        
        Analytics.setAnalyticsCollectionEnabled(enabled)
        print("FirebaseAnalyticsPlugin: Analytics collection enabled set to: \(enabled)")
        
        sendSuccessResult(command, message: "Analytics collection enabled set successfully")
    }
    
    /**
     * Reset analytics data
     */
    @objc(resetAnalyticsData:)
    func resetAnalyticsData(_ command: CDVInvokedUrlCommand) {
        Analytics.resetAnalyticsData()
        print("FirebaseAnalyticsPlugin: Analytics data reset successfully")
        
        sendSuccessResult(command, message: "Analytics data reset successfully")
    }
    
    // MARK: - Helper Methods
    
    /**
     * Convert parameters to Firebase-compatible types
     */
    private func convertToFirebaseParameters(_ parameters: [String: Any]) -> [String: Any] {
        var firebaseParameters: [String: Any] = [:]
        
        for (key, value) in parameters {
            switch value {
            case is String:
                firebaseParameters[key] = value as! String
            case is NSNumber:
                let number = value as! NSNumber
                if CFNumberIsFloatType(number) {
                    firebaseParameters[key] = number.doubleValue
                } else {
                    firebaseParameters[key] = number.intValue
                }
            case is Bool:
                firebaseParameters[key] = value as! Bool
            default:
                // Convert other types to string
                firebaseParameters[key] = String(describing: value)
            }
        }
        
        return firebaseParameters
    }
    
    /**
     * Send success result to JavaScript
     */
    private func sendSuccessResult(_ command: CDVInvokedUrlCommand, message: String) {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: message)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    /**
     * Send error result to JavaScript
     */
    private func sendErrorResult(_ command: CDVInvokedUrlCommand, message: String) {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: message)
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
}
