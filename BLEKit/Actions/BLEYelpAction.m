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
#import <AFOAuth1Client/AFOAuth1Client.h>

#import "BLEYelpAction.h"
#import "BLEContentViewController.h"
#import "BLEKit.h"

#import "YLClient.h"

@interface BLEYelpAction () <BLEContentViewControllerDelegate>
@property (strong) BLEContentViewController *contentViewController;
@end

@implementation BLEYelpAction

- (void) performBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    switch (state) {
        case BLEActionStateForeground:
        {
        	// Do something when in foreground
            [self showYelp];
        }
            break;
        case BLEActionStateBackground:
        {
        	// Do something when application is in background
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.soundName = UILocalNotificationDefaultSoundName;
            notification.alertAction = NSLocalizedString(trigger.beacon.zone.name, nil);
            notification.alertBody = NSLocalizedString(self.parameters[@"message"] ?: @"Yelp action", nil);
            notification.alertLaunchImage = nil;
            notification.hasAction = YES;
            
            //TODO: do is somehow general setup
            notification.userInfo = @{BLEActionUniqueIdentifierKey: self.uniqueIdentifier,
                                      BLEActionEventTypeKey: @(eventType),
                                      BLETriggerUniqueIdentifierKey: trigger.uniqueIdentifier};
            
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            break;
        }
            break;
        default:
            break;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#ifdef DEBUG
    NSLog(@"dealloc %@", [self class]);
#endif
}

- (UIViewController *)topViewController
{
    UIViewController *vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    UIViewController *topMostVC = vc;
    while (topMostVC.childViewControllers.count > 0) {
        topMostVC = [topMostVC.childViewControllers lastObject];
    }
    return topMostVC;
}

- (BOOL)isYelpInstalled {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yelp:"]];
}


/**
 Open Yelp application is available.
 Open Mobile website for business location as content view;
 */
- (void) showYelp
{
    YLClient *yelp = [[YLClient alloc] init];
    NSString *resourcePath = [@"business" stringByAppendingPathComponent:self.parameters[@"business_id"]];
    [yelp getPath:resourcePath
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSDictionary *yelpData = responseObject;
              if ([self isYelpInstalled]) {
                  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"yelp4:///biz/%@",yelpData[@"id"]]]];
              } else {
                  NSURL *mobileURL = [NSURL URLWithString:yelpData[@"mobile_url"]];
                  
                  self.contentViewController = [[BLEContentViewController alloc] initWithURL:mobileURL action:self];
                  self.contentViewController.view.frame = [UIApplication sharedApplication].keyWindow.frame;
                  self.contentViewController.delegate = self;

                  UIViewController *topViewController = [self topViewController];

                  // move topViewController
                  [topViewController addChildViewController:self.contentViewController];
                  [topViewController.view addSubview:self.contentViewController.view];
                  [self.contentViewController didMoveToParentViewController:topViewController];
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          }];
}

#pragma mark - BLEContentViewControllerDelegate

- (void)viewController:(id)viewController didPressCloseButton:(UIButton *)button
{
    [self.contentViewController willMoveToParentViewController:nil];
    [self.contentViewController.view removeFromSuperview];
    [self.contentViewController removeFromParentViewController];
    self.contentViewController = nil;
}

@end
