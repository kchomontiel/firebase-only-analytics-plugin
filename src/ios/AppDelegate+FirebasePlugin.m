#import "AppDelegate+FirebasePlugin.h"
#import "FirebasePlugin.h"
#import <objc/runtime.h>

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
  @import UserNotifications;

  // Implement UNUserNotificationCenterDelegate to receive display notification via APNS for devices
  // running iOS 10 and above. Implement FIRMessagingDelegate to receive data message via FCM for
  // devices running iOS 10 and above.
  @interface AppDelegate () <UNUserNotificationCenterDelegate>
  @end
#endif

#define kApplicationInBackgroundKey @"applicationInBackground"
#define kDelegateKey @"delegate"

@implementation AppDelegate (FirebasePlugin)

+ (void)load {
    Method original = class_getInstanceMethod(self, @selector(application:didFinishLaunchingWithOptions:));
    Method swizzled = class_getInstanceMethod(self, @selector(identity_application:didFinishLaunchingWithOptions:));
    method_exchangeImplementations(original, swizzled);
}

- (BOOL)identity_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"AppDelegate+FirebasePlugin MOCK: didFinishLaunchingWithOptions called");
    
    // MOCK: Simulate Firebase initialization without actual Firebase calls
    [self mockInitializeFirebase];
    
    return [self identity_application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)mockInitializeFirebase {
    NSLog(@"AppDelegate+FirebasePlugin MOCK: Initializing Firebase in mock mode");
    
    // MOCK: Set up notification observers without actual Firebase calls
    [self setupMockNotificationObservers];
}

- (void)setupMockNotificationObservers {
    NSLog(@"AppDelegate+FirebasePlugin MOCK: Setting up mock notification observers");
    
    // MOCK: Don't actually register for notifications, just log
    #if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
        NSLog(@"AppDelegate+FirebasePlugin MOCK: Would set UNUserNotificationCenter delegate");
    #endif
    
    // MOCK: Don't actually register for token refresh, just log
    NSLog(@"AppDelegate+FirebasePlugin MOCK: Would register for token refresh notifications");
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"AppDelegate+FirebasePlugin MOCK: didRegisterForRemoteNotificationsWithDeviceToken called");
    // MOCK: Don't actually set APNS token, just log
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"AppDelegate+FirebasePlugin MOCK: didFailToRegisterForRemoteNotificationsWithError called");
    // MOCK: Just log the error, don't handle it
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"AppDelegate+FirebasePlugin MOCK: didReceiveRemoteNotification called");
    // MOCK: Don't actually handle the notification, just log
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"AppDelegate+FirebasePlugin MOCK: didReceiveRemoteNotification with completion handler called");
    // MOCK: Always return no new data
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)tokenRefreshNotification:(NSNotification *)notification {
    NSLog(@"AppDelegate+FirebasePlugin MOCK: tokenRefreshNotification called");
    // MOCK: Don't actually get token, just log
}

- (void)messaging:(id)messaging didReceiveMessage:(id)remoteMessage {
    NSLog(@"AppDelegate+FirebasePlugin MOCK: messaging:didReceiveMessage called");
    // MOCK: Don't actually handle the message, just log
}

- (void)applicationReceivedRemoteMessage:(id)remoteMessage {
    NSLog(@"AppDelegate+FirebasePlugin MOCK: applicationReceivedRemoteMessage called");
    // MOCK: Don't actually handle the message, just log
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"AppDelegate+FirebasePlugin MOCK: applicationDidBecomeActive called");
    // MOCK: Don't actually connect to messaging, just log
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"AppDelegate+FirebasePlugin MOCK: applicationDidEnterBackground called");
    // MOCK: Don't actually disconnect from messaging, just log
}

@end