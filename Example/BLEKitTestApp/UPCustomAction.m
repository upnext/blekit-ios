//
//  UPCustomAction.m
//  BLEKitTestApp
//
//  Created by Marcin Krzyzanowski on 22/01/14.
//  Copyright (c) 2014 Upnext. All rights reserved.
//

#import "UPCustomAction.h"

@implementation UPCustomAction

- (void)performBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    /**
     *  Show alert
     */
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@",[self class]] message:@"Hi!" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [alertView show];
}

- (BOOL)canPerformBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    /**
     *  Foreground only
     */
    return (state == BLEActionStateForeground);
}

@end
