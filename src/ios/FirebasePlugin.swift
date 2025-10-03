import Foundation
import FirebaseAnalytics
import FirebaseCore

/**
 * Firebase Analytics Cordova Plugin for iOS
 * Provides Firebase Analytics functionality for Cordova applications
 */
@objc(FirebasePlugin)
class FirebasePlugin: CDVPlugin {
    
    /**
     * Initialize Firebase Analytics
     */
    override func pluginInitialize() {
        super.pluginInitialize()
        
        // Firebase is automatically initialized when the app starts
        // if GoogleService-Info.plist is present in the bundle
        // This is the recommended approach per Firebase documentation
        print("FirebasePlugin: Plugin initialized")
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
        
        // Firebase Analytics event names should be max 40 characters
        guard eventName.count <= 40 else {
            sendErrorResult(command, message: "Event name cannot exceed 40 characters")
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
        print("FirebasePlugin: Event logged successfully: \(eventName)")
        
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
        
        // Firebase Analytics property names should be max 24 characters
        guard name.count <= 24 else {
            sendErrorResult(command, message: "Property name cannot exceed 24 characters")
            return
        }
        
        let value = command.argument(at: 1) as? String ?? ""
        
        // Firebase Analytics property values should be max 36 characters
        guard value.count <= 36 else {
            sendErrorResult(command, message: "Property value cannot exceed 36 characters")
            return
        }
        
        Analytics.setUserProperty(value, forName: name)
        print("FirebasePlugin: User property set successfully: \(name) = \(value)")
        
        sendSuccessResult(command, message: "User property set successfully")
    }
    
    /**
     * Set user ID
     */
    @objc(setUserId:)
    func setUserId(_ command: CDVInvokedUrlCommand) {
        let userId = command.argument(at: 0) as? String ?? ""
        
        Analytics.setUserID(userId)
        print("FirebasePlugin: User ID set successfully: \(userId)")
        
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
        print("FirebasePlugin: Analytics collection enabled set to: \(enabled)")
        
        sendSuccessResult(command, message: "Analytics collection enabled set successfully")
    }
    
    /**
     * Reset analytics data
     */
    @objc(resetAnalyticsData:)
    func resetAnalyticsData(_ command: CDVInvokedUrlCommand) {
        Analytics.resetAnalyticsData()
        print("FirebasePlugin: Analytics data reset successfully")
        
        sendSuccessResult(command, message: "Analytics data reset successfully")
    }
    
    // MARK: - Helper Methods
    
    /**
     * Convert parameters to Firebase-compatible types
     * According to Firebase Analytics documentation, parameters can be:
     * - String (up to 100 characters)
     * - Number (Int, Double, Float)
     * - Boolean
     */
    private func convertToFirebaseParameters(_ parameters: [String: Any]) -> [String: Any] {
        var firebaseParameters: [String: Any] = [:]
        
        for (key, value) in parameters {
            switch value {
            case let stringValue as String:
                // Firebase Analytics parameter strings should be max 100 characters
                let truncatedString = String(stringValue.prefix(100))
                firebaseParameters[key] = truncatedString
            case let numberValue as NSNumber:
                if CFNumberIsFloatType(numberValue) {
                    firebaseParameters[key] = numberValue.doubleValue
                } else {
                    firebaseParameters[key] = numberValue.intValue
                }
            case let boolValue as Bool:
                firebaseParameters[key] = boolValue
            case let intValue as Int:
                firebaseParameters[key] = intValue
            case let doubleValue as Double:
                firebaseParameters[key] = doubleValue
            case let floatValue as Float:
                firebaseParameters[key] = floatValue
            default:
                // Convert other types to string (truncated to 100 chars)
                let stringValue = String(describing: value)
                firebaseParameters[key] = String(stringValue.prefix(100))
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
