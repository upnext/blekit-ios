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

#import "BLEKit.h"
#import "BLEKitPrivate.h"

#import "CLBeacon+BLEKit.h"

#import "BLEKitTypes.h"

#import "UNURLConnection.h"

#import "SAMCache+BLEKit.h"
#import "BLEBeaconsRangeBatch.h"
#import "BLEEventScheduler.h"

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>

#import <FacebookSDK/FacebookSDK.h>

#define BLEDelayEventTimeInterval 1

/**
 *  Did receive local notification
 *  Notification userInfo is accessible with @c BLEDidReceiveLocalNotificationKeya
 *  @see application:didReceiveLocalNotification:
 */
static NSString * const BLEDidReceiveNotification = @"BLEDidReceivePushNotification";

static NSString * const BLEDidReceiveLocalUserInfoKey = @"BLEDidReceiveLocalUserInfoKey";
static NSString * const BLEDidReceiveRemoteUserInfoKey = @"BLEDidReceiveRemoteUserInfoKey";

static NSString * const monitoredRegionIdentifiersKey = @"monitoredRegionIdentifiers";
static NSString * const sourceApplicationKey = @"sourceApplication";
static NSString * const annotationKey = @"annotation";
static NSString * const urlKey = @"url";

static NSMapTable *BLECustomActionClassess;

@interface BLEKit () <CLLocationManagerDelegate, CBCentralManagerDelegate, BLEBeaconsRangeBatchDelegate>
/**
 *  Beacons r/w
 */
@property (strong, readwrite) NSSet *beacons;
/**
 *  Location manager
 */
@property (strong) CLLocationManager *locationManager;
/**
 *  Check whenever application is in background (not frontmost)
 */
@property (nonatomic, readonly) BOOL isInBackground;
/**
 *  Returns current state (background or foreground) for action
 */
@property (nonatomic, readonly) BLEActionState currentActionState;
/**
 *  Recently ranged beacons
 */
@property (strong) BLEBeaconsRangeBatch *rangeBatch;
/**
 *  Delayed actions scheduler
 */
@property (strong) BLEEventScheduler *eventScheduler;
/**
 *  CoreBluetooth
 */
@property (strong) CBCentralManager *centralManager;
@end

@implementation BLEKit {
    /**
     *  Retain zone if initialized with zone;
     */
    BLEZone *_zone;
}

+ (void)initialize
{
    BLECustomActionClassess = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;

        self.defaultDelegate = [[BLEKitDefaultDelegate alloc] init];
        self.eventScheduler = [[BLEEventScheduler alloc] init];
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePushNotificationAction:) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePushNotificationAction:) name:BLEDidReceiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBeaconTimerEvent:) name:BLEBeaconTimerFireNotification object:nil];
    }
    return self;
}

- (instancetype) initWithBeacons:(NSSet *)blebeacons
{
    if (self = [self init]) {
        self.beacons = blebeacons;
    }
    return self;
}

- (instancetype) initWithZone:(BLEZone *)zone
{
    if (self = [self init]) {
        self.beacons = zone.beacons;
        self->_zone = zone;        
    }
    return self;
}

- (instancetype) initWithZoneData:(NSData *)zoneData error:(NSError * __autoreleasing *)error
{
    BLEZone *zone = [BLEZone zoneWithJSON:zoneData error:error];
    if (!zone || *error) {
        return nil;
    }
    
    if (self = [self initWithZone:zone]) {
        
    }
    
    return self;
}

