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

    exec(successCallback, errorCallback, "FirebasePlugin", "logEvent", [
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
      "FirebasePlugin",
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

    exec(successCallback, errorCallback, "FirebasePlugin", "setUserId", [
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
      "FirebasePlugin",
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
      "FirebasePlugin",
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
      function () {
        successCallback(true);
      },
      function () {
        successCallback(false);
      },
      "FirebasePlugin",
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
    exec(successCallback, errorCallback, "FirebasePlugin", "logEvent", [
      "screen_view",
      { screen_name: screenName },
    ]);
  },

  /**
   * Check if the app has permission to collect analytics data
   * @param {Function} successCallback - Success callback function (receives boolean)
   * @param {Function} errorCallback - Error callback function
   */
  hasPermission: function (successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback =
      errorCallback ||
      function (error) {
        console.error("Firebase Analytics Error:", error);
      };

    // Check if analytics collection is enabled
    exec(
      function (result) {
        // result should be true/false indicating if analytics is enabled
        successCallback(!!result);
      },
      function (error) {
        // If there's an error, assume no permission
        console.warn("Error checking analytics permission:", error);
        successCallback(false);
      },
      "FirebasePlugin",
      "setAnalyticsCollectionEnabled",
      [true]
    );
  },

  //
  // Cloud Messaging FCM
  //
  /**
   * Get FCM registration token
   * @param {Function} successCallback - Success callback function (receives token)
   * @param {Function} errorCallback - Error callback function
   */
  getToken: function (successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback = errorCallback || function (error) {
      console.error("Firebase FCM Error:", error);
    };

    exec(successCallback, errorCallback, "FirebasePlugin", "getToken", []);
  },

  /**
   * Subscribe to a topic
   * @param {string} topic - Topic name to subscribe to
   * @param {Function} successCallback - Success callback function
   * @param {Function} errorCallback - Error callback function
   */
  subscribe: function (topic, successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback = errorCallback || function (error) {
      console.error("Firebase FCM Error:", error);
    };

    if (!topic || typeof topic !== "string") {
      errorCallback("Topic must be a non-empty string");
      return;
    }

    exec(successCallback, errorCallback, "FirebasePlugin", "subscribe", [topic]);
  },

  /**
   * Unsubscribe from a topic
   * @param {string} topic - Topic name to unsubscribe from
   * @param {Function} successCallback - Success callback function
   * @param {Function} errorCallback - Error callback function
   */
  unsubscribe: function (topic, successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback = errorCallback || function (error) {
      console.error("Firebase FCM Error:", error);
    };

    if (!topic || typeof topic !== "string") {
      errorCallback("Topic must be a non-empty string");
      return;
    }

    exec(successCallback, errorCallback, "FirebasePlugin", "unsubscribe", [topic]);
  },

  /**
   * Set notification badge number (Android)
   * @param {number} number - Badge number
   * @param {Function} successCallback - Success callback function
   * @param {Function} errorCallback - Error callback function
   */
  setBadgeNumber: function (number, successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback = errorCallback || function (error) {
      console.error("Firebase FCM Error:", error);
    };

    exec(successCallback, errorCallback, "FirebasePlugin", "setBadgeNumber", [number || 0]);
  },

  /**
   * Get notification badge number (Android)
   * @param {Function} successCallback - Success callback function (receives number)
   * @param {Function} errorCallback - Error callback function
   */
  getBadgeNumber: function (successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback = errorCallback || function (error) {
      console.error("Firebase FCM Error:", error);
    };

    exec(successCallback, errorCallback, "FirebasePlugin", "getBadgeNumber", []);
  },

  /**
   * Clear all notifications
   * @param {Function} successCallback - Success callback function
   * @param {Function} errorCallback - Error callback function
   */
  clearAllNotifications: function (successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback = errorCallback || function (error) {
      console.error("Firebase FCM Error:", error);
    };

    exec(successCallback, errorCallback, "FirebasePlugin", "clearAllNotifications", []);
  },

  /**
   * Set up notification open listener
   * @param {Function} successCallback - Success callback function (receives notification data)
   * @param {Function} errorCallback - Error callback function
   */
  onNotificationOpen: function (successCallback, errorCallback) {
    successCallback = successCallback || function () {};
    errorCallback = errorCallback || function (error) {
      console.error("Firebase FCM Error:", error);
    };

    exec(successCallback, errorCallback, "FirebasePlugin", "onNotificationOpen", []);
  },

  /**
   * Set up token refresh listener
   * @param {Function} successCallback - Success callback function (receives new token)
   * @param {Function} errorCallback - Error callback function
   */

    errorCallback = errorCallback || function (error) {
      console.error("Firebase FCM Error:", error);
    };

    exec(successCallback, errorCallback, "FirebasePlugin", "onTokenRefresh", []);
  },
};
    exec(successCallback, errorCallback, "FirebasePlugin", "onTokenRefresh", []);
  },
};

