//
//  UPBeraconViewController.h
//  BLEKitTestApp
//
//  Created by Marcin Krzyzanowski on 22/01/14.
//  Copyright (c) 2014 Upnext. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BLEKit/BLEKit.h>

@interface UPBeaconViewController : UIViewController
@property (strong) BLEBeacon *beacon;
- (void) configureForBeacon:(BLEBeacon *)beacon;

@end
