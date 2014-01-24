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

#import "BLEEventScheduler.h"

@implementation BLEEventScheduler

- (instancetype)init
{
    if (self = [super init]) {
        self.timers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) scheduleEventForBeacon:(BLEBeacon *)beacon afterDelay:(NSTimeInterval)delay onTime:(void(^)(BLEBeacon *beacon))callback
{
    @synchronized(self) {
        if (!self.timers) {
            self.timers = [NSMutableDictionary dictionary];
        }

        UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"blekit-event-scheduler" expirationHandler:^{
            NSLog(@"Application about to terminate with timers %@", self.timers);
        }];
        
        NSDictionary *userInfo = @{@"beacon": beacon, @"delay": @(delay), @"callback": [callback copy], @"backgroundTaskIdentifier": @(backgroundTaskIdentifier)};
        
        if ([self isScheduledForBeacon:beacon]) {
            [self cancelForBeacon:beacon];
        }

        // Schedule event for delay
        __weak typeof(self)selfWeak = self;
        NSTimer *timer = [NSTimer timerWithTimeInterval:delay target:selfWeak selector:@selector(handleTimer:) userInfo:userInfo repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        
        [self.timers setObject:@{@"userInfo":userInfo, @"timer": timer} forKey:beacon.identifier];
    }
}

- (void) handleTimer:(NSTimer *)timer
{
    @synchronized(self) {
        void (^callback)(BLEBeacon *beacon) = [timer.userInfo objectForKey:@"callback"];
        
        UIBackgroundTaskIdentifier timerBackgroundTaskIdentifier = [timer.userInfo[@"backgroundTaskIdentifier"] unsignedIntegerValue];
        UIBackgroundTaskIdentifier newBackgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];

        BLEBeacon *beacon = timer.userInfo[@"beacon"];
        if (callback) {
            callback(beacon);
        }

        [self.timers removeObjectForKey:beacon.identifier];
        
        if (newBackgroundTaskIdentifier != UIBackgroundTaskInvalid)
            [[UIApplication sharedApplication] endBackgroundTask:newBackgroundTaskIdentifier];
        
        if (timerBackgroundTaskIdentifier != UIBackgroundTaskInvalid)
            [[UIApplication sharedApplication] endBackgroundTask:timerBackgroundTaskIdentifier];
    }
}

- (BOOL) cancelForBeacon:(BLEBeacon *)beacon
{
    @synchronized(self) {
        
        if (!self.timers)
            return NO;
        
        NSDictionary *timerDict = self.timers[beacon.identifier];
        if (timerDict) {
            NSTimer *timer = timerDict[@"timer"];
            NSDictionary *userInfo = timerDict[@"userInfo"]; //workaround for crashin timer.userInfo
            
            // stop background if any
            UIBackgroundTaskIdentifier backgroundTaskIdentifier = [userInfo[@"backgroundTaskIdentifier"] unsignedIntegerValue];
            
            if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            }

            if (timer.isValid) {
                [timer invalidate];
            }
            
            [self.timers removeObjectForKey:beacon.identifier];
        }
        return NO;
    }
}

- (BOOL) isScheduledForBeacon:(BLEBeacon *)beacon
{
    @synchronized(self) {
        id obj = self.timers[beacon.identifier];
        return obj ? YES : NO;
    }
}


@end
