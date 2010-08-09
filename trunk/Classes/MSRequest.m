//
//  MSRequest.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/16/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSRequest.h"
#import "MSConstants.h"
#import "MSContext.h"
#import "MSJSONRequest.h"
#import "MSOAuthMutableURLRequest.h"
#import "MSOAuthToken.h"

@interface MSContext (MSRequest)

- (MSOAuthToken *)accessToken;
- (MSOAuthConsumer *)consumer;

@end

@implementation MSContext (MSRequest)

- (MSOAuthToken *)accessToken {
  return _accessToken;
}

- (MSOAuthConsumer *)consumer {
  return _consumer;
}

@end

@interface MSRequest ()

- (void)_decodeResponseDataInBackground:(NSData *)rawResponseData;
- (void)_didFailWithError:(NSError *)error;
- (void)_notifyDidFinishWithData:(NSDictionary *)responseData;
- (void)_releaseConnection;

@end

@implementation MSRequest

#pragma mark -
#pragma mark Class Methods

+ (NSString *)defaultContentType {
  return nil;
}

+ (MSRequest *)msRequestWithContext:(MSContext *)context
                                url:(NSURL *)url
                             method:(NSString *)method
                        requestData:(NSDictionary *)requestData
                     rawRequestData:(NSData *)rawRequestData
                           delegate:(id<MSRequestDelegate>)delegate {
  return [[[MSRequest alloc] initWithContext:context
                                         url:url
                                      method:method
                                 requestData:requestData
                              rawRequestData:rawRequestData
                                    delegate:delegate] autorelease];
}

#pragma mark -
#pragma mark Initialization

- (id)initWithContext:(MSContext *)context
                  url:(NSURL *)url
               method:(NSString *)method
          requestData:(NSDictionary *)requestData
       rawRequestData:(NSData *)rawRequestData
             delegate:(id<MSRequestDelegate>)delegate {
  NSString *absoluteURL = [url absoluteString];
  Class klass = nil;
  if ((NSNotFound != [absoluteURL rangeOfString:kMSSDKAPIPrefix options:NSCaseInsensitiveSearch | NSAnchoredSearch].location) &&
      (NSNotFound == [absoluteURL rangeOfString:kMSSDKAPIJSONSuffix options:NSCaseInsensitiveSearch | NSAnchoredSearch | NSBackwardsSearch].location)) {
    klass = objc_getClass("MSXMLRequest");
  } else {
    klass = [MSJSONRequest class];
  }
  if (klass && ![self isKindOfClass:klass]) {
    [self release];
    self = nil;
    self = [klass alloc];
  }
  self = [self initWithContext:context
                           url:url
                        method:method
            requestContentType:[klass defaultContentType]
                   requestData:requestData
                rawRequestData:rawRequestData
                      delegate:delegate];
  return self;
}

