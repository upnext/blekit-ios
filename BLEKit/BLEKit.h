/*
 * Copyright (c) 2014 UP-NEXT. All rights reserved.
 * http://www.up-next.com
 *
 * Marcin Krzyżanowski <marcink@up-next.com>
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "BLEKitTypes.h"

#import "BLEZone.h"
#import "BLEBeacon.h"
#import "BLETrigger.h"
#import "BLEAction.h"

#import "BLEFacebookAction.h"
#import "BLEAlertAction.h"
#import "BLEContentAction.h"
#import "BLEYelpAction.h"
#import "BLENotificationAction.h"
#import "BLEFoursquareAction.h"

#import "BLECondition.h"
#import "BLELocation.h"
#import "BLEKitDelegate.h"

/**
 *  Bluetooth is unavailable
 */
static NSString * const BLEBluetoothUnavailableNotification = @"BLEBletoothUnavailable";
/**
 *  Bluetooth is available
 */
static NSString * const BLEBluetoothAvailableNotification = @"BLEBletoothAvailable";


/**
 *  BLEKit Class. Main class for the framework.
 */
@interface BLEKit : NSObject

/**
 *  Beacons.
 *  @see BLEBeacon
 */
@property (strong, readonly) NSSet *beacons;
/**
 *  Set of actions
 *  @see BLEAction
 */
@property (strong, readonly) NSSet *actions;
/**
 *  Processing status. YES if processing is paused.
 */
@property (assign) BOOL paused;
/**
 *  @see BLEKitDelegate
 */
@property (weak) id <BLEKitDelegate> delegate;

/**
 *  Initialize with known beacons.
 *
 *  @param blebeacons Set of beacons
 *  @see BLEBeacon
 *  @return Initialized object
 */
- (instancetype) initWithBeacons:(NSSet *)blebeacons;

/**
 *  Initialize with Zone
 *
 *  @param zone BLEZone instance
 *
 *  @return Initialized object
 */
- (instancetype) initWithZone:(BLEZone *)zone;

/**
 *  Initialize with zone raw JSON data
 *
 *  @param zoneData Zone data
 *  @param error    error or nil
 *
 *  @return Initialized object
 */
- (instancetype) initWithZoneData:(NSData *)zoneData error:(NSError * __autoreleasing *)error;

/**
 *  Initialize with JSON data from file at given path.
 *
 *  @param path  Path to JSON file.
 *  @param error error or nil.
 *
 *  @return Initialized object
 */
- (instancetype) initWithZoneAtPath:(NSString *)path error:(NSError * __autoreleasing *)error;

/**
 *  Allocate and initialize BLEKit with JSON file at given path.
 *
 *  @param path  Path to JSON file
 *  @param error error or nil
 *
 *  @return Initialized object
 */
+ (BLEKit *) kitWithZoneAtPath:(NSString *)path error:(NSError * __autoreleasing *)error;

/**
 *  Allocate and initialize BLEKit with JSON file at given URL.
 *
 *  @param url   URL to JSON
 *  @param error error or nil
 *
 *  @return Initialized object
 */
+ (BLEKit *) kitWithZoneAtURL:(NSURL *)url error:(NSError * __autoreleasing *)error;

/**
 *  Register class handler for given action type
 *
 *  @param actionClass Class that can handle given action type
 *  @param actionType  Action type defined in JSON
 */
+ (void) registerClass:(Class <BLEAction>)actionClass forActionType:(NSString *)actionType;

/**
 *  Handle remote notification from application delegate
 *  @see application:didReceiveRemoteNotification:
 */


/**
 *  Handle remote notification from application delegate
 *
 *  @param application          Caller application
 *  @param notificationUserInfo notification userInfo
 */
- (void) applicationDidReceiveRemoteNotification:(NSDictionary *)notificationUserInfo;

/**
 *  Handle local notification from application delegate
 *
 *  @param notificationUserInfo notification userInfo
 */
- (void) applicationDidReceiveLocalNotification:(NSDictionary *)notificationUserInfo;

/**
 *  Handle notification from application delegate
 *
 *  @param url               url
 *  @param sourceApplication application
 *  @param annotation        annotation
 *
 *  @return YES if handled
 */
- (BOOL) applicationOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;


/** 
 *  Start observing beacons, register regions.
 *  @see stopLookingForBeacons
 */
- (BOOL) startLookingForBeacons;
/**
 *  Un-Register observed regions.
 *  @see startLookingForBeacons;
 */
- (void) stopLookingForBeacons;

/**
 *  Manually perform action for given beacon and event type.
 *
 *  @param eventType event type
 *  @param beacon    beacon instance
 */
- (void) performAction:(BLEEventType)eventType beacon:(BLEBeacon *)beacon;


@end
