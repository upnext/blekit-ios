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

//
//  Require application schema "fsoauth"
//  This need application setup that can't be done by blekit itself.
//
//  fsoauth://authorized
//
//	<key>CFBundleURLTypes</key>
//	<array>
//		<dict>
//			<key>CFBundleTypeRole</key>
//			<string>Editor</string>
//			<key>CFBundleURLName</key>
//			<string>com.up-next.WelcomeWithFacebookCheckin</string>
//			<key>CFBundleURLSchemes</key>
//			<array>
//				<string>fsoauth</string>
//			</array>
//		</dict>
//	</array>
//

#import "BLEAction.h"

#define FOURSQUARE_DEFAULT_CALLBACK_URL @"fsoauth://authorized"

/**
 *  Actions that handle Foursquare check-in. "foursquare-checkin" type.
 *
 *  Foursquare requires some additional settings. This requires manual application setup and can not be done by BLEKit itself.
 *
 *  Please specify url scheme "fsoauch" for client application:
 *
 *  @code
 *	<key>CFBundleURLTypes</key>
 *	<array>
 *		<dict>
 *			<key>CFBundleTypeRole</key>
 *			<string>Editor</string>
 *			<key>CFBundleURLName</key>
 *			<string>com.up-next.WelcomeWithFacebookCheckin</string>
 *			<key>CFBundleURLSchemes</key>
 *			<array>
 *				<string>fsoauth</string>
 *			</array>
 *		</dict>
 *	</array>
 *  @endcode
 *
 */
@interface BLEFoursquareAction : BLEAction

/**
 *  Foursquare identifier. The venue where the user is checking in.
 */
@property (strong) NSString *venueID;
/**
 *  A message about your check-in. The maximum length of this field is 140 characters.
 */
@property (strong) NSString *message;
/**
 *  Intended recipients of this broadcast. One of private,public,facebook,twitter,followers. If no valid value is found, the default is followers.
 */
@property (strong) NSString *broadcast;
/**
 *  Foursquare registered application Client ID
 */
@property (strong) NSString *client_id;
/**
 *  Foursquare registered application Client Secret
 */
@property (strong) NSString *secret_code;

/**
 *  Callback called on successfull check-in on Foursquare
 */
@property (nonatomic, copy) void (^onSuccess)(void);
/**
 *  Callback called on failure of check-in process
 */
@property (nonatomic, copy) void (^onFailure)(void);


/**
 *  Authorization helper
 *
 *  @param completion completion block.
 */
+ (void) login:(void(^)(NSError *error))completion;

@end
