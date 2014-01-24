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

#import "BLEKitTypes.h"

@protocol BLEAction;
@class BLEAction, BLEBeacon;

@interface BLETrigger : NSObject <NSSecureCoding>

/**
 *  Unique identifier
 */
@property (strong) NSString *uniqueIdentifier;
/**
 *  Name of the trigger.
 */
@property (strong) NSString *name;
/**
 *  Comments.
 */
@property (strong) NSString *comment;
/**
 *  Beacon of this trigger.
 */
@property (weak) BLEBeacon *beacon;
/**
 *  Action for this trigger.
 */
@property (strong, nonatomic) id <BLEAction> action;
/**
 *  Set of conditions.
 *  @see BLECondition
 */
@property (strong) NSOrderedSet *conditions;

/**
 *  Initialize object
 *
 *  @param blebeacon beacon
 *
 *  @return Initialized object
 */
- (instancetype) initWithBeacon:(BLEBeacon *)blebeacon;

/**
 *  Validate trigger conditions and count as occurrence
 *
 *  @param eventType event type
 *
 *  @return YES if valid for all conditions
 */
- (BOOL) validateConditionsWithOccurrence:(BLEEventType)eventType;

/**
 *  Validate trigger conditions and don't count as occurrence
 *
 *  @param eventType event type
 *
 *  @return YES if valid for all conditions
 */
- (BOOL) validateConditionsWithoutOccurrency:(BLEEventType)eventType;

/**
 *  Validate event type
 *
 *  @param eventType event type
 *
 *  @return YES if valid for given event type
 */
- (BOOL) validateEventType:(BLEEventType)eventType;

@end
