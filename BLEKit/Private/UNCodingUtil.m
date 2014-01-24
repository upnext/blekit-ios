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

#import "UNCodingUtil.h"
#import <objc/runtime.h>

@implementation UNCodingUtil {
    __weak id object;
}

- (instancetype) initWithObject:(id <NSCoding>)obj
{
    if (self = [self init]) {
        object = obj;
    }
    return self;
}

- (NSSet *) allProperties
{
    unsigned int count = 0;
    // Get a list of all properties in the class.
    __strong __typeof(object)objectStrong = object;
    objc_property_t *properties = class_copyPropertyList([objectStrong class], &count);
    
    NSMutableSet *props = [[NSMutableSet alloc] initWithCapacity:count];

    NSError *error = NULL;
    NSRegularExpression *readOnlyRegex = [NSRegularExpression regularExpressionWithPattern:@"T.*,R,?" options:0 error:&error];
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(properties[i])];
        
        // Search for read only, regext may be the fastest here, but do the job
        NSUInteger numberOfMatches = [readOnlyRegex numberOfMatchesInString:attributes options:0 range:NSMakeRange(0, [attributes length])];
        BOOL isReadOnlyProperty = numberOfMatches > 0 ? YES : NO;
                
        //skip blocks, pointers and read-only attributes
        if (![attributes hasPrefix:@"T@?"] && ![attributes hasPrefix:@"T@^"] && !isReadOnlyProperty) {
            [props addObject:key];
        }
    }
    
    free(properties);
    return [props copy];
}

- (NSDictionary *)dictionaryRepresentation {
    NSSet *properties = [self allProperties];
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:properties.count];
    for (NSString *propertyName in properties) {
        id value = [object valueForKey:propertyName];

        if (value) {
            [dictionary setObject:value forKey:propertyName];
        }
    }
    return [dictionary copy];
}

- (void) loadDictionaryRepresentation:(NSDictionary *)dictionary;
{
    id objectStrong = object;
    UNCodingUtil *coder = [[UNCodingUtil alloc] initWithObject:objectStrong];
    NSDictionary *properties = [coder dictionaryRepresentation];
    for (NSString *propertyKey in [properties allKeys]) {
        
        if (dictionary[propertyKey]) {
            [objectStrong setValue:dictionary[propertyKey] forKey:propertyKey];
        }
    }
}

+ (void) encodeObject:(id <NSCoding>)object withCoder:(NSCoder *)encoder
{
    UNCodingUtil *c = [[UNCodingUtil alloc] initWithObject:object];
    [c encodePropertiesWithCoder:encoder];
}

+ (void) decodeObject:(id <NSCoding>)object withCoder:(NSCoder *)decoder
{
    UNCodingUtil *c = [[UNCodingUtil alloc] initWithObject:object];
    [c decodePropertiesWithCoder:decoder];
}


#pragma mark - Private

- (void) encodePropertiesWithCoder:(NSCoder *)encoder
{
    NSDictionary *dict = [self dictionaryRepresentation];
    NSSet *properties = [self allProperties];
    for (NSString *propertyKey in properties) {
        [encoder encodeObject:dict[propertyKey] forKey:propertyKey];
    }
}

- (void) decodePropertiesWithCoder:(NSCoder *)decoder
{
    NSSet *properties = [self allProperties];
    for (NSString *propertyKey in properties) {
        id value = [decoder decodeObjectForKey:propertyKey];
        if (value) {
            [object setValue:value forKey:propertyKey];
        }
    }
}

@end
