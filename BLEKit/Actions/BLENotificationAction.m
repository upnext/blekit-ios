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

#import "BLENotificationAction.h"
#import "BLETrigger.h"
#import "BLEAction.h"

@implementation BLENotificationAction

- (void) performBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    switch (state) {
        case BLEActionStateForeground:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:trigger.action.parameters[@"name"] object:self userInfo:@{BLENotificationTriggerKey: trigger}];
            });
        }
            break;
        case BLEActionStateBackground:
        {
        	//TODO: persistent queued notifications
            break;
        }
            break;
        default:
            break;
    }
}

- (BOOL)canPerformBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    return (state == BLEActionStateForeground);
}

@end
