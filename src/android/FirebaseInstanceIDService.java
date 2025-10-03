package org.apache.cordova.firebase;

import android.util.Log;
import com.google.firebase.messaging.FirebaseMessaging;

/**
 * Firebase Instance ID Service
 * Handles token refresh events
 * Note: This class is deprecated in newer versions of FCM but kept for compatibility
 */
public class FirebaseInstanceIDService {
    
    private static final String TAG = "FirebaseInstanceIDService";

    /**
     * Called when token is refreshed
     * Note: This method is deprecated in favor of FirebaseMessagingService.onNewToken()
     */
    public static void onTokenRefresh() {
        Log.d(TAG, "Token refresh requested");
        
        // Get new token using the modern approach
        FirebaseMessaging.getInstance().getToken()
            .addOnCompleteListener(task -> {
                if (!task.isSuccessful()) {
                    Log.w(TAG, "Fetching FCM registration token failed", task.getException());
                    return;
                }
                
                // Get new FCM registration token
                String token = task.getResult();
                Log.d(TAG, "New FCM token: " + token);
                
                // Send token to JavaScript
                FirebaseAnalyticsPlugin.sendToken(token);
            });
    }
}
