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

#import "BLEFoursquareAction.h"
#import "Foursquare2.h"

@implementation BLEFoursquareAction

- (instancetype)initWithUniqueIdentifier:(NSString *)uniqueIdentifier andTrigger:(BLETrigger *)trigger
{
    if (self = [super initWithUniqueIdentifier:uniqueIdentifier andTrigger:trigger]) {
        self.venueID = self.parameters[@"venue_id"] ?: self.venueID;
        self.message = self.parameters[@"message"] ?: self.message;
        self.client_id = self.parameters[@"client_id"] ?: self.client_id;
        self.secret_code = self.parameters[@"secret_code"] ?: self.secret_code;
        self.broadcast = self.parameters[@"broadcast"] ?: self.broadcast;

        NSParameterAssert(self.client_id);
        NSParameterAssert(self.secret_code);
        NSParameterAssert(self.venueID);
    }
    return self;
}

/**
 *  Do the actual check-in request
 */
- (void) checkInOnFoursquare
{
    FoursquareBroadcastType broadcast = broadcastFollowers;
    if ([self.broadcast isEqualToString:@"private"]) {
        broadcast = broadcastPrivate;
    } else if ([self.broadcast isEqualToString:@"public"]) {
        broadcast = broadcastPublic;
    } else if ([self.broadcast isEqualToString:@"followers"]) {
        broadcast = broadcastFollowers;
    } else if ([self.broadcast isEqualToString:@"followers"]) {
        broadcast = broadcastFollowers;
    } else if ([self.broadcast isEqualToString:@"twitter"]) {
        broadcast = broadcastTwitter;
    } else if ([self.broadcast isEqualToString:@"facebook"]) {
        broadcast = broadcastFacebook;
    }
        
    [Foursquare2 checkinAddAtVenue:self.venueID event:nil shout:self.message broadcast:broadcast latitude:nil longitude:nil accuracyLL:nil altitude:nil accuracyAlt:nil callback:^(BOOL success, id result) {
        if (success && self.onSuccess) {
            self.onSuccess();
        } else if (!success && self.onFailure) {
            self.onFailure();
        }
    }];
}

#pragma mark - BLEAction

- (void)performBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{    
    NSString *callbackURL = [NSString stringWithFormat:@"%@?%@=%@&%@=%@",FOURSQUARE_DEFAULT_CALLBACK_URL, BLEActionUniqueIdentifierKey, self.uniqueIdentifier, BLEActionEventTypeKey,  @(eventType)];
    [Foursquare2 setupFoursquareWithClientId:self.client_id  secret:self.secret_code callbackURL:callbackURL];
    if ([Foursquare2 isAuthorized]) {
        [self checkInOnFoursquare];
    } else {
        // authorize only in foreground
        if (state == BLEActionStateForeground) {
            [Foursquare2 authorizeWithCallback:^(BOOL success, id result) {
                if (success) {
                    [self checkInOnFoursquare];
                }
            }];
        }
    }
}

- (BOOL)canPerformBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    return [Foursquare2 isAuthorized];
}

- (BOOL)handleURL:(NSURL *)url sourceApplication:(id)sourceApplication annotation:(id)annotation
{
    return [Foursquare2 handleURL:url];
}

#pragma mark - Public

+ (void) login:(void(^)(NSError *error))completion
{
    [Foursquare2 authorizeWithCallback:^(BOOL success, id result) {
        if (completion) {
            completion((success == NO) ? [NSError errorWithDomain:BLEErrorDomain code:0 userInfo:nil] : nil);
        }
    }];
}


@end
