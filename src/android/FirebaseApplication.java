package org.apache.cordova.firebase;

import android.app.Application;
import android.content.Context;
import android.util.Log;
import com.google.firebase.FirebaseApp;

/**
 * Custom Application class to ensure Firebase is initialized early
 * This prevents the "Default FirebaseApp is not initialized" error
 * that occurs when Firebase Performance tries to initialize before
 * the main Firebase App is ready.
 */
public class FirebaseApplication extends Application {
    
    private static final String TAG = "FirebaseApplication";
    private static boolean firebaseInitialized = false;
    
    @Override
    public void onCreate() {
        super.onCreate();
        
        Log.d(TAG, "FirebaseApplication onCreate - Initializing Firebase early");
        initializeFirebaseEarly(this);
    }
    
    /**
     * Initialize Firebase App early in the application lifecycle
     * This prevents initialization issues with Firebase Performance and other services
     */
    public static synchronized void initializeFirebaseEarly(Context context) {
        if (firebaseInitialized) {
            Log.d(TAG, "Firebase already initialized, skipping...");
            return;
        }
        
        try {
            Log.d(TAG, "Early Firebase initialization started");
            
            // Check if Firebase is already initialized
            if (FirebaseApp.getApps(context).isEmpty()) {
                Log.d(TAG, "Firebase not initialized, initializing...");
                FirebaseApp.initializeApp(context);
                Log.d(TAG, "Firebase App initialized successfully");
            } else {
                Log.d(TAG, "Firebase App already initialized");
            }
            
            firebaseInitialized = true;
            Log.d(TAG, "Early Firebase initialization completed successfully");
            
        } catch (Exception e) {
            Log.e(TAG, "Failed to initialize Firebase early: " + e.getMessage(), e);
        }
    }
    
    /**
     * Check if Firebase has been initialized
     */
    public static boolean isFirebaseInitialized() {
        return firebaseInitialized;
    }
}
