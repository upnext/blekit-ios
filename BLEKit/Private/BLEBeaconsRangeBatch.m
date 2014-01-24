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

#import "BLEBeaconsRangeBatch.h"

#define BLERangingSecondsTimeFrame 2

// timeout value since last read. After that amount of time batch is cheared out
#define BLERangingSecondsTimeout 120

static NSDate *lastRanging;

@implementation BLEBeaconsRangeBatch

- (instancetype) initWithDelegate:(id <BLEBeaconsRangeBatchDelegate>)delegate
{
    if (self = [self init]) {
        self.delegate = delegate;
    }
    return self;
}


- (void) add:(NSArray *)rangedBeacons forRegion:(CLBeaconRegion *)region
{
    @synchronized(self) {
        if (!self.batch) {
            self.batch = [NSMutableDictionary dictionary];
            [self resetForRegion:region];
        }
        
        NSTimeInterval timeIntervalSinceLastRanging = [[NSDate date] timeIntervalSinceDate:lastRanging ?: [NSDate dateWithTimeIntervalSinceReferenceDate:0]];
        if (timeIntervalSinceLastRanging >= BLERangingSecondsTimeout) {
            [self resetForRegion:region];
        }
        
        lastRanging = [NSDate date];
        
        NSArray *beaconsInBatch = self.batch[region.identifier][@"beacons"];
        if (beaconsInBatch.count > 0) {
            // if time elapsed from the last read is significant I assume that there was
            // break and batch is processed as new
            NSDate *refDate = self.batch[region.identifier][@"refdate"];
            NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:refDate];
            if (timeInterval >= BLERangingSecondsTimeout) {
                [self resetForRegion:region];
            }
            // expand
            beaconsInBatch = [beaconsInBatch arrayByAddingObjectsFromArray:rangedBeacons];
            self.batch[region.identifier] = @{@"refdate": refDate, @"beacons": beaconsInBatch};

            // reset batch after rangingTimeFrame
            if (timeInterval >= BLERangingSecondsTimeFrame && timeInterval < BLERangingSecondsTimeout) {
                id <BLEBeaconsRangeBatchDelegate> delegateStrong = self.delegate;
                if ([delegateStrong conformsToProtocol:@protocol(BLEBeaconsRangeBatchDelegate)]) {
                    [delegateStrong processRangeBatch:self beacons:beaconsInBatch];
                }
                [self resetForRegion:region];
            }
        } else {
            // init with ranged beacons
            self.batch[region.identifier] = @{@"refdate": [NSDate date], @"beacons": rangedBeacons};
        }
    }
}

- (NSArray *) regions
{
    @synchronized(self) {
        return [self.batch allKeys];
    }
}

- (void) resetForRegion:(CLBeaconRegion *)region
{
    self.batch[region.identifier] = @{@"refdate": [NSDate date], @"beacons": [NSArray array]};
}

@end
