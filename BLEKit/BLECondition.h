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

@class BLETrigger, BLECondition;

@interface BLECondition : NSObject <NSSecureCoding>


/**
 *  Type of condition
 */
@property (strong) NSString *type;
/**
 *  Parameters for condition
 */
@property (strong) NSDictionary *parameters;
/**
 *  Expression string
 */
@property (strong) NSString *expression;

/**
 *  Trigger for condition
 */
@property (weak) BLETrigger *trigger;

/**
 *  Initialize instance with trigger object
 *
 *  @param trigger trigger
 *
 *  @return initialized instance
 */
- (instancetype) initWithTrigger:(BLETrigger *)trigger;

/**
 *  Check for event type.
 *
 *  @param eventType Event type
 *
 *  @return YES if condition is valid for eventType
 */
- (BOOL) validateForEventType:(BLEEventType)eventType;


/**
 *  Validate parameters.
 *
 *  @param withOccurrency count as occurrence
 *
 *  @return YES if parameters are valid with the current state of beacon
 */
- (BOOL) validateForParameters:(BOOL)withOccurrency;

@end
