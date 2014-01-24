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

@class BLEBeacon, BLEZone, BLECondition, BLEAction, BLETrigger;
@protocol BLEAction;

#pragma mark - Protocol

/**
 @protocol BLEKitDelegate
 */
@protocol BLEKitDelegate <NSObject>
@required

/**
 *  Called immediately after the action is performed. Required.
 *
 *  @param beacon beacon
 *  @param action action
 */
- (void) beacon:(BLEBeacon *)beacon didPerformAction:(id <BLEAction>)action;

@optional
/**
 *  Custom action object to handle given trigger. Optional.
 *
 *  @param blebeacon beacon
 *  @param trigger   trigger
 *  @param eventType event type
 *
 *  @return Instance of action object for given type. If nil then action is not handled by this approach.
 */
- (id <BLEAction>)actionObjectForBeacon:(BLEBeacon *)blebeacon trigger:(BLETrigger *)trigger eventType:(BLEEventType)eventType;
@end

#pragma mark - Default delegate implementation

/**
 *  Default delegate used if no user delegate is specified. This class routes to built-in action handlers
 */
@interface BLEKitDefaultDelegate : NSObject <BLEKitDelegate>

@end
