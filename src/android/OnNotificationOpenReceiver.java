package org.apache.cordova.firebase;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

/**
 * Broadcast receiver for handling notification open events
 */
public class OnNotificationOpenReceiver extends BroadcastReceiver {

    private static final String TAG = "OnNotificationOpenReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d(TAG, "Notification open received");
        
        Bundle extras = intent.getExtras();
        if (extras != null) {
            // Mark as tapped notification
            extras.putBoolean("tap", true);
            
            // Send notification data to JavaScript
            FirebaseAnalyticsPlugin.sendNotification(extras);
        }
    }
}
