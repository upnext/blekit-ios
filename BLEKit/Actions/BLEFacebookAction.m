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

#import "BLEFacebookAction.h"

#import "BLEKit.h"
#import "BLEKitPrivate.h"

#import "SAMCache+BLEKit.h"

#import <FacebookSDK/FacebookSDK.h>

@implementation BLEFacebookAction {
    UIBackgroundTaskIdentifier _bgTask;
}

- (instancetype) initWithUniqueIdentifier:(NSString *)uniqueIdentifier andTrigger:(BLETrigger *)trigger
{
    if (self = [super initWithUniqueIdentifier:uniqueIdentifier andTrigger:trigger]) {
        self.placeID = self.parameters[@"place_id"] ?: self.placeID;
        self.notificationMessage = self.parameters[@"notification_message"] ?: self.notificationMessage;
        self.notificationTitle = self.parameters[@"notification_title"] ?: self.notificationTitle ?: NSLocalizedString(@"Facebook check-in", nil);
        self.message = self.parameters[@"message"] ?: self.message;
        self.privacy = self.parameters[@"privacy"] ?: self.privacy;
        self.placeName = self.parameters[@"location"] ?: self.placeName;
        self.address = self.parameters[@"street"] ?: self.address;

        NSParameterAssert(self.placeID);
    }
    return self;
}

#pragma mark - BLEAction

- (void) performBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    if (state == BLEActionStateForeground) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(self.notificationTitle, nil) message:NSLocalizedString(self.notificationMessage, nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", nil) otherButtonTitles:nil];
        [alert show];
    }
    
    if ([FBSession openActiveSessionWithAllowLoginUI:NO]) {
        [self checkIn:^(NSError *error) {
            if (error) {
                if (self.onFailure) {
                    self.onFailure(error);
                }
                return;
            }
            [self handleSuccessMessageForState:state];
        }];
    }
}

- (BOOL)handleURL:(NSURL *)url sourceApplication:(id)sourceApplication annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}

- (BOOL)canPerformBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    BOOL ret = [super canPerformBeaconAction:trigger forState:state eventType:eventType];
    
    if (ret && state == BLEActionStateBackground) {
        ret = [BLEFacebookAction isAuthorized];
    }
    return ret;
}

#pragma mark - Public

+ (BOOL) isAuthorized
{
    if (FBSession.activeSession.isOpen && [self checkFacebookPermissions:FBSession.activeSession]) {
        return YES;
    }
    
    return NO;
}

+ (void) login:(void(^)(id sess, NSError *error))completion
{
    [FBSession renewSystemCredentials:^(ACAccountCredentialRenewResult result, NSError *error) {
        [[self class] loginAfterSync:completion];
    }];
}

#pragma mark - Private

// According to https://developers.facebook.com/docs/ios/upgrading/#30to31
// You are now required to request read and publish permission separately (and in that order). Most likely, you will request the read permissions for personalization when the app starts and the user first logs in. Later, if appropriate, your app can request publish permissions when it intends to post data to Facebook.
+ (void) openSession
{
    // Whenever a person opens the app, check for a cached session
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        [FBSession openActiveSessionWithPublishPermissions:BLEFacebookPublishPermissionsArray
                                           defaultAudience:FBSessionDefaultAudienceEveryone
                                              allowLoginUI:NO
                                         completionHandler:nil];
    }
}

+ (void) loginAfterSync:(void(^)(id sess, NSError *error))completion
{
    if (!FBSession.activeSession.isOpen || ![self checkFacebookPermissions:FBSession.activeSession]) {
        // first check if this is first time (no read permissions yet)
        __block BOOL wasOpened = NO;
        BOOL ret = [FBSession openActiveSessionWithReadPermissions:BLEFacebookReadPermissionsArray allowLoginUI:YES completionHandler:^(FBSession *session1, FBSessionState status, NSError *error) {
            if (wasOpened) {
                return;
            }
            
            if ((session1.state == FBSessionStateOpen) || (session1.state == FBSessionStateOpenTokenExtended)) {
                wasOpened = YES;
                if (![self checkFacebookPermissions:FBSession.activeSession]) {
                    [session1 requestNewPublishPermissions:BLEFacebookPublishPermissionsArray defaultAudience:BLEFacebookDefaultAudience completionHandler:^(FBSession *session2, NSError *error) {
                        if (session2.state == FBSessionStateOpenTokenExtended) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                completion(session2,error); // never called on web
                            });
                        }
                    }];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(session1, error);
                    });
                }
            } else if (error) {
                completion(session1, error);
            } else if (!error && !wasOpened && session1.state == FBSessionStateClosed) {
                // this is some kind of Facebook SDK issue
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, [NSError errorWithDomain:@"com.up-next.BLEKit" code:-1010 userInfo:@{NSLocalizedDescriptionKey: @"Unknown facebook SDK issue", NSLocalizedFailureReasonErrorKey: @"openActiveSessionWithReadPermissions fail for the first time. https://github.com/facebook/facebook-ios-sdk/issues/575"}]);
                });
            }
        }];
        
        if (ret) {
            completion(FBSession.activeSession, nil);
        }
        
    } else if (completion) {
        // do I need to do something here?
        completion(FBSession.activeSession, nil);
    }
}

