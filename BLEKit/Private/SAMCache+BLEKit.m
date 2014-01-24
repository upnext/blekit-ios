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

#import "SAMCache+BLEKit.h"

static SAMCache *ble_actionCache;
static SAMCache *ble_monitoredProximityCache;

@implementation SAMCache (BLEKit)

+ (SAMCache *) actionCache
{
    if (ble_actionCache != nil) {
        return ble_actionCache;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ble_actionCache = [[SAMCache alloc] initWithName:[NSString stringWithFormat:@"com.up-next.BLEKit.action"]];
    });
    
    return ble_actionCache;
}

+ (SAMCache *) monitoredProximityCache
{
    if (ble_monitoredProximityCache != nil) {
        return ble_monitoredProximityCache;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ble_monitoredProximityCache = [[SAMCache alloc] initWithName:[NSString stringWithFormat:@"com.up-next.BLEKit.monitored"]];
    });
    
    return ble_monitoredProximityCache;
}

//FIXME: this is rather ugly here, but convienient at the same time
- (void)incrementUsageNumberValueForAction:(id <BLEAction>)action
{
    __strong __typeof(action)actionStrong = action;
    __strong __typeof(actionStrong.trigger.beacon)beaconStrong = actionStrong.trigger.beacon;
    
    NSNumber *value = [self objectForKey:BLECacheActionIdentifierFormat(actionStrong, beaconStrong)];
    
    NSNumber *newValue = nil;
    // value == nil means 1 (first time occurrence)
    if (!value) {
        newValue = @(1);
    } else {
        newValue = @([value integerValue] + 1);
    }
    
    [self setObject:newValue forKey:BLECacheActionIdentifierFormat(actionStrong, beaconStrong)];
}

- (void)setObject:(id<NSCopying>)object forAction:(id <BLEAction>)action
{
    [self setObject:object forKey:BLECacheActionIdentifierFormat(action, action.trigger.beacon)];
}

@end
