//
//  AppDelegate.m
//  Layer-Parse-iOS-Example
//
//  Created by Kabir Mahal on 3/25/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


#import <Atlas/Atlas.h>

#import <Parse/Parse.h>
#import "AppDelegate.h"

@implementation AppDelegate

#pragma mark TODO: Before first launch, update LayerAppIDString, ParseAppIDString or ParseClientKeyString values
#warning "TODO:If LayerAppIDString, ParseAppIDString or ParseClientKeyString are nil, this app will crash"
static NSString *const LayerAppIDString = @"layer:///apps/staging/05cd95ba-b10d-11e5-b2a6-2584730b1501";
static NSString *const ParseAppIDString = @"mKfIUPAVSlDv8TD0wfOI7msbYnLgLmoc2VF2Fz8Y";
static NSString *const ParseClientKeyString = @"o286gDSBdW7JqR2nANZ47wOwO1MeTVKTMVhPGRKn";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    
    // Checking if app is running iOS 8
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        // Register device for iOS8
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:notificationSettings];
        [application registerForRemoteNotifications];
    } else {
        // Register device for iOS7
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge];
    }
    
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    if (LayerAppIDString.length == 0 || ParseAppIDString.length == 0 || ParseClientKeyString.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Invalid Configuration" message:@"You have not configured your Layer and/or Parse keys. Please check your configuration and try again." delegate:nil cancelButtonTitle:@"Rats!" otherButtonTitles:nil];
        [alertView show];
        return YES;
    }
    // Enable Parse local data store for user persistence
    [Parse enableLocalDatastore];
    [Parse setApplicationId:ParseAppIDString
                  clientKey:ParseClientKeyString];
    
    // Set default ACLs
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    // Initializes a LYRClient object
    NSURL *appID = [NSURL URLWithString:LayerAppIDString];    
    self.layerClient = [LYRClient clientWithAppID:appID];
    self.layerClient.autodownloadMIMETypes = [NSSet setWithObjects:ATLMIMETypeImagePNG, ATLMIMETypeImageJPEG, ATLMIMETypeImageJPEGPreview, ATLMIMETypeImageGIF, ATLMIMETypeImageGIFPreview, ATLMIMETypeLocation, nil];
    
    // Show View Controller
    self.controller = [ViewController new];
    self.controller.layerClient = self.layerClient;
    
    
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.controller];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}





- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{

// Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveInBackground];
    
    NSError *error;
    BOOL success = [self.layerClient updateRemoteNotificationDeviceToken:deviceToken error:&error];
    if (success) {
        NSLog(@"Application did register for remote notifications");
    } else {
        NSLog(@"Error updating Layer device token for push:%@", error);
    }
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if ([userInfo objectForKey:@"layer"] != nil)
    {
        BOOL userTappedRemoteNotification = application.applicationState == UIApplicationStateInactive;
        __block LYRConversation *conversation = [self conversationFromRemoteNotification:userInfo];
        if (userTappedRemoteNotification && conversation) {
            [self navigateToViewForConversation:conversation];
             NSLog([NSString stringWithFormat:@"%@", conversation]);
        } else if (userTappedRemoteNotification) {
            [SVProgressHUD showWithStatus:@"Loading Conversation" maskType:SVProgressHUDMaskTypeBlack];
        }
        
        BOOL success = [self.layerClient synchronizeWithRemoteNotification:userInfo completion:^(NSArray *changes, NSError *error) {
            if (changes.count) {
                completionHandler(UIBackgroundFetchResultNewData);
            } else {
                completionHandler(error ? UIBackgroundFetchResultFailed : UIBackgroundFetchResultNoData);
            }
            
            // Try navigating once the synchronization completed
            if (userTappedRemoteNotification && !conversation) {
                [SVProgressHUD dismiss];

            }
        }];
        
        if (!success) {
            completionHandler(UIBackgroundFetchResultNoData);

        }
    }
    else
    {
        NSLog(@"userInfo: %@",userInfo);
        [PFPush handlePush:userInfo];
        completionHandler(UIBackgroundFetchResultNewData);

        
    }
}

- (LYRConversation *)conversationFromRemoteNotification:(NSDictionary *)remoteNotification
{
    NSURL *conversationIdentifier = [NSURL URLWithString:[remoteNotification valueForKeyPath:@"layer.conversation_identifier"]];
    NSLog([NSString stringWithFormat:@"%@", conversationIdentifier]);

    return [self existingConversationForIdentifier:conversationIdentifier];
}

- (void)navigateToViewForConversation:(LYRConversation *)conversation
{
   // [self.controller.conversationListViewController selectConversation:conversation];

    if (![NSThread isMainThread]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Attempted to navigate UI from non-main thread" userInfo:nil];
    }
    
    if(self.controller.conversationListViewController != nil )
    {
        [self.controller.conversationListViewController selectConversation:conversation];
    }
    else
    {
//[self.controller.conversationListViewController selectConversation:conversation];
    }
    
}

- (LYRConversation *)existingConversationForIdentifier:(NSURL *)identifier
{
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRConversation class]];
    query.predicate = [LYRPredicate predicateWithProperty:@"identifier" predicateOperator:LYRPredicateOperatorIsEqualTo value:identifier];
    query.limit = 1;
    return [self.layerClient executeQuery:query error:nil].firstObject;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    application.applicationIconBadgeNumber = 0;
}


@end
