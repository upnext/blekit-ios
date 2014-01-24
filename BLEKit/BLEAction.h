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

#import <Foundation/Foundation.h>

#import "BLEKitTypes.h"

@class BLETrigger, BLECondition;

typedef NS_ENUM(NSInteger, BLEActionState) {
    BLEActionStateForeground = 0,
    BLEActionStateBackground
};

static NSString * const BLEActionTypeAlert = @"alert";
static NSString * const BLEActionTypeFacebookCheckIn = @"facebook-checkin";
static NSString * const BLEActionTypeContent = @"content";
static NSString * const BLEActionTypeYelp = @"yelp";
static NSString * const BLEActionTypeNotification = @"notification";
static NSString * const BLEActionTypeFoursquareCheckIn = @"foursquare-checkin";

/**
 *  Keys used for action serialization to dictionary or to/from url
 */
static NSString * const BLEActionUniqueIdentifierKey = @"ble_action_id";
static NSString * const BLEActionEventTypeKey = @"ble_event_type";
static NSString * const BLETriggerUniqueIdentifierKey = @"ble_trigger_id";

@protocol BLEAction <NSObject, NSSecureCoding>

@required
/**
 *  Unique identifier for action. Required.
 *
 *  @return String
 */
- (NSString *) uniqueIdentifier;
/**
 *  Type of the action. Required.
 *
 *  For example: @c BLEActionTypeAlert
 *
 *  @return String
 */
- (NSString *) type;
/**
 *  Parameters for action. Required.
 *
 *  Parameters from loaded JSON configuration.
 *
 *  @return Dictionary
 */
- (NSDictionary *) parameters;
/**
 *  Trigger for the action. Required.
 *
 *  @return BLETrigger
 */
- (BLETrigger *) trigger;

/**
 *  Initialized for action instance. Required.
 *
 *  Designated initialized, but -init is called at first and you can put initializers for action parameters.
 *
 *  @param uniqueIdentifier unique indentifier
 *  @param trigger          trigger for action
 *
 *  @return Allocated instance
 */
- (instancetype) initWithUniqueIdentifier:(NSString *)uniqueIdentifier andTrigger:(BLETrigger *)trigger;

/**
 *  Perform action for beacon with given state. Required.
 *
 *  @param trigger   trigger
 *  @param state     state (foreground or background)
 *  @param eventType event type
 */
- (void) performBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType;

/**
 *  Check if action can be performed. Required.
 *
 *  If application can be performed then execution is counted as performed for occurency parameter.
 *
 *  @param trigger   trigger
 *  @param state     state (foreground or background)
 *  @param eventType event type
 *
 *  @return YES if application can be performed. YES by default.
 */
- (BOOL) canPerformBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType;

@optional

/**
 *  Handle application url callback. Optional.
 *
 *  @param url               url
 *  @param sourceApplication application source
 *  @param annotation        annotation
 *
 *  @see application:openURL:sourceApplication:annotation:
 *  @return Boolean value
 */
- (BOOL) handleURL:(NSURL *)url sourceApplication:(id)sourceApplication annotation:(id)annotation;
@end

/**
 *  Base implementation for BLEAction protocol
 */
@interface BLEAction : NSObject <BLEAction>

/**
 *  Unique identifier for action. Required.
 */
@property (strong) NSString *uniqueIdentifier;
/**
 *  Type of the action. Required.
 *
 *  For example: @c BLEActionTypeAlert
 */
@property (strong) NSString *type;
/**
 *  Parameters for action. Required.
 *
 *  Parameters from loaded JSON configuration.
 */
@property (strong) NSDictionary *parameters;
/**
 *  Trigger for the action. Required.
 */
@property (weak) BLETrigger *trigger;


/**
 *  Initialized for action instance. Required.
 *
 *  Designated initialized.
 *
 *  @param uniqueIdentifier unique indentifier
 *  @param trigger          trigger for action
 *
 *  @return newly initialized instance
 */
- (instancetype) initWithUniqueIdentifier:(NSString *)uniqueIdentifier andTrigger:(BLETrigger *)trigger;

/**
 *  Init with another action instance
 *
 *  @param action Action object
 *
 *  @return newly initialized instance
 */
- (instancetype) initWithAction:(id <BLEAction>)action;

/**
 *  Perform action for beacon with given state. Required.
 *
 *  @param trigger   trigger
 *  @param state     state (foreground or background)
 *  @param eventType event type
 */
- (void) performBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType;

@end
