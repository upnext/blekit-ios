//
//  UPBeraconViewController.m
//  BLEKitTestApp
//
//  Created by Marcin Krzyzanowski on 22/01/14.
//  Copyright (c) 2014 Upnext. All rights reserved.
//

#import "UPBeaconViewController.h"

@interface UPBeaconViewController ()
@property (weak) IBOutlet UILabel *identifierLabel;
@property (weak) IBOutlet UILabel *accuracyLabel;
@end

@implementation UPBeaconViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)dealloc
{
    NSLog(@"dealloc");
}

- (void) configureForBeacon:(BLEBeacon *)beacon
{
    self.beacon = beacon;
    self.identifierLabel.text = beacon.identifier;
    self.accuracyLabel.text = [NSString stringWithFormat:@"Accuracy: %.2f",beacon.accuracy];
}


@end
