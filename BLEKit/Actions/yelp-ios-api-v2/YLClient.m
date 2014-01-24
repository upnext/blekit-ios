//
//  YLClient.m
//  yelp-ios-api-v2
//
//  Created by Fabian Canas on 6/13/13.
//  Copyright (c) 2013 Fabian Canas. All rights reserved.
//

#import "YLClient.h"
#import <AFNetworking/AFJSONRequestOperation.h>
#import <CommonCrypto/CommonCrypto.h>

#define BLE_YELP_KEY @"rW3SBSsrJ9hV33o_ukULPQ"
#define BLE_YELP_SECRET @"K3a5UFKm00mHaKMygzfj6wXvaEk"
#define BLE_YELP_TOKEN @"NbyZ6-eZTD-STR8UGCHhfrndn1wq05Dv"
#define BLE_YELP_TOKEN_SECRET @"D3RhYNFC-J9z95Qjj807cDXdxJw"

@implementation YLClient

static NSString *kYelpAPIURLString = @"http://api.yelp.com/v2";

- (instancetype)init
{
    return [self initWithBaseURL:[NSURL URLWithString:kYelpAPIURLString]];
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    NSString *configPathString = [[NSBundle bundleForClass:[self class]] pathForResource:@"YelpKeys" ofType:@"plist"];
    NSDictionary *keys = [[NSDictionary alloc] initWithContentsOfFile:configPathString];
    
    self = [super initWithBaseURL:url key:keys[@"key"] ?: BLE_YELP_KEY secret:keys[@"secret"] ?: BLE_YELP_SECRET];
    if (!self) {//BGZ8gI59MByMeTnOyYKFcg
        return nil;
    }
    self.accessToken = [[AFOAuth1Token alloc] initWithKey:keys[@"token"] ?: BLE_YELP_TOKEN
                                                   secret:keys[@"tokenSecret"] ?: BLE_YELP_TOKEN_SECRET
                                                  session:nil
                                               expiration:[NSDate distantFuture]
                                                renewable:NO];
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];    
    
    return self;
}


@end
