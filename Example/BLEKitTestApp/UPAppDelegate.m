//
//  UPAppDelegate.m
//  BLEKitTestApp
//
//  Created by Michael Dominic K. on 28.11.13.
//  Copyright (c) 2013 Upnext. All rights reserved.
//

#import "UPAppDelegate.h"

@implementation UPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"zone" ofType:@"json"];

    /**
     *  Initialize BLEKit instance with json configuration from file zone.json
     */
    NSError *error = nil;
    self.bleKit = [BLEKit kitWithZoneAtPath:jsonPath error:&error];
    if (error) {
        NSLog(@"Can't initialize BLEKit. %@", error);
    }

    NSParameterAssert(self.bleKit);

    /**
     *  Setup handler for custom action "custom-alert" type.
     *
     *  [BLEKit registerClass:[UPCustomAlertAction class] forActionType:@"custom-alert"];
     */

    /**
     *  Start looking for beacons from loaded file
     */
    if (![self.bleKit startLookingForBeacons]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Unable to start looking for beacons" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [alert show];
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self.bleKit applicationOpenURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [self.bleKit applicationDidReceiveLocalNotification:notification.userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self.bleKit applicationDidReceiveRemoteNotification:userInfo];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
