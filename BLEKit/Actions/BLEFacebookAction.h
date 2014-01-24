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

#import "BLEAction.h"

#define BLEFacebookReadPermissionsArray @[@"basic_info"]
#define BLEFacebookPublishPermissionsArray @[@"publish_actions"]
#define BLEFacebookDefaultAudience FBSessionDefaultAudienceEveryone

static NSString * const BLEFacebookActionDidCheckIn = @"BLEFacebookActionDidCheckIn";

/**
 *  Actions that handle Facebook check-in, "facebook-checkin" type.
 */
@interface BLEFacebookAction : BLEAction <BLEAction>
/**
 *  Facebook place identifier (FBID)
 */
@property (strong) NSString *placeID;
/**
 *  Place name
 */
@property (strong) NSString *placeName;
/**
 *  Address for the place
 */
@property (strong) NSString *address;
/**
 *  Notification title.
 */
@property (strong) NSString *notificationTitle;
/**
 *  Notification message.
 */
@property (strong) NSString *notificationMessage;
/**
 *  Check-in message
 */
@property (strong) NSString *message;
/**
 *  Privacy for check-in post.
 */
@property (strong) NSString *privacy;

/**
 *  Callback called on successfull check-in on Facebook
 */
@property (nonatomic, copy) void (^onSuccess)(void);
/**
 *  Callback called on failure of check-in process
 */
@property (nonatomic, copy) void (^onFailure)(NSError *error);


/**
 *  Open facebook session. To be called from application:didFinishLaunchingWithOptions:
 *  @see application:didFinishLaunchingWithOptions:
 */
+ (void) openSession;
/**
 *  Helper to deal with facebook login and authentication flow.
 *
 *  @param completion completion block
 */
+ (void) login:(void(^)(id sess, NSError *error))completion;
/**
 *  Check if application is authorized.
 *
 *  @return YES if authorized.
 */
+ (BOOL) isAuthorized;

@end
