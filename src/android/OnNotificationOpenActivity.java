package com.yourcompany.cordova.firebase;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

/**
 * Activity for handling notification open events
 */
public class OnNotificationOpenActivity extends Activity {

    private static final String TAG = "OnNotificationOpenActivity";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        Log.d(TAG, "Notification open activity created");
        
        Intent intent = getIntent();
        if (intent != null) {
            Bundle extras = intent.getExtras();
            if (extras != null) {
                // Mark as tapped notification
                extras.putBoolean("tap", true);
                
                // Send notification data to JavaScript
                FirebaseAnalyticsPlugin.sendNotification(extras);
            }
        }
        
        // Close the activity immediately
        finish();
    }
}