module.exports = FirebaseAnalytics;

if (typeof window !== "undefined") {
  window.fp = {
    logEvent: function (eventName, parameters, successCallback, errorCallback) {
      return FirebaseAnalytics.logEvent(
        eventName,
        parameters,
        successCallback,
        errorCallback
      );
    },

    setUserProperty: function (name, value, successCallback, errorCallback) {
      return FirebaseAnalytics.setUserProperty(
        name,
        value,
        successCallback,
        errorCallback
      );
    },

    setUserId: function (userId, successCallback, errorCallback) {
      return FirebaseAnalytics.setUserId(
        userId,
        successCallback,
        errorCallback
      );
    },

    setAnalyticsCollectionEnabled: function (
      enabled,
      successCallback,
      errorCallback
    ) {
      return FirebaseAnalytics.setAnalyticsCollectionEnabled(
        enabled,
        successCallback,
        errorCallback
      );
    },

    resetAnalyticsData: function (successCallback, errorCallback) {
      return FirebaseAnalytics.resetAnalyticsData(
        successCallback,
        errorCallback
      );
    },

    isFirebaseInitialized: function (successCallback, errorCallback) {
      return FirebaseAnalytics.isFirebaseInitialized(
        successCallback,
        errorCallback
      );
    },

     setScreenName: function (screenName, successCallback, errorCallback) {
       return FirebaseAnalytics.setScreenName(
         screenName,
         successCallback,
         errorCallback

     // FCM Methods
     getToken: function (successCallback, errorCallback) {
       return FirebaseAnalytics.getToken(successCallback, errorCallback);
     },

     subscribe: function (topic, successCallback, errorCallback) {
       return FirebaseAnalytics.subscribe(topic, successCallback, errorCallback);
     },

     unsubscribe: function (topic, successCallback, errorCallback) {
       return FirebaseAnalytics.unsubscribe(topic, successCallback, errorCallback);
     },

     setBadgeNumber: function (number, successCallback, errorCallback) {
       return FirebaseAnalytics.setBadgeNumber(number, successCallback, errorCallback);
     },

     getBadgeNumber: function (successCallback, errorCallback) {
       return FirebaseAnalytics.getBadgeNumber(successCallback, errorCallback);
     },

     clearAllNotifications: function (successCallback, errorCallback) {
       return FirebaseAnalytics.clearAllNotifications(successCallback, errorCallback);
     },

     onNotificationOpen: function (successCallback, errorCallback) {
       return FirebaseAnalytics.onNotificationOpen(successCallback, errorCallback);
     },

     onTokenRefresh: function (successCallback, errorCallback) {
       return FirebaseAnalytics.onTokenRefresh(successCallback, errorCallback);
     },
       );
     },

     hasPermission: function (successCallback, errorCallback) {
       return FirebaseAnalytics.hasPermission(
         successCallback,
         errorCallback
       );
     },
   };
 }
