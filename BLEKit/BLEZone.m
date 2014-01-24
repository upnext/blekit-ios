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

#import "BLEZone.h"
#import "BLELocation.h"
#import "UNCodingUtil.h"
#import "UNMutableURLRequest.h"
#import "UNURLConnection.h"

#import "BLEKitPrivate.h"

@implementation BLEZone

- (instancetype) initWithIdentifier:(NSString *)identifier name:(NSString *)name timeToLife:(NSInteger)timeToLife
{
    if (self = [self init]) {
        self->_identifier = identifier;
        self->_name = name;
        self->_timeToLife = timeToLife;
    }
    return self;
}

- (instancetype) initWithJSON:(NSData *)jsonData error:(NSError * __autoreleasing *)error
{
    if (self = [self init]) {
        NSDictionary *zoneDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:error];
        if (!zoneDictionary) {
            return nil;
        }
        
        [self updatePropertiesFromDictionary:zoneDictionary];
    }
    return self;
}

- (instancetype) initWithJSONAtPath:(NSString *)jsonPath error:(NSError * __autoreleasing *)error
{
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath options:NSDataReadingUncached error:error];
    if (!jsonData) {
        return nil;
    }
    
    if (self = [self initWithJSON:jsonData error:error]) {
        // stuff
    }
    return self;
}

- (instancetype) initWithJSONAtURL:(NSURL *)url error:(NSError * __autoreleasing *)error
{
    NSData *jsonData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:error];
    if (!jsonData) {
        return nil;
    }
    
    if (self = [self initWithJSON:jsonData error:error]) {
        // stuff
    }
    return self;
}

+ (BLEZone *) zoneWithJSONAtURL:(NSURL *)url error:(NSError * __autoreleasing *)error
{
    return [[BLEZone alloc] initWithJSON:[NSData dataWithContentsOfURL:url] error:error];
}

+ (BLEZone *) zoneWithJSONAtPath:(NSString *)jsonPath error:(NSError * __autoreleasing *)error
{
    return [[BLEZone alloc] initWithJSONAtPath:jsonPath error:error];
}

+ (BLEZone *) zoneWithJSON:(NSData *)jsonData error:(NSError * __autoreleasing *)error
{
    BLEZone *zone = [[BLEZone alloc] initWithJSON:jsonData error:error];
    return zone;
}

- (NSString *)description
{
    return self.desc;
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"dealloc zone %@", self.identifier);
#endif
}

#pragma mark - BLEUpdatableFromDictionary

- (void) updatePropertiesFromDictionary:(NSDictionary *)dictionary
{
    self->_identifier = [dictionary[@"id"] description];
    self->_name = dictionary[@"name"];
    self->_timeToLife = [dictionary[@"ttl"] integerValue];
    self->_desc = dictionary[@"description"];
    
    if (dictionary[@"location"]) {
        BLELocation *location = [[BLELocation alloc] init];
        [location updatePropertiesFromDictionary:dictionary[@"location"]];
        self->_location = location;
    }
    
    if (dictionary[@"beacons"]) {
        NSArray *array = dictionary[@"beacons"];
        NSMutableSet *set = [NSMutableSet setWithCapacity:array.count];
        
        for (NSDictionary *beaconDictionary in array) {
            BLEBeacon *beacon = [[BLEBeacon alloc] initWithZone:self];
            [beacon updatePropertiesFromDictionary:beaconDictionary];
            [set addObject:beacon];
        }
        self.beacons = [set copy];
    }
}

#pragma mark - Remote

+ (void) fetchAsyncZoneFromURL:(NSURL *)zoneURL completion:(void(^)(BLEZone *zone, NSError *error))completion
{
    NSParameterAssert(zoneURL);

    __block BLEZone *zone = nil;
    UNMutableURLRequest *request = [[UNMutableURLRequest alloc] initWithGetURL:zoneURL parameters:nil];
    UNURLConnection *connection = [UNURLConnection connectionWithRequest:request completion:^(NSHTTPURLResponse *response, NSData *responseData, NSError *errorRequest) {
        if (errorRequest || responseData.length == 0) {
            if (completion) {
                completion(nil, errorRequest);
            }
            return;
        }
        
        NSError *error = nil;
        zone = [[self class] zoneWithJSON:responseData error:&error];
        if (completion) {
            completion(zone, error);
        }
    }];
    [connection start];
}

+ (BLEZone *) fetchZoneFromURL:(NSURL *)zoneURL
{
    NSParameterAssert(zoneURL);

    __block BLEZone *returnZone = nil;
    __block BOOL finished = NO;

    [BLEZone fetchAsyncZoneFromURL:zoneURL completion:^(BLEZone *zone, NSError *error) {
        returnZone = zone;
        finished = YES;
    }];

    while(!finished) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }

    return returnZone;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [self init]) {
        [UNCodingUtil decodeObject:self withCoder:aDecoder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [UNCodingUtil encodeObject:self withCoder:aCoder];
}

#pragma mark - UNCoding

- (instancetype) initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        [[[UNCodingUtil alloc] initWithObject:self] loadDictionaryRepresentation:dictionary];
    }
    return self;
}

- (NSDictionary *) dictionaryRepresentation
{
    return [[[UNCodingUtil alloc] initWithObject:self] dictionaryRepresentation];
}

@end