- (instancetype) initWithZoneAtPath:(NSString *)path error:(NSError * __autoreleasing *)error
{
    if (self = [self initWithZoneData:[NSData dataWithContentsOfFile:path] error:error]) {
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (BLEKit *) kitWithZoneAtPath:(NSString *)path error:(NSError * __autoreleasing *)error
{
    return [[BLEKit alloc] initWithZoneAtPath:path error:error];
}

+ (BLEKit *) kitWithZoneAtURL:(NSURL *)url error:(NSError * __autoreleasing *)error
{
    return [[BLEKit alloc] initWithZone:[BLEZone zoneWithJSONAtURL:url error:error]];
}

#pragma mark - Getters

- (NSSet *)actions
{
    // Collect all available actions
    NSMutableSet *actions = [NSMutableSet setWithCapacity:1];
    for (BLEBeacon *beacon in self.beacons) {
        for (BLETrigger *trigger in beacon.triggers) {
            [actions addObject:trigger.action];
        }
    }
    return actions.count > 0 ? [actions copy] : nil;
}

- (BOOL) isInBackground
{
    return ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground || [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive);
}

- (BLEActionState)currentActionState
{
    return self.isInBackground ? BLEActionStateBackground : BLEActionStateForeground;
}

#pragma mark - RegisterClass

+ (void) registerClass:(Class <BLEAction>)actionClass forActionType:(NSString *)actionType;
{
    NSParameterAssert(actionClass);
    [BLECustomActionClassess setObject:actionClass forKey:actionType];
}

#pragma mark - Push Notifications

- (void) applicationDidReceiveRemoteNotification:(NSDictionary *)notificationUserInfo
{
    if (notificationUserInfo) {
        // Wait until application goes foreground
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:BLEDidReceiveNotification object:self userInfo:@{BLEDidReceiveRemoteUserInfoKey: notificationUserInfo}];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:self];
        }];
    }
}

- (void) applicationDidReceiveLocalNotification:(NSDictionary *)notificationUserInfo
{
    if (notificationUserInfo) {
        // Wait until application goes foreground
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:BLEDidReceiveNotification object:self userInfo:@{BLEDidReceiveLocalUserInfoKey: notificationUserInfo}];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:self];
        }];
    }
}

- (BOOL) applicationOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSParameterAssert(url);
    NSParameterAssert(sourceApplication);

    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *param in [url.query componentsSeparatedByString:@"&"]) {
        NSArray *elements = [param componentsSeparatedByString:@"="];
        if([elements count] < 2) continue;
        [params setObject:[elements objectAtIndex:1] forKey:[elements objectAtIndex:0]];
    }

    // Search for action
    NSSet *handledActions = [self searchForAction:params[BLEActionUniqueIdentifierKey]];

    for (id <BLEAction> generalAction in handledActions) {
        BLETrigger *trigger = generalAction.trigger;
        id <BLEAction> determinedActionInstance = [self determineActionObjectForBeacon:trigger.beacon trigger:trigger eventType:[params[BLEActionEventTypeKey] integerValue]];

        if ([determinedActionInstance respondsToSelector:@selector(handleURL:sourceApplication:annotation:)]) {
            if ([determinedActionInstance handleURL:url sourceApplication:sourceApplication annotation:annotation]) {
                return YES;
            }
        }
    }
    return NO;
}

/**
 *  Handler for received push notification. Check notification @c userInfo for details. Allways in foreground.
 *
 * @code
 * - (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
 * {
 *    [BLEKit applicationDidReceiveRemoteNotification:userInfo];
 * }
 * @endcode
 *
 *  @param notification @c BLEDidReceiveNotification or @c UIApplicationDidFinishLaunchingNotification
 */
