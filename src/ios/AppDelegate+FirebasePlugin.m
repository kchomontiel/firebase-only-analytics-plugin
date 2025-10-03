#import "AppDelegate+FirebasePlugin.h"
#import "FirebasePlugin.h"
#import "Firebase.h"
@import Firebase;
@import FirebaseAnalytics;
#import <objc/runtime.h>

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
  @import UserNotifications;

  // Implement UNUserNotificationCenterDelegate to receive display notification via APNS for devices
  // running iOS 10 and above. Implement FIRMessagingDelegate to receive data message via FCM for
  // devices running iOS 10 and above.
  @interface AppDelegate () <UNUserNotificationCenterDelegate, FIRMessagingDelegate>
  @end
#endif

#define kApplicationInBackgroundKey @"applicationInBackground"
#define kDelegateKey @"delegate"

@implementation AppDelegate (FirebasePlugin)

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

- (void)setDelegate:(id)delegate {
    objc_setAssociatedObject(self, kDelegateKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)delegate {
    return objc_getAssociatedObject(self, kDelegateKey);
}

#endif

+ (void)load {
    Method original = class_getInstanceMethod(self, @selector(application:didFinishLaunchingWithOptions:));
    Method swizzled = class_getInstanceMethod(self, @selector(application:swizzledDidFinishLaunchingWithOptions:));
    method_exchangeImplementations(original, swizzled);

    //Dynamic Link
    Method originalDL = class_getInstanceMethod(self, @selector(application:openURL:options:));
    Method swizzledDL = class_getInstanceMethod(self, @selector(swizzled_application:openURL:options:));
    method_exchangeImplementations(originalDL, swizzledDL);
    Method originalMDL = class_getInstanceMethod(self, @selector(application:continueUserActivity:restorationHandler:));
    Method swizzledMDL = class_getInstanceMethod(self, @selector(swizzled_application:continueUserActivity:restorationHandler:));
    method_exchangeImplementations(originalMDL, swizzledMDL);
}
//DL
-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    return FALSE;
}

- (BOOL)swizzled_application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    // always call original method implementation first
    BOOL handled = [self swizzled_application:app openURL:url options:options];
    FirebasePlugin* dl = [self.viewController getCommandInstance:@"FirebasePlugin"];
    // parse firebase dynamic link
    FIRDynamicLink *dynamicLink = [[FIRDynamicLinks dynamicLinks] dynamicLinkFromCustomSchemeURL:url];
    if (dynamicLink) {
        [dl postDynamicLink:dynamicLink];
        handled = TRUE;
    }
    return handled;
}

-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler{
    return FALSE;
}

- (BOOL)swizzled_application:(UIApplication *)app continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    // always call original method implementation first
    BOOL handled = [self swizzled_application:app continueUserActivity:userActivity restorationHandler:restorationHandler];
    FirebasePlugin* dl = [self.viewController getCommandInstance:@"FirebasePlugin"];
    // handle firebase dynamic link
    return [[FIRDynamicLinks dynamicLinks]
        handleUniversalLink:userActivity.webpageURL
        completion:^(FIRDynamicLink * dynamicLink, NSError * error) {
            if (dynamicLink) {
                [dl postDynamicLink:dynamicLink];
            } else {
                [[FIRDynamicLinks dynamicLinks] dynamicLinkFromUniversalLinkURL:userActivity.webpageURL];
                if (dynamicLink){
                    [dl postDynamicLink:dynamicLink];
                }
            }
        }] || handled;
}
//DL<

- (void)setApplicationInBackground:(NSNumber *)applicationInBackground {
    objc_setAssociatedObject(self, kApplicationInBackgroundKey, applicationInBackground, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)applicationInBackground {
    return objc_getAssociatedObject(self, kApplicationInBackgroundKey);
}

- (BOOL)application:(UIApplication *)application swizzledDidFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"FirebasePlugin - Finished launching");
    [self application:application swizzledDidFinishLaunchingWithOptions:launchOptions];

    
    [FIRApp configure];

   
    [FIRMessaging messaging].delegate = self;
     
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;


    [[UIApplication sharedApplication] registerForRemoteNotifications];

    //[FIRApp configure];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                                 name:FIRMessagingRegistrationTokenRefreshedNotification object:nil];
    
    self.applicationInBackground = @(YES);
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
   // [self connectToFcm];
    self.applicationInBackground = @(NO);
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
   // [[FIRMessaging messaging] disconnect];  //modified
    self.applicationInBackground = @(YES);
   //NSLog(@"FirebasePlugin - Disconnected from FCM");  //modified
}

