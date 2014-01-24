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

#import "UNURLConnection.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h> 

@interface UNURLConnection () <NSURLConnectionDataDelegate>
@property (strong) NSMutableData *responseData;
@property (strong) NSHTTPURLResponse *response;
@property (copy) UNURLConnectionCompletionBlock completion;
@end

#ifdef DEBUG
static BOOL UNVerbose = YES;
#else
static BOOL UNVerbose = NO;
#endif

@implementation UNURLConnection

/**
 Creates and initializes an `QRCURLConnection` object with the specified `NSURLRequest`.
 
 @param request request object
 @param completion finish called on finish.
 (NSData *responseData, NSError *errorRequest);
 */
- (instancetype) initWithRequest:(NSURLRequest *)request completion:(UNURLConnectionCompletionBlock)completion;
{
    if (self = [super initWithRequest:request delegate:self startImmediately:NO]) {
        if (completion) {
            self.completion = completion;
        }
        [self scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

+ (instancetype) connectionWithRequest:(NSURLRequest *)request completion:(UNURLConnectionCompletionBlock)completion
{
    return [[UNURLConnection alloc] initWithRequest:request completion:completion];
}


- (void)start {
    [[self pool] addObject:self];
    
    if ([[self class] isVerbose]) NSLog(@"Request %@",self.currentRequest.URL);

    [super start];
}

- (void)cancel {
    [[self pool] removeObject:self];
    [super cancel];
    //[self unscheduleFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [self updateNetworkActivity];
}

#pragma mark NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    // In debug mode you can disable SSL validation
    if (self.doNotValidateSSL) {
        NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
        NSURLCredential* credentail = [NSURLCredential credentialForTrust:[protectionSpace serverTrust]];
        if (challenge.previousFailureCount > 2) {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        } else {
            [[challenge sender] useCredential:credentail forAuthenticationChallenge:challenge];
        }
    } else if (([self.class pinnedCertificates].count > 0) && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        // SSL Pinning
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        
        CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
        NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:certificateCount];
        for (CFIndex i = 0; i < certificateCount; i++) {
            SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
            [trustChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
        }
        for (id serverCertificateData in trustChain) {
            if ([[self.class pinnedCertificates] containsObject:serverCertificateData]) {
                NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
                return;
            }
        }
        
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    } else {
        // Regular
        [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.responseData = [[NSMutableData alloc] init];
    self.response = (NSHTTPURLResponse *)response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (data) {
        [self.responseData appendData:data];
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([UNURLConnection isVerbose]) NSLog(@"Response %@: %@",@(self.response.statusCode), [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]);

    if (self.completion) {
        self.completion(self.response,self.responseData,nil);
    }
    
    [[self pool] removeObject:self];
    [self updateNetworkActivity];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    if ([UNURLConnection isVerbose]) NSLog(@"Response %@: %@",@(self.response.statusCode), error);

    if (self.completion) {
        self.completion(self.response, nil,error);
    }

    [[self pool] removeObject:self];
    [self updateNetworkActivity];
}

- (void) updateNetworkActivity
{
    if ([self pool].count == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    } else if ([self pool].count > 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

// working connections pool
static NSMutableSet *connectionPool = nil;

- (NSMutableSet *)pool
{
    return connectionPool;
}

#pragma mark Class Methods

static NSLock *generalLock = nil;
static NSArray *pinnedCertificatesArray = nil;

+ (void)initialize
{
    connectionPool = [NSMutableSet setWithCapacity:1];
    generalLock = [[NSLock alloc] init];
    pinnedCertificatesArray = [[NSArray alloc] init];
}

/**
 Whitelisted certificates. SSL Pinning.
 
 Aside of defined certificates this implementation look for .cer files in bundle and
 use it as pinned certificate.
 
 @param DERCertificate NSData with whitelisted certificate (DER encoded certificates)
 */
+ (void) addPinnedCertificate:(NSData *)DERCertificate
{
    [generalLock lock];
    pinnedCertificatesArray = [pinnedCertificatesArray arrayByAddingObject:[DERCertificate copy]];
    [generalLock unlock];
}

/** Whitelisted certificates, empty by default */
+ (NSArray *)pinnedCertificates
{
    return pinnedCertificatesArray;
}


+ (void) setVerbose:(BOOL)enable
{
    UNVerbose = enable;
}

+ (BOOL) isVerbose;
{
    return UNVerbose;
}


@end
