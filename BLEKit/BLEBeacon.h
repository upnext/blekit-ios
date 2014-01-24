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

//  An app can register up to 20 regions at a time.
//  In order to report region changes in a timely manner, the region monitoring service requires network connectivity.

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "BLEKitTypes.h"

extern NSString * const BLEInvalidBeaconIdentifierException;
extern NSString * const BLEBeaconTimerFireNotification;

#define BLEBeaconStaysCacheName(beacon) \
    [NSString stringWithFormat:@"com.up-next.BLEKit.stays.%@",beacon.identifier]

@class BLELocation, BLEZone;
@protocol BLEAction;

@interface BLEBeacon : CLBeacon <NSSecureCoding, NSCopying>

@property (readwrite, nonatomic, strong) NSUUID *proximityUUID;
@property (readwrite, nonatomic, strong) NSNumber *major;
@property (readwrite, nonatomic, strong) NSNumber *minor;
@property (readwrite, nonatomic, assign) CLProximity proximity;
@property (readwrite, nonatomic, assign) CLLocationAccuracy accuracy;
@property (readwrite, nonatomic, assign) NSInteger rssi;

/**
 *  Name of the beacon.
 */
@property (strong) NSString *name;
/**
 *  Additional description for the beacon.
 */
@property (strong) NSString *description;
/**
 *  Optional parameters for beacon.
 */
@property (strong) NSDictionary *parameters;
/**
 *  Time from last enter to zone region. How long beacon stays in its zone.
 */
@property (assign, readonly) NSTimeInterval staysTimeInterval;

/**
 *  Zone for the beacon
 */
@property (weak) BLEZone *zone;
/**
 *  Location of the beacon
 */
@property (strong) BLELocation *location;
/**
 *  Triggers defined for beacon
 */
@property (strong) NSSet *triggers;
/**
 *  Identifier
 *
 *  String of proximityUUID+major+minor
 */
@property (readonly) NSString *identifier;

/// On enter callback

/**
 *  Callback called on enter region event
 */
@property (copy) void(^onEnterCallback)(BLEBeacon *beacon);
/**
 *  Callback called on leave region event
 */
@property (copy) void(^onExitCallback)(BLEBeacon *beacon);
/**
 *  Callback called on change proximity for the beacon
 */
@property (copy) void(^onChangeProximityCallback)(BLEBeacon *beacon);
/**
 *  Callback called on about to perform action. If block returns NO then action is not performed and can be handled entirely by this caller.
 */
@property (copy) BOOL(^onPerformActionCallback)(BLEBeacon *beacon, id <BLEAction> action, BLEEventType eventType, BOOL isPush);

/**
 *  Intialize beacon with zone
 *
 *  @param zone Zone instance
 *
 *  @return Initialized object
 */
- (instancetype) initWithZone:(BLEZone *)zone;

@end
