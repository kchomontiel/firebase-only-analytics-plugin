package org.apache.cordova.firebase;

import android.os.Bundle;
import android.util.Log;

import com.google.firebase.analytics.FirebaseAnalytics;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.google.firebase.installations.FirebaseInstallations;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import androidx.annotation.NonNull;
import android.app.NotificationManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Iterator;

/**
 * Firebase Analytics Cordova Plugin for Android
 * Provides Firebase Analytics functionality for Cordova applications
 */
public class FirebasePlugin extends CordovaPlugin {

    private static final String TAG = "FirebasePlugin";
    private FirebaseAnalytics mFirebaseAnalytics;
    private static final String KEY = "badge";
    private static CallbackContext notificationCallbackContext;
    private static CallbackContext tokenRefreshCallbackContext;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        Log.d(TAG, "Executing action: " + action);

        // Initialize Firebase Analytics if not already done
        // Firebase App is automatically initialized by google-services.json
        if (mFirebaseAnalytics == null) {
            mFirebaseAnalytics = FirebaseAnalytics.getInstance(this.cordova.getActivity());
            Log.d(TAG, "Firebase Analytics initialized");
        }

        switch (action) {
            case "logEvent":
                return logEvent(args, callbackContext);
            case "setUserProperty":
                return setUserProperty(args, callbackContext);
            case "setUserId":
                return setUserId(args, callbackContext);
            case "setAnalyticsCollectionEnabled":
                return setAnalyticsCollectionEnabled(args, callbackContext);
            case "resetAnalyticsData":
                return resetAnalyticsData(callbackContext);
            case "getToken":
                return getToken(callbackContext);
            case "subscribe":
                return subscribe(args, callbackContext);
            case "unsubscribe":
                return unsubscribe(args, callbackContext);
            case "setBadgeNumber":
                return setBadgeNumber(args, callbackContext);
            case "getBadgeNumber":
                return getBadgeNumber(callbackContext);
            case "clearAllNotifications":
                return clearAllNotifications(callbackContext);
            case "onNotificationOpen":
                return onNotificationOpen(callbackContext);
            case "onTokenRefresh":
                return onTokenRefresh(callbackContext);
            default:
                Log.e(TAG, "Unknown action: " + action);
                callbackContext.error("Unknown action: " + action);
                return false;
        }
    }

    /**
     * Log a custom event to Firebase Analytics
     */
    private boolean logEvent(JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (args.length() < 1) {
            callbackContext.error("Event name is required");
            return false;
        }

        String eventName = args.getString(0);
        if (eventName == null || eventName.isEmpty()) {
            callbackContext.error("Event name cannot be empty");
            return false;
        }

        Bundle parameters = new Bundle();

        // Add parameters if provided
        if (args.length() > 1 && !args.isNull(1)) {
            JSONObject paramsObj = args.getJSONObject(1);
            if (paramsObj != null) {
                Iterator<String> keys = paramsObj.keys();
                while (keys.hasNext()) {
                    String key = keys.next();
                    Object value = paramsObj.get(key);
                    
                    if (value instanceof String) {
                        parameters.putString(key, (String) value);
                    } else if (value instanceof Integer) {
                        parameters.putInt(key, (Integer) value);
                    } else if (value instanceof Long) {
                        parameters.putLong(key, (Long) value);
                    } else if (value instanceof Double) {
                        parameters.putDouble(key, (Double) value);
                    } else if (value instanceof Float) {
                        parameters.putFloat(key, (Float) value);
                    } else if (value instanceof Boolean) {
                        parameters.putBoolean(key, (Boolean) value);
                    } else {
                        // Convert other types to string
                        parameters.putString(key, value.toString());
                    }
                }
            }
        }

        try {
            mFirebaseAnalytics.logEvent(eventName, parameters);
            Log.d(TAG, "Event logged successfully: " + eventName + " with " + parameters.size() + " parameters");
            PluginResult result = new PluginResult(PluginResult.Status.OK, "Event logged successfully");
            callbackContext.sendPluginResult(result);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Error logging event '" + eventName + "': " + e.getMessage(), e);
            PluginResult result = new PluginResult(PluginResult.Status.ERROR, "Error logging event: " + e.getMessage());
            callbackContext.sendPluginResult(result);
            return false;
        }
    }

    /**
     * Set user property
     */
    private boolean setUserProperty(JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (args.length() < 2) {
            callbackContext.error("Property name and value are required");
            return false;
        }

        String name = args.getString(0);
        String value = args.getString(1);

        if (name == null || name.isEmpty()) {
            callbackContext.error("Property name cannot be empty");
            return false;
        }

        try {
            mFirebaseAnalytics.setUserProperty(name, value);
            Log.d(TAG, "User property set successfully: " + name + " = " + value);
            PluginResult result = new PluginResult(PluginResult.Status.OK, "User property set successfully");
            callbackContext.sendPluginResult(result);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Error setting user property '" + name + "' = '" + value + "': " + e.getMessage(), e);
            PluginResult result = new PluginResult(PluginResult.Status.ERROR, "Error setting user property: " + e.getMessage());
            callbackContext.sendPluginResult(result);
            return false;
        }
    }

    /**
     * Set user ID
     */
    private boolean setUserId(JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (args.length() < 1) {
            callbackContext.error("User ID is required");
            return false;
        }

        String userId = args.getString(0);

        try {
            mFirebaseAnalytics.setUserId(userId);
            Log.d(TAG, "User ID set successfully: " + userId);
            PluginResult result = new PluginResult(PluginResult.Status.OK, "User ID set successfully");
            callbackContext.sendPluginResult(result);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Error setting user ID '" + userId + "': " + e.getMessage(), e);
            PluginResult result = new PluginResult(PluginResult.Status.ERROR, "Error setting user ID: " + e.getMessage());
            callbackContext.sendPluginResult(result);
            return false;
        }
    }

    /**
     * Set analytics collection enabled
     */
    private boolean setAnalyticsCollectionEnabled(JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (args.length() < 1) {
            callbackContext.error("Enabled parameter is required");
            return false;
        }

        boolean enabled = args.getBoolean(0);

        try {
            mFirebaseAnalytics.setAnalyticsCollectionEnabled(enabled);
            Log.d(TAG, "Analytics collection enabled set to: " + enabled);
            PluginResult result = new PluginResult(PluginResult.Status.OK, "Analytics collection enabled set successfully");
            callbackContext.sendPluginResult(result);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Error setting analytics collection enabled to '" + enabled + "': " + e.getMessage(), e);
            PluginResult result = new PluginResult(PluginResult.Status.ERROR, "Error setting analytics collection enabled: " + e.getMessage());
            callbackContext.sendPluginResult(result);
            return false;
        }
    }

    /**
     * Reset analytics data
     */
    private boolean resetAnalyticsData(CallbackContext callbackContext) {
        try {
            mFirebaseAnalytics.resetAnalyticsData();
            Log.d(TAG, "Analytics data reset successfully");
            PluginResult result = new PluginResult(PluginResult.Status.OK, "Analytics data reset successfully");
            callbackContext.sendPluginResult(result);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Error resetting analytics data: " + e.getMessage(), e);
            PluginResult result = new PluginResult(PluginResult.Status.ERROR, "Error resetting analytics data: " + e.getMessage());
            callbackContext.sendPluginResult(result);
            return false;
        }
    }

    //
    // Cloud Messaging FCM Methods
    //

    /**
     * Get FCM registration token
     */
    private boolean getToken(CallbackContext callbackContext) {
        Log.d(TAG, "getToken called");
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    FirebaseMessaging.getInstance().getToken()
                        .addOnCompleteListener(new OnCompleteListener<String>() {
                            @Override
                            public void onComplete(@NonNull Task<String> task) {
                                if (!task.isSuccessful()) {
                                    Log.w(TAG, "Fetching FCM registration token failed", task.getException());
                                    callbackContext.error("Failed to get FCM token: " + task.getException().getMessage());
                                    return;
                                }
                                String token = task.getResult();
                                Log.d(TAG, "FCM token: " + token);
                                callbackContext.success(token);
                            }
                        });
                } catch (Exception e) {
                    Log.e(TAG, "Error getting FCM token: " + e.getMessage(), e);
                    callbackContext.error("Error getting FCM token: " + e.getMessage());
                }
            }
        });
        return true;
    }

    /**
     * Subscribe to a topic
     */
    private boolean subscribe(JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (args.length() < 1) {
            callbackContext.error("Topic is required");
            return false;
        }

        String topic = args.getString(0);
        Log.d(TAG, "subscribe called. topic: " + topic);

        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    FirebaseMessaging.getInstance().subscribeToTopic(topic)
                        .addOnCompleteListener(new OnCompleteListener<Void>() {
                            @Override
                            public void onComplete(@NonNull Task<Void> task) {
                                if (task.isSuccessful()) {
                                    Log.d(TAG, "Successfully subscribed to topic: " + topic);
                                    callbackContext.success();
                                } else {
                                    Log.e(TAG, "Failed to subscribe to topic: " + topic, task.getException());
                                    callbackContext.error("Failed to subscribe to topic: " + task.getException().getMessage());
                                }
                            }
                        });
                } catch (Exception e) {
                    Log.e(TAG, "Error subscribing to topic: " + e.getMessage(), e);
                    callbackContext.error("Error subscribing to topic: " + e.getMessage());
                }
            }
        });
        return true;
    }

    /**
     * Unsubscribe from a topic
     */
    private boolean unsubscribe(JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (args.length() < 1) {
            callbackContext.error("Topic is required");
            return false;
        }

        String topic = args.getString(0);
        Log.d(TAG, "unsubscribe called. topic: " + topic);

        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    FirebaseMessaging.getInstance().unsubscribeFromTopic(topic)
                        .addOnCompleteListener(new OnCompleteListener<Void>() {
                            @Override
                            public void onComplete(@NonNull Task<Void> task) {
                                if (task.isSuccessful()) {
                                    Log.d(TAG, "Successfully unsubscribed from topic: " + topic);
                                    callbackContext.success();
                                } else {
                                    Log.e(TAG, "Failed to unsubscribe from topic: " + topic, task.getException());
                                    callbackContext.error("Failed to unsubscribe from topic: " + task.getException().getMessage());
                                }
                            }
                        });
                } catch (Exception e) {
                    Log.e(TAG, "Error unsubscribing from topic: " + e.getMessage(), e);
                    callbackContext.error("Error unsubscribing from topic: " + e.getMessage());
                }
            }
        });
        return true;
    }

    /**
     * Set badge number
     */
    private boolean setBadgeNumber(JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (args.length() < 1) {
            callbackContext.error("Number is required");
            return false;
        }

        int number = args.getInt(0);
        Log.d(TAG, "setBadgeNumber called. number: " + number);

        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    Context context = cordova.getActivity();
                    SharedPreferences settings = context.getSharedPreferences(KEY, Context.MODE_PRIVATE);
                    settings.edit().putInt(KEY, number).apply();
                    callbackContext.success();
                    Log.d(TAG, "setBadgeNumber success. number: " + number);
                } catch (Exception e) {
                    Log.e(TAG, "Error setting badge number: " + e.getMessage(), e);
                    callbackContext.error("Error setting badge number: " + e.getMessage());
                }
            }
        });
        return true;
    }

    /**
     * Get badge number
     */
    private boolean getBadgeNumber(CallbackContext callbackContext) {
        Log.d(TAG, "getBadgeNumber called");
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    Context context = cordova.getActivity();
                    SharedPreferences settings = context.getSharedPreferences(KEY, Context.MODE_PRIVATE);
                    int number = settings.getInt(KEY, 0);
                    callbackContext.success(number);
                    Log.d(TAG, "getBadgeNumber success. number: " + number);
                } catch (Exception e) {
                    Log.e(TAG, "Error getting badge number: " + e.getMessage(), e);
                    callbackContext.error("Error getting badge number: " + e.getMessage());
                }
            }
        });
        return true;
    }

    /**
     * Clear all notifications
     */
    private boolean clearAllNotifications(CallbackContext callbackContext) {
        Log.d(TAG, "clearAllNotifications called");
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    Context context = cordova.getActivity();
                    NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                    nm.cancelAll();
                    callbackContext.success();
                    Log.d(TAG, "clearAllNotifications success");
                } catch (Exception e) {
                    Log.e(TAG, "Error clearing notifications: " + e.getMessage(), e);
                    callbackContext.error("Error clearing notifications: " + e.getMessage());
                }
            }
        });
        return true;
    }

    /**
     * Set up notification open listener
     */
    private boolean onNotificationOpen(CallbackContext callbackContext) {
        Log.d(TAG, "onNotificationOpen called");
        notificationCallbackContext = callbackContext;
        PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
        return true;
    }

    /**
     * Set up token refresh listener
     */
    private boolean onTokenRefresh(CallbackContext callbackContext) {
        Log.d(TAG, "onTokenRefresh called");
        tokenRefreshCallbackContext = callbackContext;
        PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
        result.setKeepCallback(true);
        callbackContext.sendPluginResult(result);
        return true;
    }

    /**
     * Send notification data to JavaScript
     */
    public static void sendNotification(Bundle bundle, Context context) {
        if (notificationCallbackContext != null && bundle != null) {
            JSONObject json = new JSONObject();
            for (String key : bundle.keySet()) {
                try {
                    json.put(key, bundle.get(key));
            result.setKeepCallback(true);
            }
            PluginResult result = new PluginResult(PluginResult.Status.OK, json);
                } catch (JSONException e) {
                    Log.e(TAG, "Error creating notification JSON", e);
                    return;
                }
            }
            PluginResult result = new PluginResult(PluginResult.Status.OK, json);
            result.setKeepCallback(true);
            notificationCallbackContext.sendPluginResult(result);
            Log.d(TAG, "sendNotification success");
        }
    }

    /**
     * Send notification data to JavaScript (overloaded for JSONObject)
     */
    public static void sendNotification(JSONObject json) {
        if (notificationCallbackContext != null && json != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, json);
            result.setKeepCallback(true);
            notificationCallbackContext.sendPluginResult(result);
            Log.d(TAG, "sendNotification success (JSONObject)");
        }
    }

    /**
     * Send token to JavaScript
     */
    public static void sendToken(String token) {
        if (tokenRefreshCallbackContext != null && token != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, token);
            result.setKeepCallback(true);
            tokenRefreshCallbackContext.sendPluginResult(result);
            Log.d(TAG, "sendToken success. token: " + token);
        }
    }
}
