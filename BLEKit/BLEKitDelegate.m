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

#import "BLEKitDelegate.h"
#import "BLEKit.h"
#import "BLEAction.h"

@implementation BLEKitDefaultDelegate

- (id <BLEAction>)actionObjectForBeacon:(BLEBeacon *)blebeacon trigger:(BLETrigger *)trigger eventType:(BLEEventType)eventType
{
    // trigger.action is action automatically created based on backend data (web actions)
    
    id <BLEAction> action = nil;
    NSString *actionType = [trigger.action.type lowercaseString];
    if ([actionType isEqualToString:BLEActionTypeAlert]) {
        BLEAlertAction *alertAction = [[BLEAlertAction alloc] initWithAction:trigger.action];
        action = alertAction;
    } else if ([actionType isEqualToString:BLEActionTypeFacebookCheckIn]) {
        BLEFacebookAction *fbAction = [[BLEFacebookAction alloc] initWithAction:trigger.action];
        action = fbAction;
    } else if ([actionType isEqualToString:BLEActionTypeContent]) {
        BLEContentAction *contentAction = [[BLEContentAction alloc] initWithAction:trigger.action];
        action = contentAction;
    } else if ([actionType isEqualToString:BLEActionTypeYelp]) {
        BLEYelpAction *yelpAction = [[BLEYelpAction alloc] initWithAction:trigger.action];
        action = yelpAction;
    } else if ([actionType isEqualToString:BLEActionTypeNotification]) {
        BLENotificationAction *notificationAction = [[BLENotificationAction alloc] initWithAction:trigger.action];
        action = notificationAction;
    } else if ([actionType isEqualToString:BLEActionTypeFoursquareCheckIn]) {
        BLEFoursquareAction *foursquareAction = [[BLEFoursquareAction alloc] initWithAction:trigger.action];
        action = foursquareAction;
    }
    
    return action;
}

- (void)beacon:(BLEBeacon *)beacon didPerformAction:(id<BLEAction>)action
{
    
}

@end
