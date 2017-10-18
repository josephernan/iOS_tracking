//
//  AppDelegate.m
//  My GPS Tracker
//
//  Created by Derk Humblet on 09/06/16.
//  Copyright © 2016 mygpstracker. All rights reserved.
//

#import "AppDelegate.h"
#import "Firebase.h"
#import "WebViewController.h"
#import "TWMessageBarManager.h"
#import "AudioToolbox/AudioToolbox.h"

@interface AppDelegate ()


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerForPushNotifications:application];

    [FIRApp configure];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"cqtech-ios", @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                                 name:kFIRInstanceIDTokenRefreshNotification object:nil];
    return YES;
}

- (void)registerForPushNotifications:(UIApplication*)application {
    //https://nrj.io/simple-interactive-notifications-in-ios-8/
    UIUserNotificationType types = (UIUserNotificationTypeAlert|
                                    UIUserNotificationTypeSound|
                                    UIUserNotificationTypeBadge);
    
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:Nil];
    [application registerUserNotificationSettings:notificationSettings];
}

- (void)tokenRefreshNotification:(NSNotification *)notification {
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
    NSLog(@"InstanceID token: %@", refreshedToken);
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:refreshedToken forKey:@"FIREBASE_FCM_TOKEN"];
    [prefs synchronize];
    
    // Connect to FCM since connection may have failed when attempted before having a token.
    [self connectToFcm];
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[FIRMessaging messaging] disconnect];
    NSLog(@"Disconnected from FCM");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self connectToFcm];
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

#pragma mark Firebase

- (void)connectToFcm {
    [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Unable to connect to FCM. %@", error);
        } else {
            NSLog(@"Connected to FCM.");
        }
    }];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(nonnull UILocalNotification *)notification {
    NSLog(@"did receive local notif");
    //NSLog(@"First: %@", notification.userInfo[@"first"]);
    //NSNumber *eventIdNumber = [notification.userInfo objectForKey:@"event"];
    //NSString *eventId = [notification.userInfo objectForKey:@"event"];
    //NSNumber *numFirst = [notification.userInfo objectForKey:@"first"];
    /*NSLog(@"timeintervalsincenow: %f", notification.fireDate.timeIntervalSinceNow);
    if (notification.fireDate.timeIntervalSinceNow > 0.5) {
        NSLog(@"eventid: %@", eventId);
        NSString *req = [NSString stringWithFormat:@"eventsShowEvent(%@);", eventId];
        [((WebViewController*) self.window.rootViewController) evalJs:req];
    }*/
    /*numFirst = [NSNumber numberWithInt:0];
    NSMutableDictionary *userdict = [notification.userInfo mutableCopy];
    [userdict setObject:numFirst forKey:@"first"];
    notification.userInfo = userdict;*/
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSString *eventId = [userInfo objectForKey:@"event.id"];
    NSString *type = [userInfo objectForKey:@"type"];
    NSString *link = [userInfo objectForKey:@"url"];
    
    NSLog(@"remote notif %@", userInfo);
    
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateActive) {
        NSString *msgbody = [userInfo objectForKey:@"body"];
        NSString *msgtitle = [userInfo objectForKey:@"title"];
        
        if (eventId != NULL || link != NULL) {
            SystemSoundID soundID = 0;
            NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"notif" ofType:@"caf"];
            NSURL *soundFileURL = [NSURL fileURLWithPath:soundPath];
            OSStatus errorCode = AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundFileURL, &soundID);
            NSLog(@"errorcode: %d", (int)errorCode);
            if (errorCode == 0) {
                AudioServicesPlayAlertSoundWithCompletion(soundID, nil);
            }
            
            [[TWMessageBarManager sharedInstance] showMessageWithTitle:msgtitle
                                                           description:msgbody
                                                                  type:TWMessageBarMessageTypeInfo
                                                              duration:5.0
                                                              callback:^{
                                                                  NSLog(@"callback called...");
                                                                  if ([type isEqualToString:@"event"]) {
                                                                      NSString *req = [NSString stringWithFormat:@"eventsShowEvent(%@);", eventId];
                                                                      [((WebViewController*) self.window.rootViewController) evalJs:req];
                                                                  } else if ([type isEqualToString:@"subscription"]) {
                                                                      NSURL *url = [NSURL URLWithString:link];
                                                                      [[UIApplication sharedApplication] openURL:url];
                                                                  }
                                                              }];
        }
    } else if (state == UIApplicationStateBackground) {
        if ([type isEqualToString:@"event"]) {
            NSString *req = [NSString stringWithFormat:@"eventsShowEvent(%@);", eventId];
            [((WebViewController*) self.window.rootViewController) evalJs:req];
        } else if ([type isEqualToString:@"subscription"]) {
            NSURL *url = [NSURL URLWithString:link];
            [[UIApplication sharedApplication] openURL:url];
        }
    } else {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setInteger:eventId.intValue forKey:@"FIREBASE_FCM_EVENT_ID"];
        [prefs synchronize];
        
        if ([type isEqualToString:@"subscription"]) {
            NSURL *url = [NSURL URLWithString:link];
            [[UIApplication sharedApplication] openURL:url];
        }
    }
    completionHandler(UIBackgroundFetchResultNewData);
}

#pragma mark Token

// With "FirebaseAppDelegateProxyEnabled": NO
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *deviceTokenString = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"Device token: %@", deviceTokenString);
    [[FIRInstanceID instanceID] setAPNSToken:deviceToken type:FIRInstanceIDAPNSTokenTypeUnknown];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    if (notificationSettings.types != UIUserNotificationTypeNone) {
        [application registerForRemoteNotifications];
    }
}

@end
