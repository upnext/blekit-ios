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

#import <UIKit/UIKit.h>

#import "BLEAction.h"
#import "BLEKitPrivate.h"
#import "UNCodingUtil.h"
#import "SAMCache+BLEKit.h"

@implementation BLEAction

- (instancetype) initWithUniqueIdentifier:(NSString *)uniqueIdentifier andTrigger:(BLETrigger *)trigger
{
    if (self = [self init]) {
        if (!uniqueIdentifier) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:[NSString stringWithFormat:@"You must specify unique identifier for class instance (%@)", [self class]]
                                         userInfo:nil];
        }
        
        self.trigger = trigger;
        self.uniqueIdentifier = [NSString stringWithFormat:@"%@", uniqueIdentifier];
        
        // and this come with json data
        self.type = trigger.action.type;
        self.parameters = trigger.action.parameters;
    }
    return self;
}

- (instancetype) initWithAction:(id <BLEAction>)action
{
    if (self = [self initWithUniqueIdentifier:action.uniqueIdentifier andTrigger:action.trigger]) {
    }
    return self;
}

#ifdef DEBUG
- (void)dealloc
{
    NSLog(@"dealloc %@",[self class]);
}
#endif

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

+ (BOOL)supportsSecureCoding
{
    return YES;
}

#pragma mark - BLEAction

- (void) performBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    // Default actions are defined in BLEKitDefaultDelegate
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (BOOL)canPerformBeaconAction:(BLETrigger *)trigger forState:(BLEActionState)state eventType:(BLEEventType)eventType
{
    return YES;
}

- (BOOL)handleURL:(NSURL *)url sourceApplication:(id)sourceApplication annotation:(id)annotation
{
    return NO;
}

#pragma mark - BLEUpdatableFromDictionary

- (void)updatePropertiesFromDictionary:(NSDictionary *)dictionary
{
    self->_uniqueIdentifier = [dictionary[@"id"] description];
    self->_type = dictionary[@"type"];
    self->_parameters = dictionary[@"parameters"];
}


@end