- (id)initWithContext:(MSContext *)context
                  url:(NSURL *)url
               method:(NSString *)method
   requestContentType:(NSString *)requestContentType
          requestData:(NSDictionary *)requestData
       rawRequestData:(NSData *)rawRequestData
             delegate:(id<MSRequestDelegate>)delegate {
  if (self = [super init]) {
    _context = [context retain];
    _url = [url retain];
    _method = [method copy];
    _requestContentType = [requestContentType copy];
    _requestData = [requestData retain];
    _rawRequestData = [rawRequestData retain];
    self.delegate = delegate;
  }
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize context=_context;
@synthesize delegate=_delegate;
@synthesize method=_method;
@synthesize requestContentType=_requestContentType;
@synthesize responseContentType=_responseContentType;
@synthesize url=_url;
@synthesize userInfo=_userInfo;

#pragma mark -
#pragma mark Connection Management

- (void)cancel {
  [self _releaseConnection];
}

- (void)execute {
  [self executeWithToken:[self.context accessToken]];
}

- (void)executeWithToken:(MSOAuthToken *)token {
  [self _releaseConnection];
  MSOAuthMutableURLRequest *request = [[[MSOAuthMutableURLRequest alloc] initWithURL:self.url
                                                                            consumer:[self.context consumer]
                                                                               token:token] autorelease];
  if ([self.requestContentType length]) {
    [request setValue:self.requestContentType forHTTPHeaderField:@"Content-Type"];
  }
  if ([self.method length]) {
    [request setHTTPMethod:self.method];
  }
  if (!_rawRequestData) {
    _rawRequestData = [[self encodeRequestData:_requestData] retain];
    [_requestData release];
    _requestData = nil;
  }
  if ([_rawRequestData length]) {
    [request setHTTPBody:_rawRequestData];
  }
  [request sign];
  
  if ([self.delegate respondsToSelector:@selector(msRequestWillExecute:)] &&
      ![self.delegate msRequestWillExecute:self]) {
    return;
  }
  
  _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

#pragma mark -
#pragma mark Data Coding

- (NSDictionary *)decodeResponseData:(NSData *)data {
  return nil;
}

- (NSData *)encodeRequestData:(NSDictionary *)data {
  return nil;
}

#pragma mark -
#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  [self _didFailWithError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSError *error = nil;
    NSDictionary *userInfo = nil;
    NSInteger statusCode = [httpResponse statusCode];
    if ((200 <= statusCode) && (300 > statusCode)) {
      _responseContentType = [[[httpResponse allHeaderFields] objectForKey:@"Content-Type"] copy];
      [_rawResponseData release];
      _rawResponseData = [[NSMutableData alloc] init];
    } else if (409 == statusCode) {
      [self cancel];
      error = [NSError errorWithDomain:kMSSDKErrorDomain code:kMSSDKOpenSocialErrorCode userInfo:userInfo];
      [self _didFailWithError:error];
    } else {
      [self cancel];
      NSString *description = [[httpResponse allHeaderFields] objectForKey:@"X-Opensocial-Error"];
      if ([description length]) {
        userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
      }
      error = [NSError errorWithDomain:kMSSDKErrorDomain
                                  code:kMSSDKOpenSocialErrorCode
                              userInfo:userInfo];
      [self _didFailWithError:error];
    }
  }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [_rawResponseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  if ([self.delegate respondsToSelector:@selector(msRequest:didFinishWithRawData:)]) {
    [self.delegate msRequest:self didFinishWithRawData:_rawResponseData];
  }
  if ([self.delegate respondsToSelector:@selector(msRequest:didFinishWithData:)]) {
    [self performSelectorInBackground:@selector(_decodeResponseDataInBackground:) withObject:_rawResponseData];
  }
}

#pragma mark -
#pragma mark Helper Methods

- (void)_decodeResponseDataInBackground:(NSData *)rawResponseData {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSDictionary *responseData = [self decodeResponseData:rawResponseData];
  [self performSelectorOnMainThread:@selector(_notifyDidFinishWithData:) withObject:responseData waitUntilDone:NO];
  [pool drain];
}

- (void)_didFailWithError:(NSError *)error {
  if ([self.delegate respondsToSelector:@selector(msRequest:didFailWithError:)]) {
    [self.delegate msRequest:self didFailWithError:error];
  }
}

- (void)_notifyDidFinishWithData:(NSDictionary *)responseData {
  if ([self.delegate respondsToSelector:@selector(msRequest:didFinishWithData:)]) {
    [self.delegate msRequest:self didFinishWithData:responseData];
  }
}

#pragma mark -
#pragma mark Memory Management

- (void)_releaseConnection {
  [_connection cancel];
  [_connection release];
  _connection = nil;
  
  [_rawResponseData release];
  _rawResponseData = nil;
}

- (void)dealloc {
  _delegate = nil;
  
  [self _releaseConnection];
  
  [_context release];
  [_method release];
  [_rawRequestData release];
  [_requestContentType release];
  [_requestData release];
  [_responseContentType release];
  [_url release];
  [_userInfo release];
  [super dealloc];
}

@end
