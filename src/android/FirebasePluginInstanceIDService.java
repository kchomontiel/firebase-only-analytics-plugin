package org.apache.cordova.firebase;

import android.util.Log;

import com.google.firebase.messaging.FirebaseMessaging;

public class FirebasePluginInstanceIDService {

  private static final String TAG = "FirebasePlugin";

  /**
   * Token refresh is now handled by FirebaseMessagingService
   * This class is kept for compatibility but functionality moved to FirebasePluginMessagingService
   */
  public static void onTokenRefresh() {
    // Get updated FCM token using new API
    FirebaseMessaging.getInstance().getToken()
      .addOnCompleteListener(task -> {
        if (!task.isSuccessful()) {
          Log.e(TAG, "Fetching FCM registration token failed", task.getException());
          return;
        }
        
        // Get new FCM registration token
        String refreshedToken = task.getResult();
        Log.d(TAG, "Refreshed token: " + refreshedToken);
        
        FirebasePlugin.sendToken(refreshedToken);
      });
  }
}