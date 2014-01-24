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

#import "BLECondition.h"
#import "BLEKitPrivate.h"
#import "UNCodingUtil.h"

#import "SAMCache+BLEKit.h"

static NSString * const BLEConditionTypeStays = @"stays";
static NSString * const BLEConditionStaysKey = @"stays";
static NSString * const BLEConditionStaysIntervalKey = @"interval";
static NSString * const BLEConditionOccurrenceKey = @"occurrence";

@interface BLECondition ()
@end

@implementation BLECondition

- (id)init
{
    if (self = [super init]) {
    }
    return self;
}

- (instancetype) initWithTrigger:(BLETrigger *)trigger
{
    if (self = [self init]) {
        self.trigger = trigger;
    }
    return self;
}

- (NSNumber *)occurrenceValue
{
    // calculate nthTime from persisent data for beacon action
//    NSCalendar *cal = [NSCalendar currentCalendar];
//    NSDate *date = [NSDate date];
//    NSDateComponents *comps = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
//    NSDate *today = [cal dateFromComponents:comps];
//    
//    NSDateComponents *components = [[NSDateComponents alloc] init];
//    [components setDay:-1];
//    
//    //TODO: support all units, yesterday is for testing purpose only
//    NSDate *yesterday = [cal dateByAddingComponents:components toDate:today options:0];
    
    __strong __typeof(self.trigger)triggerStrong = self.trigger;
    __strong __typeof(self.trigger.beacon)beaconStrong = triggerStrong.beacon;
    
    NSNumber *occurrence = [[SAMCache actionCache] objectForKey:BLECacheActionIdentifierFormat(triggerStrong.action, beaconStrong)];
    NSNumber *ret = occurrence ?: @(0);
    return ret;
}

/**
 *  Value for @c BLEConditionStaysKey
 *
 *  @return NSNumber
 */
- (NSNumber *)staysValue {
    NSNumber *value = @(self.trigger.beacon.staysTimeInterval);
    return value;
}

- (BOOL) validateForEventType:(BLEEventType)eventType
{
    BOOL ret = NO;
    
    if (!ret && self.type) {
        BLETrigger *trigger = self.trigger;
        BLEBeacon  *beacon  = trigger.beacon;
        
        if ([self.type isEqualToString:@"enter"] && eventType == BLEEventTypeEnter) {
            ret = YES;
        } else if ([self.type isEqualToString:@"leave"] && eventType == BLEEventTypeLeave) {
            ret = YES;
        } else if ([self.type isEqualToString:@"cameNear"] && eventType == BLEEventTypeRange && beacon.proximity == CLProximityNear) {
            ret = YES;
        } else if ([self.type isEqualToString:@"cameFar"] && eventType == BLEEventTypeRange && beacon.proximity == CLProximityFar) {
            ret = YES;
        } else if ([self.type isEqualToString:@"cameImmediate"] && eventType == BLEEventTypeRange && beacon.proximity == CLProximityImmediate) {
            ret = YES;
        } else if ([self.type isEqualToString:@"isNear"] && eventType == BLEEventTypeRange && beacon.proximity == CLProximityNear) {
            ret = YES;
        } else if ([self.type isEqualToString:@"isFar"] && eventType == BLEEventTypeRange && beacon.proximity == CLProximityFar) {
            ret = YES;
        } else if ([self.type isEqualToString:@"isImmediate"] && eventType == BLEEventTypeRange && beacon.proximity == CLProximityImmediate) {
            ret = YES;
        } else if ([self.type isEqualToString:BLEConditionTypeStays] && eventType == BLEEventTypeTimer) {
            ret = YES;
        }
    }

    //TODO: httpOk
    // NSLog(@"condition '%@' evalute to: %@, event type: %@.", self.type, ret ? @"true" : @"false", @(eventType));
    return ret;
}

