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

#import "BLEContentAction.h"
#import "BLEContentViewController.h"
#import "BLEKit.h"

@interface BLEContentAction () <BLEContentViewControllerDelegate>
@property (strong) BLEContentViewController *contentViewController;
@end

@implementation BLEContentAction

- (instancetype) initWithUniqueIdentifier:(NSString *)uniqueIdentifier andTrigger:(BLETrigger *)trigger
{
    if (self = [super initWithUniqueIdentifier:uniqueIdentifier andTrigger:trigger]) {
        if (self.parameters[@"url"]) {
            self.url = [NSURL URLWithString:self.parameters[@"url"]];
        }
        self.message = self.parameters[@"message"] ?: self.message;
    }
    return self;
}

- (void) performBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    switch (state) {
        case BLEActionStateForeground:
        {
        	// Do something when in foreground
            [self showContentView];
        }
            break;
        case BLEActionStateBackground:
        {
        	// Do something when application is in background
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.soundName = UILocalNotificationDefaultSoundName;
            notification.alertAction = NSLocalizedString(trigger.beacon.name, nil);
            notification.alertBody = NSLocalizedString(self.message, nil);
            notification.fireDate  = nil;
            notification.alertLaunchImage = nil;

            notification.userInfo = @{BLEActionUniqueIdentifierKey: self.uniqueIdentifier,
                                      BLEActionEventTypeKey: @(eventType),
                                      BLETriggerUniqueIdentifierKey: trigger.uniqueIdentifier};

            
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        }
            break;
        default:
            break;
    }
    
}

static BOOL BLEContentActionIsVisible = NO;

- (BOOL)canPerformBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    if (!self.url)
        return NO;
    
    // if already visible then can't be performed
    if (BLEContentActionIsVisible)
        return NO;
    
    return YES;
}

#pragma mark - Private

- (UIViewController *)topViewController
{
    UIViewController *vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    UIViewController *topMostVC = vc;
    while (topMostVC.childViewControllers.count > 0) {
        topMostVC = [topMostVC.childViewControllers lastObject];
    }
    return topMostVC;
}

- (void) showContentView
{
    BLEContentActionIsVisible = YES;
    
    self.contentViewController = [[BLEContentViewController alloc] initWithURL:self.url action:self];
    self.contentViewController.view.frame = [UIApplication sharedApplication].keyWindow.bounds;
    self.contentViewController.delegate = self;
    
    UIViewController *topViewController = [self topViewController];
    
    // move topViewController
    [topViewController addChildViewController:self.contentViewController];
    [topViewController.view addSubview:self.contentViewController.view];
    [self.contentViewController didMoveToParentViewController:topViewController];
}

#pragma mark - BLEContentViewControllerDelegate

- (void)viewController:(id)viewController didPressCloseButton:(UIButton *)button
{
    [self.contentViewController willMoveToParentViewController:nil];
    [self.contentViewController.view removeFromSuperview];
    [self.contentViewController removeFromParentViewController];
    self.contentViewController = nil;
    BLEContentActionIsVisible = NO;
}

@end
