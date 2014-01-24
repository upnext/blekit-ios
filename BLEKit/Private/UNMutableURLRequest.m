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

#import "UNMutableURLRequest.h"

@implementation UNMutableURLRequest

/**
 GET request with parameters
 @param theURL request URL
 @param parameters dictionary with parameters
 */
- (instancetype)initWithGetURL:(NSURL *)theURL parameters:(NSDictionary *)parameters
{
    return [self initWithURL:theURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60 parameters:parameters method:@"GET" parametersContentType:CCPParametersContentTypeURLEncoded];
}

/**
 POST multipart request
 @param theURL request URL
 @param parameters dictionary with parameters
 */
- (instancetype)initWithPostURL:(NSURL *)theURL parameters:(NSDictionary *)parameters
{
    return [self initWithURL:theURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60 parameters:parameters method:@"POST" parametersContentType:CCPParametersContentTypeMultipart];
}

/**
 PUT multipart request
 @param theURL request URL
 @param parameters dictionary with parameters
 */
- (instancetype)initWithPutURL:(NSURL *)theURL parameters:(NSDictionary *)parameters
{
    return [self initWithURL:theURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60 parameters:parameters method:@"PUT" parametersContentType:CCPParametersContentTypeMultipart];
}

/**
 DELETE request with parameters.
 @param theURL request URL
 @param parameters dictionary with parameters
 */
- (instancetype)initWithDeleteURL:(NSURL *)theURL parameters:(NSDictionary *)parameters
{
    return [self initWithURL:theURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60 parameters:parameters method:@"DELETE" parametersContentType:CCPParametersContentTypeURLEncoded];
}

/**
 Returns an initialized URL request with specified values. This is the designated initializer for CCPMutableURLRequest.
 
 @param theURL The URL for the request.
 @param cachePolicy The cache policy for the request.
 @param timeoutInterval The timeout interval for the request, in seconds.
 @param parameters dictionary with parameters
 @param method HTTP method, GET, POST, ...
 @param parametersContentType Content type for methods other than GET
 */
- (instancetype)initWithURL:(NSURL *)theURL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval parameters:(NSDictionary *)parameters method:(NSString *)method parametersContentType:(CCPParametersContentType)parametersContentType
{
    // build url
    NSData *encodedParameters = nil;
    NSURL *finalURL = theURL;
    
    if (parameters) {
        switch (parametersContentType) {
            case CCPParametersContentTypeMultipart:
                encodedParameters = [UNMutableURLRequest dictionaryToMultiPartForm:parameters withBoundary:@"0xKhTmLbOuNdArY"];
                break;
            default:
                encodedParameters = [[UNMutableURLRequest dictionaryToQueryString:parameters] dataUsingEncoding:NSUTF8StringEncoding];
                break;
        }
        if ([[method uppercaseString] isEqualToString:@"GET"] || [[method uppercaseString] isEqualToString:@"DELETE"]) {
            finalURL = [UNMutableURLRequest url:theURL byAppendingQueryString:[[NSString alloc] initWithData:encodedParameters encoding:NSUTF8StringEncoding]];
        }
    }
    
    self = [super initWithURL:finalURL cachePolicy:cachePolicy timeoutInterval:timeoutInterval];
    if (self) {
        self.HTTPMethod = method ?: @"GET";
        // set post, put
        if (![[method uppercaseString] isEqualToString:@"GET"] && ![[method uppercaseString] isEqualToString:@"DELETE"]) {
            self.HTTPMethod = method;
            self.HTTPBody = encodedParameters;
            [self setValue:[NSString stringWithFormat:@"%@", @(self.HTTPBody.length)] forHTTPHeaderField:@"Content-Length"];
            switch (parametersContentType) {
                case CCPParametersContentTypeMultipart:
                    [self setValue:[NSString stringWithFormat:@"multipart/form-data, boundary=%@",@"0xKhTmLbOuNdArY"] forHTTPHeaderField:@"Content-Type"];
                    break;
                default:
                    [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                    break;
            }
        }
    }
    return self;
}

- (NSURL *) appendQueryParameters:(NSDictionary *)parameters
{
    return [UNMutableURLRequest url:self.URL byAppendingQueryString:[UNMutableURLRequest dictionaryToQueryString:parameters]];
}

+ (NSString *) dictionaryToQueryString:(NSDictionary *)dict
{
    NSMutableArray *queryElements = [NSMutableArray arrayWithCapacity:1];
    for (id key in [dict allKeys]) {
        id val = dict[key];
        
        if ([val isKindOfClass:[NSNull class]]) {
            continue;
        }
        
        if ([val isKindOfClass:[NSNumber class]])
            [queryElements addObject:[NSString stringWithFormat:@"%@=%@",key,[[self class] percentEscapedQueryString:[val descriptionWithLocale: @{NSLocaleDecimalSeparator: @"."} ]]]];
        else
            [queryElements addObject:[NSString stringWithFormat:@"%@=%@",key,[[self class] percentEscapedQueryString:val]]];
    }
    return [queryElements componentsJoinedByString:@"&"];
}

#pragma mark - Private

+ (NSData *) dictionaryToMultiPartForm:(NSDictionary *)dict withBoundary:(NSString *)boundary
{
    NSMutableData *body = [NSMutableData data];
    for (id key in [dict allKeys]) {
        id val = dict[key];
        
        if ([val isKindOfClass:[NSNull class]]) {
            continue;
        }
        
        if ([val isKindOfClass:[NSString class]]) {
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[val dataUsingEncoding:NSUTF8StringEncoding]];
        }
        if ([val isKindOfClass:[NSNumber class]]) {
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[val stringValue] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        if ([val isKindOfClass:[NSData class]])  {
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"filename\"\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:val];
        }
    }
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return [body copy];
}

+ (NSURL *)url:(NSURL *)url byAppendingQueryString:(NSString *)queryString {
    if (![queryString length]) {
        return url;
    }
    
    NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@", [url absoluteString], [url query] ? @"&" : @"?", queryString];
    NSURL *theURL = [NSURL URLWithString:URLString];
    return theURL;
}

static NSString * const kAFCharactersToBeEscaped = @":/?&=;+!@#$()~',* ";
static NSString * const kAFCharactersToLeaveUnescaped = @"[].";

+ (NSString *)percentEscapedQueryString:(NSString *)string
{
    if (!string || [string isKindOfClass:[NSNull class]])
        return @"";
    
    NSStringEncoding encoding = NSUTF8StringEncoding;
    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kAFCharactersToLeaveUnescaped, (__bridge CFStringRef)kAFCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding));
}


@end
