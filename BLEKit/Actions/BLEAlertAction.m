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

#import <UIKit/UIKit.h>

#import "BLEAlertAction.h"
#import "BLETrigger.h"

@implementation BLEAlertAction

- (instancetype) initWithUniqueIdentifier:(NSString *)uniqueIdentifier andTrigger:(BLETrigger *)trigger
{
    if (self = [super initWithUniqueIdentifier:uniqueIdentifier andTrigger:trigger]) {
        self.title = self.parameters[@"title"] ?: nil;
        self.message = self.parameters[@"message"] ?: nil;
    }
    return self;
}


#pragma mark - BLEAction

- (void) performBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    switch (state) {
        case BLEActionStateForeground:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.title ?: trigger.name
                                                            message:self.message ?: @""
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                  otherButtonTitles:nil];
            [alert show];
        }
            break;
        case BLEActionStateBackground:
        {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.soundName = UILocalNotificationDefaultSoundName;
            notification.alertAction = self.title ?: NSLocalizedString(@"Action", @"BLEAlertAction default title");
            notification.alertBody = self.message ?: @"";
            notification.fireDate  = nil;
            notification.alertLaunchImage = nil;
            
            //TODO: do is somehow general setup (see yelp)
            notification.userInfo = @{BLEActionUniqueIdentifierKey: self.uniqueIdentifier,
                                      BLEActionEventTypeKey: @(eventType),
                                      BLETriggerUniqueIdentifierKey: trigger.uniqueIdentifier};
            
            
            notification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        }
            break;
        default:
            break;
    }
}

@end
