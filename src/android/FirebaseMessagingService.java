package org.apache.cordova.firebase;

import android.util.Log;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Firebase Cloud Messaging Service
 * Handles incoming FCM messages
 */
public class FirebaseMessagingService extends FirebaseMessagingService {

    private static final String TAG = "FirebaseMessagingService";

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        Log.d(TAG, "From: " + remoteMessage.getFrom());

        // Check if message contains a data payload
        if (remoteMessage.getData().size() > 0) {
            Log.d(TAG, "Message data payload: " + remoteMessage.getData());
        }

        // Check if message contains a notification payload
        if (remoteMessage.getNotification() != null) {
            Log.d(TAG, "Message Notification Body: " + remoteMessage.getNotification().getBody());
        }

        // Send notification to JavaScript
        sendNotificationToJS(remoteMessage);
    }

    @Override
    public void onNewToken(String token) {
        Log.d(TAG, "Refreshed token: " + token);

        // Send token to JavaScript
        FirebasePlugin.sendToken(token);
    }

    /**
     * Send notification data to JavaScript
     */
    private void sendNotificationToJS(RemoteMessage remoteMessage) {
        try {
            JSONObject notificationData = new JSONObject();
            
            // Add notification data
            if (remoteMessage.getData().size() > 0) {
                for (String key : remoteMessage.getData().keySet()) {
                    notificationData.put(key, remoteMessage.getData().get(key));
                }
            }
            
            // Add notification payload if present
            if (remoteMessage.getNotification() != null) {
                notificationData.put("title", remoteMessage.getNotification().getTitle());
                notificationData.put("body", remoteMessage.getNotification().getBody());
                notificationData.put("icon", remoteMessage.getNotification().getIcon());
                notificationData.put("sound", remoteMessage.getNotification().getSound());
                notificationData.put("tag", remoteMessage.getNotification().getTag());
                notificationData.put("color", remoteMessage.getNotification().getColor());
                notificationData.put("clickAction", remoteMessage.getNotification().getClickAction());
            }
            
            notificationData.put("from", remoteMessage.getFrom());
            notificationData.put("messageId", remoteMessage.getMessageId());
            notificationData.put("sentTime", remoteMessage.getSentTime());
            notificationData.put("ttl", remoteMessage.getTtl());

            // Send to JavaScript
            FirebasePlugin.sendNotification(notificationData);
            
        } catch (JSONException e) {
            Log.e(TAG, "Error creating notification JSON", e);
        }
    }
}
