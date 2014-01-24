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
#import <CoreLocation/CoreLocation.h>

#import "UNCoding.h"

@class BLELocation;

@interface BLEZone : NSObject <UNCoding>

/**
 *  Zone identifier
 */
@property (strong) NSString *identifier;
/**
 *  Zone name
 */
@property (strong) NSString *name;
/**
 *  Zone description
 */
@property (strong) NSString *desc;
/**
 *  Zone time to life
 */
@property (assign) NSInteger timeToLife;
/**
 *  Zone location coordinates
 */
@property (strong) BLELocation *location;
/**
 *  Associated beacons for the zone. @c BLEBeacon
 */
@property (strong) NSSet *beacons;

/**
 *  Initialized
 *
 *  @param identifier Zone identifier
 *  @param name       Zone name
 *  @param timeToLife Time to life
 *
 *  @return Initialized object
 */
- (instancetype) initWithIdentifier:(NSString *)identifier name:(NSString *)name timeToLife:(NSInteger)timeToLife;

/** Initialize with JSON */

/**
 *  Initialize with JSON data
 *
 *  @param jsonData JSON data
 *  @param error    Returned error object
 *
 *  @return Initialized object
 */
- (instancetype) initWithJSON:(NSData *)jsonData error:(NSError * __autoreleasing *)error;
- (instancetype) initWithJSONAtPath:(NSString *)jsonPath error:(NSError * __autoreleasing *)error;
- (instancetype) initWithJSONAtURL:(NSURL *)url error:(NSError * __autoreleasing *)error;

/** Initialize object with zone definition */

/**
 *  Allocate and initialize object with JSON at given source
 *
 *  @param jsonPath JSON file path
 *  @param error    Returned error object
 *
 *  @return Allocated and initialized object;
 */
+ (BLEZone *) zoneWithJSONAtPath:(NSString *)jsonPath error:(NSError * __autoreleasing *)error;
+ (BLEZone *) zoneWithJSONAtURL:(NSURL *)url error:(NSError * __autoreleasing *)error;
+ (BLEZone *) zoneWithJSON:(NSData *)jsonData error:(NSError * __autoreleasing *)error;

/** Fetch zone */
/**
 *  Fetch zone from URL. Synchronous.
 *
 *  @param zoneURL URL
 *
 *  @return Zone instance
 */
+ (BLEZone *) fetchZoneFromURL:(NSURL *)zoneURL;
/**
 *  Fetch zone from URL. Asynchronous.
 *
 *  @param zoneURL    URL
 *  @param completion completion block.
 */
+ (void) fetchAsyncZoneFromURL:(NSURL *)zoneURL completion:(void(^)(BLEZone *zone, NSError *error))completion;

@end
