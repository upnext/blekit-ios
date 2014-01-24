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

#import "BLETrigger.h"

#import "BLEKitPrivate.h"
#import "UNCodingUtil.h"

@implementation BLETrigger

- (instancetype) initWithBeacon:(BLEBeacon *)blebeacon
{
    if (self = [self init]) {
        self.beacon = blebeacon;
    }
    return self;
}

#pragma mark - BLEUpdatableFromDictionary

- (void)updatePropertiesFromDictionary:(NSDictionary *)dictionary
{
    self->_uniqueIdentifier = [dictionary[@"id"] description];
    self->_comment = dictionary[@"comment"];
    self->_name = dictionary[@"name"];
    
    if (dictionary[@"action"]) {
        id <BLEAction> action = [[BLEAction alloc] initWithUniqueIdentifier:[dictionary[@"action"][@"id"] description] andTrigger:self];

        if ([action conformsToProtocol:@protocol(BLEAction)]) {
            /**
             *  Called on <BLEAction>, not on custom actions because <BLEUpdatableFromDictionary> is private here
             */
            [action performSelector:@selector(updatePropertiesFromDictionary:) withObject:dictionary[@"action"]];
        }

        self->_action = action;
    }

    if (dictionary[@"conditions"]) {
        NSArray *array = dictionary[@"conditions"];
        NSMutableSet *set = [NSMutableSet setWithCapacity:array.count];
        
        for (NSDictionary *conditionDictionary in array) {
            BLECondition *condition = [[BLECondition alloc] initWithTrigger:self];
            [condition updatePropertiesFromDictionary:conditionDictionary];
            [set addObject:condition];
        }
        self->_conditions = [set copy];
    }
}

- (BOOL) validateConditionsWithOccurrence:(BLEEventType)eventType
{
    for (BLECondition *condition in self.conditions) {
        if (![condition validateForEventType:eventType] || ![condition validateForParameters:YES])
            return NO;
    }
    return self.conditions.count > 0 ? YES : NO;
}

- (BOOL) validateConditionsWithoutOccurrency:(BLEEventType)eventType
{
    for (BLECondition *condition in self.conditions) {
        if (![condition validateForEventType:eventType] || ![condition validateForParameters:NO])
            return NO;
    }
    return self.conditions.count > 0 ? YES : NO;
}

- (BOOL) validateEventType:(BLEEventType)eventType
{
    for (BLECondition *condition in self.conditions) {
        if (![condition validateForEventType:eventType])
            return NO;
    }
    return self.conditions.count > 0 ? YES : NO;
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
