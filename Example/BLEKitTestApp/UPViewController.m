//
//  UPViewController.m
//  BLEKitTestApp
//
//  Created by Michael Dominic K. on 28.11.13.
//  Copyright (c) 2013 Upnext. All rights reserved.
//

#import "UPViewController.h"
#import "UPAppDelegate.h"
#import "UPCustomAction.h"
#import "UPBeaconViewController.h"

@interface UPViewController ()
@property (strong) NSTimer *timer;
@end

@implementation UPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UPAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    BLEKit *blekit =  appDelegate.bleKit;

    __weak typeof(self)selfWeak = self;
    for (BLEBeacon *beacon in blekit.beacons) {

        [beacon setOnChangeProximityCallback:^(BLEBeacon *b) {
            NSLog(@"Proximity of beacon %@ changed to value %@", b.identifier, @(b.proximity));
            // Move beacon on view based on current proximity
            [selfWeak updateProximity:b];
        }];

        [beacon setOnEnterCallback:^(BLEBeacon *b) {
            NSLog(@"Beacon %@ did enter region", b.identifier);

            // Show beacon on view
            [selfWeak showBeacon:b];
        }];

        [beacon setOnExitCallback:^(BLEBeacon *b) {
            NSLog(@"Beacon %@ did leave region", b.identifier);

            // Remove beacon from view
            [selfWeak removeBeacon:b];
        }];

        [beacon setOnPerformActionCallback:^BOOL(BLEBeacon *b, id<BLEAction> action, BLEEventType eventType, BOOL isPush) {
            NSLog(@"Action class %@", [action class]);

            if ([action isKindOfClass:[UPCustomAction class]]) {
                /**
                 *  Returns NO to prevent action to be performed, so action can be handled here
                 *
                 *  return NO;
                 */
            }
            
            return YES;
        }];
    }

    // Schedule timer based update of beacon details
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateBeaconDescription) userInfo:nil repeats:YES];
}

- (void) updateBeaconDescription
{
    NSArray *beaconViewControllers = [self.childViewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.class == %@", [UPBeaconViewController class]]];
    for (UPBeaconViewController *beaconVC in beaconViewControllers) {
        [beaconVC configureForBeacon:beaconVC.beacon];
    }
}

- (void) updateProximity:(BLEBeacon *)beacon
{
    NSParameterAssert(beacon);

    UPBeaconViewController *beaconVC = [self beaconViewController:beacon];
    if (!beaconVC) {
        beaconVC = [self showBeacon:beacon];
    }

    switch (beacon.proximity) {
        case CLProximityFar:
            beaconVC.view.center = CGPointMake(beaconVC.view.center.x, 100);
            break;
        case CLProximityNear:
            beaconVC.view.center = CGPointMake(beaconVC.view.center.x, 300);
            break;
        case CLProximityImmediate:
            beaconVC.view.center = CGPointMake(beaconVC.view.center.x, 500);
            break;
        default:
            break;
    }
}

- (UPBeaconViewController *) showBeacon:(BLEBeacon *)beacon
{
    NSParameterAssert(beacon);

    UPBeaconViewController *existsBeaconViewController = [self beaconViewController:beacon];
    if (existsBeaconViewController)
        return existsBeaconViewController;

    UPBeaconViewController *beaconViewController = [[UPBeaconViewController alloc] initWithNibName:NSStringFromClass([UPBeaconViewController class]) bundle:nil];
    [self addChildViewController:beaconViewController];
    [self.view addSubview:beaconViewController.view];
    [beaconViewController configureForBeacon:beacon];
    [beaconViewController didMoveToParentViewController:self];

    return beaconViewController;
}

- (void) removeBeacon:(BLEBeacon *)beacon
{
    NSParameterAssert(beacon);

    UPBeaconViewController *beaconVC = [self beaconViewController:beacon];
    if (beaconVC && [beaconVC.beacon.identifier isEqualToString:beacon.identifier]) {
        [beaconVC willMoveToParentViewController:nil];
        [beaconVC.view removeFromSuperview];
        [beaconVC removeFromParentViewController];
    }
}

#pragma mark - Helper

- (UPBeaconViewController *) beaconViewController:(BLEBeacon *)beacon
{
    NSParameterAssert(beacon);

    NSArray *beaconViewControllers = [self.childViewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.class == %@ && SELF.beacon.identifier == %@", [UPBeaconViewController class], beacon.identifier]];
    if (beaconViewControllers.count > 0)
        return beaconViewControllers[0];

    return nil;
}



@end
