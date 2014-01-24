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

@class BLEBeaconsRangeBatch;

@protocol BLEBeaconsRangeBatchDelegate <NSObject>
/**
 *  Process ranged batch
 *
 *  @param batch         Batch object
 *  @param rangedBeacons Ranged beacons
 */
- (void) processRangeBatch:(BLEBeaconsRangeBatch *)batch beacons:(NSArray *)rangedBeacons;
@end

/**
 * Cumulate ranged beacons for region and process every given period of time
 * this is workaround to be sure that we gather all near beacons already
 */
@interface BLEBeaconsRangeBatch : NSObject
/**
 *  Current batch
 */
@property (strong) NSMutableDictionary *batch;
/**
 *  Regions in current batch
 */
@property (strong, readonly) NSArray *regions;
/**
 *  Delegate
 *  @see BLEBeaconsRangeBatchDelegate
 */
@property (weak) id <BLEBeaconsRangeBatchDelegate> delegate;

/// Initialize with delegate

/**
 *  Initialize object with delegate
 *
 *  @param delegate delegate object
 *
 *  @return Initialized object
 */
- (instancetype) initWithDelegate:(id <BLEBeaconsRangeBatchDelegate>)delegate;

/// Add ranged beacons to batch

/**
 *  Add ranged beacons to batch
 *
 *  @param rangedBeacons Array of ranged beacons data (NSDictionary)
 *  @param region        region
 */
- (void) add:(NSArray *)rangedBeacons forRegion:(CLBeaconRegion *)region;

@end
