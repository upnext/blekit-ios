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
#import "BLEKit.h"

//@class BLEEventScheduler;
//
//@protocol BLEEventSchedulerDelegate <NSObject>
//- (void) bleEventScheduler:(BLEEventScheduler*) scheduler perform:(NSInvocation *)invocation;
//@end

/**
 *  Schedule events for later execution. Used to delay 'leave' action.
 */
@interface BLEEventScheduler : NSObject

@property (assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (strong) NSMutableDictionary *timers;

/**
 *  Schedule event for later.
 *
 *  @param beacon   Beacon
 *  @param delay    Delay value in seconds
 *  @param callback On time callback block
 */
- (void) scheduleEventForBeacon:(BLEBeacon *)beacon afterDelay:(NSTimeInterval)delay onTime:(void(^)(BLEBeacon *beacon))callback;

/// Cancel scheduled event for given beacon
/// @return YES if cancelled, NO if not found (not cancelled)

/**
 *  Cancel scheduled event
 *
 *  @param beacon beacon
 *
 *  @return YES if canelled.
 */
- (BOOL) cancelForBeacon:(BLEBeacon *)beacon;

/**
 *  Check if beacon have scheduled event
 *
 *  @param beacon beacon
 *
 *  @return YES if event is scheduled for beacon
 */
- (BOOL) isScheduledForBeacon:(BLEBeacon *)beacon;


@end