- (void) handlePushNotificationAction:(NSNotification *)notification
{
    NSDictionary *notificationUserInfo = nil;
    if (notification.userInfo[UIApplicationLaunchOptionsLocalNotificationKey]) {
        UILocalNotification *localNotification = notification.userInfo[UIApplicationLaunchOptionsLocalNotificationKey];
        notificationUserInfo = localNotification.userInfo;
    } else if (notification.userInfo[BLEDidReceiveLocalUserInfoKey]) {
        notificationUserInfo = notification.userInfo[BLEDidReceiveLocalUserInfoKey];
    } else if (notification.userInfo[BLEDidReceiveRemoteUserInfoKey]) {
        notificationUserInfo = notification.userInfo[BLEDidReceiveRemoteUserInfoKey];
    }
    
    if (notificationUserInfo[BLEActionUniqueIdentifierKey]) {
        /**
         *  Perform beacon action
         */
        NSSet *handledActions = [self searchForAction:notificationUserInfo[BLEActionUniqueIdentifierKey]];
        for (id <BLEAction> generalAction in handledActions) {
            BLETrigger *trigger = generalAction.trigger;
            id <BLEAction> determinedActionInstance = [self determineActionObjectForBeacon:trigger.beacon trigger:trigger eventType:[notificationUserInfo[BLEActionEventTypeKey] integerValue]];
            if (determinedActionInstance) {
                BLEEventType eventType = [notificationUserInfo[BLEActionEventTypeKey] integerValue];
                
                /**
                 *  Without additional validation bacause this is queued aciton that should be performed without taking current status in scope
                 */
                BOOL canPerformAction = [determinedActionInstance canPerformBeaconAction:trigger forState:self.currentActionState eventType:eventType];

                BLEBeacon *beacon = trigger.beacon;
                if (canPerformAction && beacon.onPerformActionCallback) {
                    canPerformAction = beacon.onPerformActionCallback(beacon, determinedActionInstance, eventType, YES);
                }

                if (canPerformAction) {
                    [determinedActionInstance performBeaconAction:trigger forState:self.currentActionState eventType:eventType];
                }
            }
        }

    }
}

#pragma mark - Main Loop

- (void) stopLookingForBeacons
{
    // Unregister only these regions monitored by BLEKit. It may be region registered outside BLEKit though (registered before of after BLEKit but we don't know that).
    NSSet *monitoredRegionIdentifiers = [[SAMCache monitoredProximityCache] objectForKey:monitoredRegionIdentifiersKey];
    NSSet *monitoredRegions = [self.locationManager.monitoredRegions filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.identifier IN %@",monitoredRegionIdentifiers]];
    for (CLBeaconRegion *region in monitoredRegions) {
        if ([self.locationManager.rangedRegions containsObject:region]) {
            [self.locationManager stopRangingBeaconsInRegion:region];
        }
        [self.locationManager stopMonitoringForRegion:region];
    }
    [[SAMCache monitoredProximityCache] removeObjectForKey:monitoredRegionIdentifiersKey];
    
    for (BLEBeacon *beacon in self.beacons) {
        beacon.proximity = CLProximityUnknown;
        [self beaconProximityDidChange:beacon];
    }
}

- (BOOL) startLookingForBeacons
{
    if ([[UIApplication sharedApplication] backgroundRefreshStatus] < UIBackgroundRefreshStatusAvailable)
        return NO;

    if (![CLLocationManager locationServicesEnabled]) {
        return NO;
    }
    
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        return NO;
    }
    
    if (![CLLocationManager isRangingAvailable]) {
        return NO;
    }

    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        return NO;
    }
    
    // Register new regions
    NSMutableSet *monitoredRegionIdentifiers = [NSMutableSet setWithCapacity:self.beacons.count];
    for (BLEBeacon *blebeacon in self.beacons) {
        if (blebeacon.zone.identifier) {
            
            CLBeaconRegion *beaconRegion = nil;
            
            if (blebeacon.major && !blebeacon.minor) {
                beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:blebeacon.proximityUUID major:[blebeacon.major unsignedIntegerValue] identifier:blebeacon.identifier];
            } else if (blebeacon.major && blebeacon.minor) {
                beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:blebeacon.proximityUUID major:[blebeacon.major unsignedIntegerValue] minor:[blebeacon.minor unsignedIntegerValue] identifier:blebeacon.identifier];
            } else {
                beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:blebeacon.proximityUUID identifier:blebeacon.identifier];
            }
            beaconRegion.notifyOnEntry = YES;
            beaconRegion.notifyOnExit = YES;
            //FIXME: this perform didDetermineState every time phone go out of sleep
            //When set to YES, the location manager sends beacon notifications when the user turns on the display and the device is already inside the region.
            beaconRegion.notifyEntryStateOnDisplay = YES;
            
            [self.locationManager startMonitoringForRegion:beaconRegion];
            [monitoredRegionIdentifiers addObject:beaconRegion.identifier];
        }
    }
    
    // should I refresh observable regions?
    // remove previously monitored regions but not monitored any more. JSON changed.
    NSMutableSet *previouslyMonitoredRegionIdentifiers = [[[SAMCache monitoredProximityCache] objectForKey:monitoredRegionIdentifiersKey] mutableCopy];
    [previouslyMonitoredRegionIdentifiers minusSet:monitoredRegionIdentifiers];
    NSSet *regionsToRemove = [self.locationManager.monitoredRegions filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.identifier IN %@",previouslyMonitoredRegionIdentifiers]];
    for (CLRegion *region in regionsToRemove) {
        if ([self.locationManager.rangedRegions containsObject:region]) {
            [self.locationManager stopMonitoringForRegion:region];
        }
        [self.locationManager stopMonitoringForRegion:region];
    }

    // save monitored regions
    [[SAMCache monitoredProximityCache] setObject:monitoredRegionIdentifiers forKey:monitoredRegionIdentifiersKey];
    
    return YES;
}

