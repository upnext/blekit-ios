//
//  UPAppDelegate.h
//  BLEKitTestApp
//
//  Created by Michael Dominic K. on 28.11.13.
//  Copyright (c) 2013 Upnext. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BLEKit/BLEKit.h>

@interface UPAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;

@property (strong) BLEKit *bleKit;

@end
