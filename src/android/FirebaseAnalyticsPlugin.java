package com.yourcompany.cordova.firebase;

import android.os.Bundle;
import android.util.Log;

import com.google.firebase.analytics.FirebaseAnalytics;

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
public class FirebaseAnalyticsPlugin extends CordovaPlugin {

    private static final String TAG = "FirebaseAnalyticsPlugin";
    private FirebaseAnalytics mFirebaseAnalytics;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        Log.d(TAG, "Executing action: " + action);

        // Initialize Firebase Analytics if not already done
        if (mFirebaseAnalytics == null) {
            mFirebaseAnalytics = FirebaseAnalytics.getInstance(this.cordova.getActivity());
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
            Log.d(TAG, "Event logged successfully: " + eventName);
            PluginResult result = new PluginResult(PluginResult.Status.OK, "Event logged successfully");
            callbackContext.sendPluginResult(result);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Error logging event: " + e.getMessage());
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
            Log.e(TAG, "Error setting user property: " + e.getMessage());
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
            Log.e(TAG, "Error setting user ID: " + e.getMessage());
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
            Log.e(TAG, "Error setting analytics collection enabled: " + e.getMessage());
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
            Log.e(TAG, "Error resetting analytics data: " + e.getMessage());
            PluginResult result = new PluginResult(PluginResult.Status.ERROR, "Error resetting analytics data: " + e.getMessage());
            callbackContext.sendPluginResult(result);
            return false;
        }
    }
}