- (id <BLEAction>) determineActionObjectForBeacon:(BLEBeacon *)blebeacon trigger:(BLETrigger *)trigger eventType:(BLEEventType)eventType
{
    NSParameterAssert(blebeacon);
    NSParameterAssert(trigger);
    
    __strong __typeof(self->_delegate)delegate = self.delegate;
    
    // Check for registered class for action type
    id <BLEAction> action = [[[BLECustomActionClassess objectForKey:trigger.action.type] alloc] initWithUniqueIdentifier:trigger.action.uniqueIdentifier andTrigger:trigger];
    
    // Check for delegate
    if (!action && delegate) {
        action = [delegate actionObjectForBeacon:blebeacon trigger:trigger eventType:eventType];
    }
    
    // Try default delegate
    if (!action || ![action conformsToProtocol:@protocol(BLEAction)]) {
        action = [self.defaultDelegate actionObjectForBeacon:blebeacon trigger:trigger eventType:eventType];
    }

    // finaly use BLEAction general instance
    if (!action || ![action conformsToProtocol:@protocol(BLEAction)]) {
        action = trigger.action;
    }

    return action;
}

- (void) handleBeaconTimerEvent:(NSNotification *)notification
{
    NSParameterAssert(notification);
    NSParameterAssert(notification.object);
    
    [self performAction:BLEEventTypeTimer beacon:notification.object];
}

/**
 Process enter/leave change for region.
 
 @param state New state for region
 @param region Beacon
 
 @discussion Because iOS API have some bugs and report enter/leave series without good reason
 we have implemented some delayed actions to check if this is real change or just
 invalid data received.
 */