+ (BOOL) checkFacebookPermissions:(FBSession *)session
{
    NSArray *permissions = [session permissions];
    NSArray *requiredPermissions = BLEFacebookPublishPermissionsArray;
    
    for (NSString *perm in requiredPermissions) {
        if (![permissions containsObject:perm]) {
            return NO; // required permission not found
        }
    }
    return YES;
}

- (void) handleSuccessMessageForState:(BLEActionState)state
{
    BLETrigger *trigger = self.trigger;
    BLEBeacon  *beacon  = trigger.beacon;

    if (self.onSuccess) {
        self.onSuccess();
    }
    
    switch (state) {
        case BLEActionStateForeground:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:BLEFacebookActionDidCheckIn object:self];
        }
            break;
        case BLEActionStateBackground:
        {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.soundName = UILocalNotificationDefaultSoundName;
            notification.alertAction = self.notificationTitle;
            notification.alertBody = self.notificationMessage ?: [NSString stringWithFormat:@"Checked in at %@",beacon.name];
            notification.fireDate  = nil;
            notification.alertLaunchImage = nil;
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        }
            break;
            
        default:
            break;
    }
}

/**
 *  Set up privacy opton for request
 *
 *  @param parameters Facebook request parameters
 */
- (void) setupPrivacy:(NSMutableDictionary *)parameters
{
    if (!self.privacy) {
          return;
    }
    
    NSString *value = @"ALL_FRIENDS"; // default is all friends
    
    if ([self.privacy isEqualToString:@"everyone"]) {
        value = @"EVERYONE";
    } else if ([self.privacy isEqualToString:@"friends"]) {
        value = @"ALL_FRIENDS";
    } else if ([self.privacy isEqualToString:@"friends of friends"]) {
        value = @"FRIENDS_OF_FRIENDS";
    } else if ([self.privacy isEqualToString:@"self"]) {
        value = @"SELF";
    }
    
    NSDictionary *privacyDictionary = @{@"value":value};
    NSData *privacyData = [NSJSONSerialization dataWithJSONObject:privacyDictionary options:0 error:nil];
    NSString *privacyStr = [[NSString alloc] initWithData:privacyData encoding:NSUTF8StringEncoding];
    
    [parameters addEntriesFromDictionary:@{@"privacy":privacyStr}];
}

/**
 *  Facebook Check-in request.
 *
 *  @param completion completion block
 */
- (void) checkIn:(void(^)(NSError *error))completion
{
    self->_bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"facebook-checkin-task" expirationHandler:nil];

    // do actual checkin
    void (^checkinBlock)(NSString *placeFBID) = ^(NSString *placeFBID) {
        FBRequest *req = [FBRequest requestForPostStatusUpdate: self.message ?: self.trigger.name place:placeFBID tags:nil];
        [self setupPrivacy:req.parameters];
        
        [req startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        completion([NSError errorWithDomain:BLEErrorDomain code:[FBErrorUtility errorCategoryForError:error] userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to post on facebook", nil), NSUnderlyingErrorKey: error}]);
                    } else {
                        completion(nil);
                    }
                });
            }
            
            if (self->_bgTask != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:self->_bgTask];
                self->_bgTask = UIBackgroundTaskInvalid;
            }
        }];
    };

    /**
     *  Search for place on facebook and cache result
     */
    if (!self.placeID && self.trigger.beacon.location) {
        BLETrigger *trigger = self.trigger;
        BLEBeacon  *beacon  = trigger.beacon;
        BLEZone    *zone    = beacon.zone;
        
        NSString *cacheKey = [NSString stringWithFormat:@"place%@",zone.name];
        SAMCache *cache = [[SAMCache alloc] initWithName:[NSString stringWithFormat:@"com.up-next.BLEKit.%@",[self class]]];
        // Check-in cache
        if ([cache objectExistsForKey:cacheKey]) {
            NSString *cachedPlaceId = [cache objectForKey:cacheKey];
            if (checkinBlock) {
                checkinBlock(cachedPlaceId);
            }
        } else {
            FBRequest *reqPlace = [FBRequest requestForPlacesSearchAtCoordinate:beacon.location.coordinate radiusInMeters:200 resultsLimit:1 searchText:zone.name];
            [reqPlace startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {

                if (error) {
                    checkinBlock(nil);
                }

                for (id <FBGraphObject> place in result[@"data"]) {
                    [cache setObject:[place[@"id"] description] forKey:cacheKey];
                    
                    if (checkinBlock) {
                        checkinBlock([place[@"id"] description]);
                    }
                }
            }];
        }
    } else if (checkinBlock) {
        checkinBlock(self.placeID);
    }
}

@end