- (void)tokenRefreshNotification:(NSNotification *)notification {
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
    
    /* MODIFIED
    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
    NSLog(@"FirebasePlugin - InstanceID token: %@", refreshedToken);

    // Connect to FCM since connection may have failed when attempted before having a token.
    [self connectToFcm];
    [FirebasePlugin.firebasePlugin sendToken:refreshedToken];
    */
    [[FIRMessaging messaging] tokenWithCompletion:^(NSString * _Nullable token, NSError * _Nullable error) {
        if (token != nil) {
            [FirebasePlugin.firebasePlugin sendToken:token];
        }
    }];
}
/* MODIFIED
- (void)connectToFcm {
    [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"FirebasePlugin - Unable to connect to FCM. %@", error);
        } else {
            NSLog(@"FirebasePlugin - Connected to FCM.");
            NSString *refreshedToken = [[FIRInstanceID instanceID] token];
            NSLog(@"FirebasePlugin - InstanceID token: %@", refreshedToken);
        }
    }];
}*/

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [FIRMessaging messaging].APNSToken = deviceToken;
    NSLog(@"FirebasePlugin - deviceToken1 = %@", deviceToken);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSDictionary *mutableUserInfo = [userInfo mutableCopy];

    [mutableUserInfo setValue:self.applicationInBackground forKey:@"tap"];

    // Print full message.
    NSLog(@"FirebasePlugin - didReceiveRemoteNotification - before");
    NSLog(@"FirebasePlugin - Response %@", mutableUserInfo);
    NSLog(@"FirebasePlugin - didReceiveRemoteNotification - after");

    [FirebasePlugin.firebasePlugin sendNotification:mutableUserInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
    fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {

    NSDictionary *mutableUserInfo = [userInfo mutableCopy];

    [mutableUserInfo setValue:self.applicationInBackground forKey:@"tap"];

    // Print full message.
    NSLog(@"FirebasePlugin - didReceiveRemoteNotification:fetchCompletionHandler - before");
    NSLog(@"FirebasePlugin - Response %@", mutableUserInfo);
    NSLog(@"FirebasePlugin - didReceiveRemoteNotification:fetchCompletionHandler - after");

    completionHandler(UIBackgroundFetchResultNewData);
    [FirebasePlugin.firebasePlugin sendNotification:mutableUserInfo];
}

// [START ios_10_data_message]
// Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
// To enable direct data messages, you can set [Messaging messaging].shouldEstablishDirectChannel to YES.

/*MODIFIED
- (void)messaging:(FIRMessaging *)messaging didReceiveMessage:(FIRMessagingRemoteMessage *)remoteMessage {
    NSLog(@"FirebasePlugin - didReceiveMessage");
    NSLog(@"FirebasePlugin - Received data message: %@", remoteMessage.appData);

    // This will allow us to handle FCM data-only push messages even if the permission for push
    // notifications is yet missing. This will only work when the app is in the foreground.
    [FirebasePlugin.firebasePlugin sendNotification:remoteMessage.appData];
}
// [END ios_10_data_message]

*/
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  NSLog(@"FirebasePlugin - Unable to register for remote notifications: %@", error);
}

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
           
    NSLog(@"FirebasePlugin - willPresentNotification:withCompletionHandler - 1");

    [self.delegate userNotificationCenter:center
              willPresentNotification:notification
                withCompletionHandler:completionHandler];

    if (![notification.request.trigger isKindOfClass:UNPushNotificationTrigger.class])
        return;

    NSDictionary *mutableUserInfo = [notification.request.content.userInfo mutableCopy];

    [mutableUserInfo setValue:self.applicationInBackground forKey:@"tap"];

    // Print full message.
    NSLog(@"FirebasePlugin - willPresentNotification:withCompletionHandler - before");
    NSLog(@"FirebasePlugin - Response %@", mutableUserInfo);
    NSLog(@"FirebasePlugin - willPresentNotification:withCompletionHandler - after");

    completionHandler(UNNotificationPresentationOptionAlert);
    [FirebasePlugin.firebasePlugin sendNotification:mutableUserInfo];
}

- (void) userNotificationCenter:(UNUserNotificationCenter *)center
 didReceiveNotificationResponse:(UNNotificationResponse *)response
          withCompletionHandler:(void (^)(void))completionHandler
{
    NSLog(@"FirebasePlugin - didReceiveNotificationResponse:withCompletionHandler - 1");
            
    [self.delegate userNotificationCenter:center
       didReceiveNotificationResponse:response
                withCompletionHandler:completionHandler];

    if (![response.notification.request.trigger isKindOfClass:UNPushNotificationTrigger.class])
        return;

    NSDictionary *mutableUserInfo = [response.notification.request.content.userInfo mutableCopy];

    [mutableUserInfo setValue:@YES forKey:@"tap"];

    // Print full message.
    NSLog(@"FirebasePlugin - didReceiveNotificationResponse:withCompletionHandler - before");
    NSLog(@"FirebasePlugin - Response %@", mutableUserInfo);
    NSLog(@"FirebasePlugin - didReceiveNotificationResponse:withCompletionHandler - after");

    [FirebasePlugin.firebasePlugin sendNotification:mutableUserInfo];

    completionHandler();
}
/*MODIFIED
// Receive data message on iOS 10 devices.
- (void)applicationReceivedRemoteMessage:(FIRMessagingRemoteMessage *)remoteMessage {
    // Print full message
    NSLog(@"FirebasePlugin - applicationReceivedRemoteMessage");
    NSLog(@"%@", [remoteMessage appData]);
}*/
#endif

@end