- (BOOL) validateForParameters:(BOOL)withOccurrency
{
    BOOL ret = NO;
    
    if (self.expression) {
        ret = NO;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:self.expression];
        predicate = [predicate predicateWithSubstitutionVariables:@{@"isNear": @(CLProximityNear),
                                                                    @"isImmediate": @(CLProximityImmediate),
                                                                    @"isFar": @(CLProximityFar),
                                                                    @"cameNear": @(CLProximityNear),
                                                                    @"cameImmediate": @(CLProximityImmediate),
                                                                    @"cameFar": @(CLProximityFar),
                                                                    BLEConditionOccurrenceKey: [self occurrenceValue],
                                                                    BLEConditionStaysKey: [self staysValue]
                                                                    }];
        ret = [predicate evaluateWithObject:self];
    }
    
    if (!ret && self.parameters) {
        NSMutableArray *predicates = [[NSMutableArray alloc] initWithCapacity:1];

        /**
         *  Build "AND" predicate with parameters from json
         */

        NSDictionary *dict = self.parameters;
        for (NSString *key in [dict allKeys]) {
            
            if (!withOccurrency && [key isEqualToString:BLEConditionOccurrenceKey]) {
                // skip occurence
                continue;
            }
            
            id value = dict[key];
            NSPredicate *singlePredicate = nil;
            if ([self.type isEqualToString:BLEConditionTypeStays] && [key isEqualToString:BLEConditionStaysIntervalKey]) { //change it to more general configuration
                singlePredicate = [NSPredicate predicateWithFormat:@"%K >= %@",key, @([value integerValue])];
            } else {
                singlePredicate = [NSPredicate predicateWithFormat:@"%K = %@",key, value];
            }
            [predicates addObject:singlePredicate];
        }
        
        NSPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
        ret = [finalPredicate evaluateWithObject:self];
    }
    
    if (!ret && !self.parameters && !self.expression) {
        ret = YES;
    }
    
    return ret;
}

#pragma mark - NSKeyValueCoding

- (id)valueForUndefinedKey:(NSString *)key
{
    id ret = [self condition:self objectForParameter:key]; //self

    if (!ret) {
        @try {
            return [super valueForUndefinedKey:key];
        }
        @catch (NSException *exception) {
            /**
             *  nothing important, specified parameter key is invalid
             */
            NSLog(@"WARNING: %@",exception.reason);
        }
    }
    
    return ret;
}

- (id) valueForKeyPath:(NSString *)keyPath
{
    return [super valueForKeyPath:keyPath];
}

#pragma mark - BLEConditionDelegate

/**
 *  Object or value for condition.
 *
 *  if defined here then can be used in expression.
 *
 *  @param condition Condition object
 *  @param key       Condition key
 *
 *  @return Value object
 */
- (id) condition:(BLECondition *)condition objectForParameter:(NSString *)key
{
    BLETrigger *trigger = self.trigger;
    BLEBeacon  *beacon  = trigger.beacon;

    if ([key isEqualToString:@"zone"]) {
        return beacon.zone;
    } else if ([key isEqualToString:@"beacon"]) {
        return beacon;
    } else if ([key isEqualToString:@"action"]) {
        return trigger.action;
    } else if ([key isEqualToString:@"trigger"]) {
        return trigger;
    } else if ([key isEqualToString:@"distance"]) {
        return @(beacon.proximity);
    } else if ([key isEqualToString:BLEConditionOccurrenceKey]) {
        return [self occurrenceValue];
    } else if ([condition.type isEqualToString:BLEConditionTypeStays] && [key isEqualToString:BLEConditionStaysIntervalKey]) {
        return [self staysValue];
    }
    return nil;
}

#pragma mark - BLEUpdatableFromDictionary

- (void)updatePropertiesFromDictionary:(NSDictionary *)dictionary
{
    self->_type = dictionary[@"type"];
    self->_parameters = ![dictionary[@"parameters"] isKindOfClass:[NSNull class]] ? dictionary[@"parameters"] : nil;
    self->_expression = ![dictionary[@"expression"] isKindOfClass:[NSNull class]] ? dictionary[@"expression"] : nil;
}

#pragma mark - NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [UNCodingUtil decodeObject:self withCoder:aDecoder];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [UNCodingUtil encodeObject:self withCoder:aCoder];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}


@end