- (void) processRegionState:(CLRegionState)state forRegion:(CLBeaconRegion *)region
{
    if (self.paused) {
#ifdef DEBUG
        NSLog(@"PAUSED");
#endif
        return;
    }
    
    NSParameterAssert(region);
    // search for beacon and call actions
    BLEBeacon *foundBeacon = [[self.beacons filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@",region.identifier]] anyObject];
    if (foundBeacon) {
        // search for trigger
        BLEEventType eventType = BLEEventTypeUnknown;
        switch (state) {
            case CLRegionStateInside:
                eventType = BLEEventTypeEnter;
                break;
            case CLRegionStateOutside:
                eventType = BLEEventTypeLeave;
                break;
            default:
                //@throw [NSException exceptionWithName:@"BLEKitUnknownEvent" reason:@"Unknown event" userInfo:nil];
                break;
        }

        if (eventType > BLEEventTypeUnknown) {
            // Schedule
            if (eventType == BLEEventTypeEnter) {
                // if leave is scheduled then unschedule leave and do nothing
                if ([self.eventScheduler isScheduledForBeacon:foundBeacon]) {
                    [self.eventScheduler cancelForBeacon:foundBeacon];
                } else {
                    // perform actual action
                    
                    //TODO: do it nicer
                    SAMCache *staysCache = [[SAMCache alloc] initWithName:BLEBeaconStaysCacheName(foundBeacon)];
                    [staysCache setObject:[NSDate date] forKey:foundBeacon.identifier];
                    
                    if (foundBeacon.onEnterCallback) {
                        foundBeacon.onEnterCallback(foundBeacon);
                    }
                    [self performAction:eventType beacon:foundBeacon];
                }
            } else if (eventType == BLEEventTypeLeave) {
                // schedule new leave cancelling old one (re-schedule)
                __weak typeof(self)selfWeak = self;
                [self.eventScheduler scheduleEventForBeacon:foundBeacon afterDelay:BLEDelayEventTimeInterval onTime:^(BLEBeacon *scheduledBeacon) {
                    // if beacon leave then assume that proximity is unknown (it's FAR FAr Far far away)
                    foundBeacon.proximity = CLProximityUnknown;

                    // clear stays cache
                    SAMCache *staysCache = [[SAMCache alloc] initWithName:BLEBeaconStaysCacheName(foundBeacon)];
                    [staysCache removeObjectForKey:foundBeacon.identifier];
                    
                    if (scheduledBeacon.onExitCallback) {
                        scheduledBeacon.onExitCallback(foundBeacon);
                    }
                    [selfWeak performAction:BLEEventTypeLeave beacon:scheduledBeacon];
                }];
            }
        }
        
    }
}


- (void) beaconProximityDidChange:(BLEBeacon *)blebeacon
{
    if (!blebeacon)
        return;
    
    if (blebeacon.onChangeProximityCallback) {
        blebeacon.onChangeProximityCallback(blebeacon);
    }
    
    [self performAction:BLEEventTypeRange beacon:blebeacon];
}

- (void) performAction:(BLEEventType)eventType beacon:(BLEBeacon *)beacon
{
    __strong __typeof(self.delegate)delegateStrong = self.delegate;
    NSParameterAssert(beacon);
    // Skip repeatable events in short period of time (due to hardware issues).
    // but for range event if defice is in state unable to determine for some time then guess that proximity is Far
    // This is performed only on change, but sometime there is much changes in short time - we should skip that and treat as disorder.
    for (BLETrigger *matchTrigger in beacon.triggers) {
        id <BLEAction, NSObject> action = [self determineActionObjectForBeacon:beacon trigger:matchTrigger eventType:eventType];

        if (action) {
            BOOL canPerformAction = [matchTrigger validateEventType:eventType];
            if (canPerformAction && [action respondsToSelector:@selector(canPerformBeaconAction:forState:eventType:)]) {
                canPerformAction = [action canPerformBeaconAction:matchTrigger forState:self.currentActionState eventType:eventType];
            }
            

            canPerformAction = canPerformAction && [matchTrigger validateConditionsWithoutOccurrency:eventType];
            if (canPerformAction) {
                [[SAMCache actionCache] incrementUsageNumberValueForAction:action];
            }
            
            canPerformAction = canPerformAction && [matchTrigger validateConditionsWithOccurrence:eventType];
            
            if (canPerformAction && beacon.onPerformActionCallback) {
                canPerformAction = beacon.onPerformActionCallback(beacon, action, eventType, NO);
            }

            if (canPerformAction) {
                // schedule for lated performing
                [action performBeaconAction:matchTrigger forState:self.currentActionState eventType:eventType];
                if (delegateStrong) {
                    [delegateStrong beacon:beacon didPerformAction:action];
                }
                
            }
        }
    }
}

#pragma mark - Other

/**
 *  Search for action
 *
 *  @param actionIdentifier unique identifier for action
 *
 *  @return Set with actions
 */
- (NSSet *) searchForAction:(NSString *)actionIdentifier
{
    NSParameterAssert(actionIdentifier);

    NSSet *actions = [self.actions objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        if (![obj conformsToProtocol:@protocol(BLEAction)])
            return NO;

        id <BLEAction> action = obj;
        if ([action.uniqueIdentifier isEqualToString:actionIdentifier]) {
            return YES;
        }
        return NO;
    }];

    return actions;
}

#pragma mark - CLLocationManagerDelegate

/**
 *  Not used. For debugging purposed only
 */
#ifdef DEBUG
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLBeaconRegion *)region
{
    if (state == CLRegionStateInside) {
        // Trick to start count stays even if application was already in area but lastEnter was not in the record
        BLEBeacon *foundBeacon = [[self.beacons filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@",region.identifier]] anyObject];
        {
            SAMCache *staysCache = [[SAMCache alloc] initWithName:BLEBeaconStaysCacheName(foundBeacon)];
            NSDate *lastEnter = [staysCache objectForKey:foundBeacon.identifier];
            if (!lastEnter) {
                [staysCache setObject:[NSDate date] forKey:foundBeacon.identifier];
            }
        }
    }
}
#endif

/**
 *  Gather ranged data and every period of time, process gathered data and clear batch
 */
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)rangedBeacons inRegion:(CLBeaconRegion *)region
{
    if (rangedBeacons.count == 0)
        return;
    
    if (self.isInBackground)
        return;

    if (!self.rangeBatch) {
        self.rangeBatch = [[BLEBeaconsRangeBatch alloc] initWithDelegate:self];
    }

    [self.rangeBatch add:rangedBeacons forRegion:region];
}

/**
 *  Enter to region
 */
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLBeaconRegion *)region
{
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    [self processRegionState:CLRegionStateInside forRegion:region];
    if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
    }
}

