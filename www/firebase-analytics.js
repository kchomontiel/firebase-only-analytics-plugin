/**
 * Firebase Analytics Cordova Plugin
 * JavaScript interface for Firebase Analytics functionality
 */

var exec = require("cordova/exec");

/**
 * Firebase Analytics Plugin
 */
var FirebaseAnalytics = {
  /**
   * Log a custom event to Firebase Analytics
   * @param {string} eventName - The name of the event to log
   * @param {Object} parameters - Optional parameters for the event
   * @param {Function} successCallback - Success callback function
   * @param {Function} errorCallback - Error callback function
   */
  logEvent: function (eventName, parameters, successCallback, errorCallback) {
    // Default parameters
    parameters = parameters || {};
    successCallback = successCallback || function () {};
    errorCallback =
      errorCallback ||
      function (error) {
        console.error("Firebase Analytics Error:", error);
      };

    // Validate event name
    if (!eventName || typeof eventName !== "string") {
      errorCallback("Event name must be a non-empty string");
      return;
    }

    // Validate parameters
    if (typeof parameters !== "object" || Array.isArray(parameters)) {
      errorCallback("Parameters must be an object");
      return;
    }

    exec(successCallback, errorCallback, "FirebaseAnalytics", "logEvent", [
      eventName,
      parameters,
    ]);
  },

  /**
   * Set user property
   * @param {string} name - Property name
   * @param {string} value - Property value
   * @param {Function} successCallback - Success callback function
   * @param {Function} errorCallback - Error callback function
   */
  setUserProperty: function (name, value, successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback =
      errorCallback ||
      function (error) {
        console.error("Firebase Analytics Error:", error);
      };

    if (!name || typeof name !== "string") {
      errorCallback("Property name must be a non-empty string");
      return;
    }

    exec(
      successCallback,
      errorCallback,
      "FirebaseAnalytics",
      "setUserProperty",
      [name, value || ""]
    );
  },

  /**
   * Set user ID
   * @param {string} userId - User ID
   * @param {Function} successCallback - Success callback function
   * @param {Function} errorCallback - Error callback function
   */
  setUserId: function (userId, successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback =
      errorCallback ||
      function (error) {
        console.error("Firebase Analytics Error:", error);
      };

    exec(successCallback, errorCallback, "FirebaseAnalytics", "setUserId", [
      userId || "",
    ]);
  },

  /**
   * Set analytics collection enabled
   * @param {boolean} enabled - Whether analytics collection is enabled
   * @param {Function} successCallback - Success callback function
   * @param {Function} errorCallback - Error callback function
   */
  setAnalyticsCollectionEnabled: function (
    enabled,
    successCallback,
    errorCallback
  ) {
    successCallback = successCallback || function () {};
    errorCallback =
      errorCallback ||
      function (error) {
        console.error("Firebase Analytics Error:", error);
      };

    exec(
      successCallback,
      errorCallback,
      "FirebaseAnalytics",
      "setAnalyticsCollectionEnabled",
      [!!enabled]
    );
  },

  /**
   * Reset analytics data
   * @param {Function} successCallback - Success callback function
   * @param {Function} errorCallback - Error callback function
   */
  resetAnalyticsData: function (successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback =
      errorCallback ||
      function (error) {
        console.error("Firebase Analytics Error:", error);
      };

    exec(
      successCallback,
      errorCallback,
      "FirebaseAnalytics",
      "resetAnalyticsData",
      []
    );
  },

  /**
   * Check if Firebase Analytics is initialized
   * @param {Function} successCallback - Success callback function (receives boolean)
   * @param {Function} errorCallback - Error callback function
   */
  isFirebaseInitialized: function (successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback =
      errorCallback ||
      function (error) {
        console.error("Firebase Analytics Error:", error);
      };

    // Firebase is considered initialized if the plugin is loaded
    // We can make a simple call to verify
    exec(
      function() {
        successCallback(true);
      },
      function() {
        successCallback(false);
      },
      "FirebaseAnalytics",
      "logEvent",
      ["_init_check", {}]
    );
  },

  /**
   * Set screen name for analytics tracking
   * @param {string} screenName - The name of the screen
   * @param {Function} successCallback - Success callback function
   * @param {Function} errorCallback - Error callback function
   */
  setScreenName: function (screenName, successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback =
      errorCallback ||
      function (error) {
        console.error("Firebase Analytics Error:", error);
      };

    // Validate screen name
    if (!screenName || typeof screenName !== "string") {
      errorCallback("Screen name must be a non-empty string");
      return;
    }

    // Log a screen_view event with the screen name
    exec(
      successCallback,
      errorCallback,
      "FirebaseAnalytics",
      "logEvent",
      ["screen_view", { screen_name: screenName }]
    );
  },
};

module.exports = FirebaseAnalytics;

// Create window.fp interface for compatibility
if (typeof window !== 'undefined') {
  window.fp = {
    logEvent: function(eventName, parameters, successCallback, errorCallback) {
      return FirebaseAnalytics.logEvent(eventName, parameters, successCallback, errorCallback);
    },
    
    setUserProperty: function(name, value, successCallback, errorCallback) {
      return FirebaseAnalytics.setUserProperty(name, value, successCallback, errorCallback);
    },
    
    setUserId: function(userId, successCallback, errorCallback) {
      return FirebaseAnalytics.setUserId(userId, successCallback, errorCallback);
    },
    
    setAnalyticsCollectionEnabled: function(enabled, successCallback, errorCallback) {
      return FirebaseAnalytics.setAnalyticsCollectionEnabled(enabled, successCallback, errorCallback);
    },
    
    resetAnalyticsData: function(successCallback, errorCallback) {
      return FirebaseAnalytics.resetAnalyticsData(successCallback, errorCallback);
    },
    
    isFirebaseInitialized: function(successCallback, errorCallback) {
      return FirebaseAnalytics.isFirebaseInitialized(successCallback, errorCallback);
    },
    
    setScreenName: function(screenName, successCallback, errorCallback) {
      return FirebaseAnalytics.setScreenName(screenName, successCallback, errorCallback);
    }
  };
}
