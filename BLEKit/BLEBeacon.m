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

#import "BLEBeacon.h"
#import "BLEZone.h"
#import "BLELocation.h"
#import "BLETrigger.h"

#import "UNURLConnection.h"
#import "UNMutableURLRequest.h"

#import "BLEKitPrivate.h"
#import "CLBeacon+BLEKit.h"

#import "SAMCache+BLEKit.h"

#import "UNCodingUtil.h"

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

NSString * const BLEInvalidBeaconIdentifierException = @"BLEInvalidBeaconIdentifier";
NSString * const BLEBeaconTimerFireNotification = @"BLEBeaconTimerFireNotification";

@interface BLEBeacon ()
@property (strong) dispatch_source_t timer;
@property (assign) BOOL timerIsActive;
@end

@implementation BLEBeacon

@synthesize proximityUUID = _proximityUUID;
@synthesize major = _major;
@synthesize minor = _minor;
@synthesize accuracy = _accuracy;
@synthesize proximity = _proximity;
@synthesize rssi = _rssi;
@synthesize zone = _zone;

- (instancetype) init
{
    if (self = [super init]) {
        // remove only if period of time is significant
        SAMCache *staysCache = [[SAMCache alloc] initWithName:BLEBeaconStaysCacheName(self)];
        [staysCache removeAllObjects];
        
        [self scheduleStaysTimer];
    }
    return self;
}

- (instancetype) initWithZone:(BLEZone *)zone
{
    if (self = [self init]) {
        self.zone = zone;
    }
    return self;
}

- (instancetype) initWithZone:(BLEZone *)zone proximityUUID:(NSUUID *)proximityUUID major:(NSNumber *)major minor:(NSNumber *)minor
{
    if (self = [self initWithZone:zone]) {
        self.proximityUUID = proximityUUID;
        self.major = major;
        self.minor = minor;
    }
    return self;
}

- (NSString *)identifier
{
    return self.blekit_identifier;
}

- (BOOL)isEqual:(id)other
{
    if(![other isKindOfClass: [self class]])
        return YES;
    
    BOOL ret = NO;
    if ([other respondsToSelector:@selector(identifier)]) {
        ret = [[other identifier] isEqualToString:[self identifier]];
    }
    
    return ret;
}

- (NSUInteger)hash
{
    NSUInteger outHash = [_proximityUUID hash];
    outHash = NSUINTROTATE(outHash, NSUINT_BIT / 2) ^ [_major hash];
    outHash = NSUINTROTATE(outHash, NSUINT_BIT / 2) ^ [_minor hash];
    outHash = NSUINTROTATE(outHash, NSUINT_BIT / 2) ^ [_name hash];
    outHash = NSUINTROTATE(outHash, NSUINT_BIT / 2) ^ [_desc hash];
    return outHash;
}

- (NSString *) debugDescription
{
    return self.identifier;
}

- (NSTimeInterval) staysTimeInterval
{
    SAMCache *staysCache = [[SAMCache alloc] initWithName:BLEBeaconStaysCacheName(self)];
    NSDate *lastEnter = [staysCache objectForKey:self.identifier];
    if (lastEnter) {
        return [[NSDate date] timeIntervalSinceDate:lastEnter];
    }
    return 0;
}

- (void) scheduleStaysTimer
{
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    if (self.timer)
    {
        __weak typeof(self)selfWeak = self;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            __strong __typeof(self)selfStrong = selfWeak;
            if (self.timerIsActive) {
                dispatch_suspend(selfStrong.timer);
                selfStrong.timerIsActive = NO;
            }
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            __strong __typeof(self)selfStrong = selfWeak;
            if (!self.timerIsActive) {
                dispatch_resume(selfStrong.timer);
                selfStrong.timerIsActive = YES;
            }
        }];
        
        
        dispatch_source_set_timer(self.timer, dispatch_walltime(NULL, 0), 60 * NSEC_PER_SEC, 1 * NSEC_PER_SEC); // 1m, 1s
        dispatch_source_set_event_handler(self.timer, ^{
            __strong __typeof(self)selfStrong = selfWeak;
            @synchronized(selfStrong) {
#ifdef DEBUG
//                NSLog(@"%@ Time based event for beacon %@.", [self class], selfStrong);
#endif
                [[NSNotificationCenter defaultCenter] postNotificationName:BLEBeaconTimerFireNotification object:selfStrong];
            }
        });
        
        self.timerIsActive = YES;
        dispatch_resume(self.timer);
    }
}

#pragma mark - BLEUpdatableFromDictionary

- (void)updatePropertiesFromDictionary:(NSDictionary *)dictionary
{
    self->_desc = dictionary[@"description"];
    self->_name = dictionary[@"name"];
    self->_parameters = dictionary[@"parameters"];
    
    if (dictionary[@"zone"]) {
        BLEZone *zone = [[BLEZone alloc] init];
        [zone updatePropertiesFromDictionary:dictionary[@"zone"]];
        self.zone = zone;
    }
    
    BLELocation *location = [[BLELocation alloc] init];
    [location updatePropertiesFromDictionary:dictionary[@"location"]];
    self.location = location;
    
    if (dictionary[@"triggers"]) {
        NSArray *triggersArray = dictionary[@"triggers"];
        NSMutableSet *triggersSet = [NSMutableSet setWithCapacity:triggersArray.count];
        
        for (NSDictionary *triggerDictionary in triggersArray) {
            BLETrigger *trigger = [[BLETrigger alloc] initWithBeacon:self];
            [trigger updatePropertiesFromDictionary:triggerDictionary];
            [triggersSet addObject:trigger];
        }
        self.triggers = [triggersSet copy];
    }

    if (dictionary[@"id"]) {
        NSString *idString = [dictionary[@"id"] description];
        NSError *error = NULL;
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([\\w-]*)(\\+(\\d*)){0,1}(\\+(\\d*)){0,1}" options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&error];
        NSArray *matches =  [regex matchesInString:idString
                                           options:0
                                             range:NSMakeRange(0, [idString length])];
        
        NSTextCheckingResult *match = [matches objectAtIndex:0];
        for (int idx = 1; idx < match.numberOfRanges; idx++) {
            NSRange range = [match rangeAtIndex:idx];
            if (range.location != NSNotFound && idx == 1) {
                self.proximityUUID = [[NSUUID alloc] initWithUUIDString:[idString substringWithRange:range]];
            }

            if (range.location != NSNotFound && idx == 3) {
                self.major = @([[idString substringWithRange:range] integerValue]);
            }

            if (range.location != NSNotFound && idx == 5) {
                self.minor = @([[idString substringWithRange:range] integerValue]);
            }
        }
        
        if (!self.proximityUUID) {
            @throw [NSException exceptionWithName:BLEInvalidBeaconIdentifierException reason:[NSString stringWithFormat:@"Defined beacon identifier '%@' is invalid", idString] userInfo:dictionary];
        }
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    BLEBeacon *copy = [super copyWithZone:zone];
    copy.name = self.name;
    copy.desc = self.desc;
    copy.zone = self.zone;
    copy.location = self.location;
    copy.triggers = self.triggers;
    copy.onEnterCallback = self.onEnterCallback;
    copy.onExitCallback = self.onExitCallback;
    copy.parameters = [self.parameters copy];
    copy.onChangeProximityCallback = self.onChangeProximityCallback;
    copy.onPerformActionCallback = self.onPerformActionCallback;
    return copy;
}

#pragma mark - NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }
    [UNCodingUtil decodeObject:self withCoder:aDecoder];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [UNCodingUtil encodeObject:self withCoder:aCoder];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}


@end