/**
 *  Leave region
 */
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLBeaconRegion *)region
{
    [self processRegionState:CLRegionStateOutside forRegion:region];
}

- (void) startRangingBeaconsInRegion:(CLBeaconRegion *)region
{
    [self.locationManager startRangingBeaconsInRegion:region];
}

/**
 * iOS correct proximity with the delay especially for multiple beacons available, so added this delay to let adjust at the start.
 */
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLBeaconRegion *)region
{
    [self performSelector:@selector(startRangingBeaconsInRegion:) withObject:region afterDelay:2];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"rangingBeaconsDidFailForRegion, reason: %@", error);
}

#pragma mark - CBCentralManagerDelegate

/**
 *  Detect if bluetooth is enabled and post notification about change.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state < CBCentralManagerStatePoweredOn) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BLEBluetoothUnavailableNotification object:self];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:BLEBluetoothAvailableNotification object:self];
    }
}

#pragma mark - BLEBeaconsRangeBatchDelegate

- (void)processRangeBatch:(BLEBeaconsRangeBatch *)batch beacons:(NSArray *)rangedBeacons
{
    if (self.paused) {
#ifdef DEBUG
        NSLog(@"PAUSED");
#endif
        return;
    }

    NSArray *knownRangedBeacons = [rangedBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"accuracy > 0"]];
    NSArray *rangedBeaconsSorted = [knownRangedBeacons sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"accuracy" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"rssi" ascending:YES]]];
    
    if (rangedBeaconsSorted.count > 0) {
        for (BLEBeacon *bleBeacon in self.beacons) {
            CLBeacon *rangedBeacon = rangedBeaconsSorted[0];
            if ([rangedBeacon.blekit_identifier hasPrefix:bleBeacon.identifier]) {
                bleBeacon.accuracy = rangedBeacon.accuracy;
                bleBeacon.rssi = rangedBeacon.rssi;
                // Guess the proximty based on accuracy value
                if (rangedBeacon.proximity != CLProximityUnknown && rangedBeacon.accuracy > 0) {
                    CLProximity guessedProximity = CLProximityUnknown;
                    if (rangedBeacon.accuracy < 0.5) {
                        guessedProximity = CLProximityImmediate;
                    } else if (rangedBeacon.accuracy <= 3.0) {
                        guessedProximity = CLProximityNear;
                    } else {
                        guessedProximity = CLProximityFar;
                    }
                    
                    if (bleBeacon.proximity != guessedProximity) {
                        bleBeacon.proximity = guessedProximity;
                        [self beaconProximityDidChange:bleBeacon];
                    }
                }
            }
        }
    }
}

@end
