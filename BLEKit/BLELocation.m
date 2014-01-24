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

#import "BLELocation.h"

#import "BLEKitPrivate.h"
#import "UNCodingUtil.h"

@implementation BLELocation

#pragma mark - BLEUpdatableFromDictionary
- (void)updatePropertiesFromDictionary:(NSDictionary *)dictionary
{
    self.coordinate = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
}

#pragma mark - NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) {
        return nil;
    }

    /**
     * because of how CLLocationCoordinate2D is defined this must be encoded manually
     * ref: http://stackoverflow.com/questions/12291279/nskeyedarchiver-fails-with-cllocationcoordinate2d-structs-why
     */
    CLLocationDegrees latitude = (CLLocationDegrees)[(NSNumber*)[aDecoder decodeObjectForKey:@"latitude"] doubleValue];
    CLLocationDegrees longitude = (CLLocationDegrees)[(NSNumber*)[aDecoder decodeObjectForKey:@"longitude"] doubleValue];
    self->_coordinate = (CLLocationCoordinate2D) { latitude, longitude };
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    NSNumber *latitude = [NSNumber numberWithDouble:self.coordinate.latitude];
    NSNumber *longitude = [NSNumber numberWithDouble:self.coordinate.longitude];
    [aCoder encodeObject:latitude forKey:@"latitude"];
    [aCoder encodeObject:longitude forKey:@"longitude"];}

+ (BOOL)supportsSecureCoding
{
    return YES;
}


@end
