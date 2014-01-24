# iOS BLEKit Library

An iOS library for BLEKit developers to ease interaction with iBeacons.

## What does this library do?

It allows pre-configured interaction with Beacons. 

Configuration is provided in JSON file format - either directly or as a link to an existing JSON on the web.

Basic objects present in configuration are:

* BLEAction - represents an action to be executed, eg. show a Dialog with a given message or perform a check-in to Facebook

* BLECondition - represents a condition that has to be met in order for the BLEAction to be executed, eg. 'enter' (beacon has appeared), 'cameImmediate' (beacon is in close proximity to the device)

It is possible to write your own custom BLEActions and BLEConditions and provide them to the BLEKit instance.

## How to use this library

The prefered method to install BLEKit is by using [CocoaPods](http://cocoapods.org).

The latest release can be installed with the following line:

````
pod 'BLEKit', :podspec => 'https://raw.github.com/upnext/blekit-ios/master/BLEKit.podspec'
````

Because of Cocoapods integration please use workspace (*.xcworkspace*) for Xcode to build library or Example application (example application can be found in **Example** folder).

##Example

Example application can be found in **Example** folder.

##Usage

####Basic setup

````
NSError *error = nil;

BLEKit *blekit = [BLEKit kitWithZoneAtPath:jsonPath error:&error];

// remember to retain blekit instance!
self.blekit = blekit;

if (error) {
    NSLog(@"Can't initialize BLEKit. %@", error);
}

````

start looking for beacons

````
    if (![self.bleKit startLookingForBeacons]) {
    	// problem, check you settings (bluetooth, background refresh, location permission etc...)
    }
````

Please refer to the documentation for other ways to initialize object, including download from URL

####Handlers

Handlers are the simplest way to handle events on configured beacons.

````
    for (BLEBeacon *beacon in blekit.beacons) {

        [beacon setOnChangeProximityCallback:^(BLEBeacon *b) {
            NSLog(@"Proximity of beacon %@ changed to value %@", b.identifier, @(b.proximity));
            // Move beacon on view based on current proximity
            [self updateProximity:b];
        }];

        [beacon setOnEnterCallback:^(BLEBeacon *b) {
            NSLog(@"Beacon %@ did enter region", b.identifier);

            // Show beacon on view
            [self showBeacon:b];
        }];

        [beacon setOnExitCallback:^(BLEBeacon *b) {
            NSLog(@"Beacon %@ did leave region", b.identifier);

            // Remove beacon from view
            [self removeBeacon:b];
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
````

Please check the BLEKit sample application for details.

####Handle application delegate

````
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self.bleKit applicationOpenURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [self.bleKit applicationDidReceiveLocalNotification:notification.userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self.bleKit applicationDidReceiveRemoteNotification:userInfo];
}
````

##Built-in actions

BLEKit comes with built-in support for a number of predefined actions, sucg as `alert`, `facebook-checkin`, `foursquare-checkin`, `content`

##Dependencies

This library is dependent on the Facebook SDK, the Foursquare SDK, and SAMCache component.

##Tutorials & How-to

###Custom Action Tutorial
####Create Action class

First you have to specify a delegate for your BLEKit instance.

````
self.blekit.delegate = self;
````

Action classes need to conform to the *BLEAction* protocol. The easiest way to do this is by extending the `BLEAction` class. If your class inherits from BLEAction and needs to initialize parameters for your `UPCustomAlertAction`, then this should be done with the designated initializer `-initWithUniqueIdentifier:andTrigger:`


````
@interface UPCustomAlertAction : BLEAction <BLEAction>
	// Custom property for custom action
    @property (strong) NSString *customProperty;
@end
````

It is essential to override the method `-performBeaconAction:forState:eventType` in the following manner:

````
- (void) performBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    switch (state) {
        case BLEActionStateForeground:
        {
        	// Do something when in foreground
        	NSLog(@"Foreground %@",self.customProperty);
        }
            break;
        case BLEActionStateBackground:
        {
        	// Do something when application is in background
        	NSLog(@"Background %@",self.customProperty);
        }
            break;
        default:
            break;
    }

}

- (BOOL) canPerformBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
	return YES
}

````

####Custom action for beacon

If you have developed class `UPCustomAlertAction` for action type "custom-alert" (defined in JSON file) and want to handle it, the handler should be registered in the following way:

````
[BLEKit registerClass:[UPCustomAlertAction class] forActionType:@"custom-alert"];
````

####Local and Remote notifications

It is convienient to use notifications (Push or Local) to inform the user about an action while the application is in the background. If you wish to handle the action, you have to pass the action data to be performed back to the application. This should be done by specyifying userInfo value with appropriate identifiers like this:

    UILocalNotification *notification = [[UILocalNotification alloc] init];
	notification.userInfo = @{BLEActionUniqueIdentifierKey: self.uniqueIdentifier, BLETriggerUniqueIdentifierKey: self.trigger.uniqueIdentifier};
	
	[[UIApplication sharedApplication] presentLocalNotificationNow:notification];


####Lifetime of single Action

An action will run automatically. However, it is important to remember that an action is not retained longer than for `-performBeaconAction:forState:eventType`. Therefore, to do something asynchronously or to keep an action instance longer, a strong reference should be fept for as long as necessary.

####License

This software is available under the MIT License, allowing you to use the library in your applications.

If you would like to contribute to the open source project, contact blekit@up-next.com