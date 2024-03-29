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

@interface MSRequest ()

+ (NSOperationQueue *)requestQueue;

- (BOOL)_connectionDidReceiveResponse:(NSURLResponse *)response;
- (void)_connectionDidFinishLoading;
- (void)_decodeResponseData:(NSData *)rawResponseData;
- (void)_didFailWithError:(NSError *)error;
- (void)_executeWithToken:(MSOAuthToken *)token;
- (void)_notifyDidFinishWithData:(NSDictionary *)responseData;
- (void)_releaseConnection;
- (NSInvocationOperation *)_requestOperation;
- (BOOL)_shouldDelegateToMainThread;

@end

@implementation MSRequest

#pragma mark -
#pragma mark Class Methods

+ (NSString *)defaultContentType {
  return @"";
}

+ (NSInteger)maxConcurrentRequestCount {
  return [[self requestQueue] maxConcurrentOperationCount];
}

+ (void)setMaxConcurrentRequestCount:(NSInteger)value {
  [[self requestQueue] setMaxConcurrentOperationCount:value];
}

+ (NSOperationQueue *)requestQueue {
  static NSOperationQueue *_requestQueue = nil;
  if (!_requestQueue) {
    @synchronized(self) {
      if (!_requestQueue) {
        NSOperationQueue *requestQueue = [[NSOperationQueue alloc] init];
        [requestQueue setMaxConcurrentOperationCount:2];
        _requestQueue = requestQueue;
      }
    }
  }
  return _requestQueue;
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
  self = [self initWithContext:context
                           url:url
                        method:method
            requestContentType:nil
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
  if (requestContentType) {
    if (self = [super init]) {
      _context = [context retain];
      _url = [url retain];
      _method = [method copy];
      _requestContentType = [requestContentType copy];
      _requestData = [requestData retain];
      _rawRequestData = [rawRequestData retain];
      self.delegate = delegate;
    }
  } else {
    NSString *absoluteURL = [url absoluteString];
    Class klass = nil;
    if ((NSNotFound != [absoluteURL rangeOfString:kMSSDKAPIPrefix options:NSCaseInsensitiveSearch | NSAnchoredSearch].location) &&
        (NSNotFound == [absoluteURL rangeOfString:kMSSDKAPIJSONSuffix options:NSCaseInsensitiveSearch | NSAnchoredSearch | NSBackwardsSearch].location)) {
      klass = NSClassFromString(@"MSXMLRequest");
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
  }
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize context=_context;
@synthesize delegate=_delegate;
@synthesize isAnonymous=_isAnonymous;
@synthesize method=_method;
@synthesize priority=_priority;
@synthesize rawRequestData=_rawRequestData;
@synthesize rawResponseData=_rawResponseData;
@synthesize requestContentType=_requestContentType;
@synthesize requestData=_requestData;
@synthesize responseContentType=_responseContentType;
@synthesize url=_url;
@synthesize userInfo=_userInfo;

#pragma mark -
#pragma mark Request Management

- (void)cancel {
  [self _releaseConnection];
}

- (void)execute {
  [self executeWithToken:[self.context accessToken]];
}

- (void)executeWithToken:(MSOAuthToken *)token {
  _delegateToMainThread = [NSThread isMainThread];
  
  if ([self _shouldDelegateToMainThread]) {
    [[self _requestOperation] cancel];
    NSInvocationOperation *requestOperation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                                   selector:@selector(_executeWithToken:)
                                                                                     object:token];
    [requestOperation setQueuePriority:self.priority];
    [[[self class] requestQueue] addOperation:requestOperation];
    [requestOperation release];
  } else {
    [self _executeWithToken:token];
  }
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
#pragma mark Connection Delegate Methods

- (BOOL)_connectionDidReceiveResponse:(NSURLResponse *)response {
  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSError *error = nil;
    NSDictionary *userInfo = nil;
    NSInteger statusCode = [httpResponse statusCode];
    if ((200 <= statusCode) && (300 > statusCode)) {
      _responseContentType = [[[httpResponse allHeaderFields] objectForKey:@"Content-Type"] copy];
      return YES;
    } else if (401 == statusCode) {
      [self cancel];
      error = [NSError errorWithDomain:kMSSDKErrorDomain code:kMSSDKNotAuthorizedErrorCode userInfo:userInfo];
      [self _didFailWithError:error];      
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
  return NO;
}

- (void)_connectionDidFinishLoading {
  if ([self _shouldDelegateToMainThread] && ![NSThread isMainThread]) {
    [self performSelectorOnMainThread:@selector(_connectionDidFinishLoading) withObject:nil waitUntilDone:NO];
    return;
  }
  if ([self.delegate respondsToSelector:@selector(msRequest:didFinishWithRawData:)]) {
    [self.delegate msRequest:self didFinishWithRawData:self.rawResponseData];
  }
  if ([self.delegate respondsToSelector:@selector(msRequest:didFinishWithData:)]) {
    [self _decodeResponseData:self.rawResponseData];
  }
}

#pragma mark -
#pragma mark Helper Methods

- (void)_decodeResponseData:(NSData *)rawResponseData {
  NSDictionary *responseData = [self decodeResponseData:rawResponseData];
  [self _notifyDidFinishWithData:responseData];
}

- (void)_didFailWithError:(NSError *)error {
  [[self _requestOperation] cancel];
  if ([self _shouldDelegateToMainThread] && ![NSThread isMainThread]) {
    [self performSelectorOnMainThread:@selector(_didFailWithError:) withObject:error waitUntilDone:NO];
    return;
  }
  if ([self.delegate respondsToSelector:@selector(msRequest:didFailWithError:)]) {
    [self.delegate msRequest:self didFailWithError:error];
  }
}

- (void)_executeWithToken:(MSOAuthToken *)token {
  _isAnonymous = ![self.context isLoggedIn];
  MSOAuthMutableURLRequest *request = [[[MSOAuthMutableURLRequest alloc] initWithURL:self.url
                                                                            consumer:[self.context consumer]
                                                                               token:token] autorelease];
  [request setHTTPShouldHandleCookies:NO];
  if ([self.requestContentType length]) {
    [request setValue:self.requestContentType forHTTPHeaderField:@"Content-Type"];
  }
  if ([self.method length]) {
    [request setHTTPMethod:self.method];
  }
  
  NSData *rawRequestData = self.rawRequestData;
  
  if (!rawRequestData) {
    rawRequestData = [self encodeRequestData:self.requestData];
  }
  NSDictionary *requestHeaders = [self.userInfo objectForKey:@"requestHeaders"];
  if ([requestHeaders count]) {
    for (NSString *key in requestHeaders) {
      [request setValue:[requestHeaders objectForKey:key] forHTTPHeaderField:key];
    }
  }
  if ([rawRequestData length]) {
    [request setHTTPBody:rawRequestData];
  }
  [request sign];
  
  if ([self.delegate respondsToSelector:@selector(msRequestWillExecute:)] &&
      ![self.delegate msRequestWillExecute:self]) {
    [self cancel];
    return;
  }
  
  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData *rawData = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
  
  if (error) {
    if ([[error domain] isEqualToString:NSURLErrorDomain] && (NSURLErrorUserCancelledAuthentication == [error code])) {
      // this is an auth error
      error = [NSError errorWithDomain:kMSSDKErrorDomain code:kMSSDKNotAuthorizedErrorCode userInfo:nil];
    }
    [self _didFailWithError:error];
    return;
  }
  
  if ([self _connectionDidReceiveResponse:response]) {
    self.rawResponseData = rawData;
    [self _connectionDidFinishLoading];
  }
}

- (void)_notifyDidFinishWithData:(NSDictionary *)responseData {
  if ([self _shouldDelegateToMainThread] && ![NSThread isMainThread]) {
    [self performSelectorOnMainThread:@selector(_notifyDidFinishWithData:) withObject:responseData waitUntilDone:NO];
    return;
  }
  if ([self.delegate respondsToSelector:@selector(msRequest:didFinishWithData:)]) {
    [self.delegate msRequest:self didFinishWithData:responseData];
  }
}

- (NSInvocationOperation *)_requestOperation {
  NSInvocationOperation *requestOperation = nil;
  NSArray *operations = [[[[self class] requestQueue] operations] copy];
  for (NSOperation *operation in operations) {
    if ([operation isKindOfClass:[NSInvocationOperation class]] &&
        ([[(NSInvocationOperation *)operation invocation] target] == self)) {
      requestOperation = (NSInvocationOperation *)operation;
      break;
    }
  }
  [operations release];
  return requestOperation;
}

- (BOOL)_shouldDelegateToMainThread {
  return _delegateToMainThread;
}

#pragma mark -
#pragma mark Memory Management

- (void)_releaseConnection {
  [[self _requestOperation] cancel];
  
  [_rawResponseData release];
  _rawResponseData = nil;
}

- (void)dealloc {
  _delegate = nil;
  
  [self _releaseConnection];
  
  [_context release];
  [_method release];
  [_rawRequestData release];
  [_rawResponseData release];
  [_requestContentType release];
  [_requestData release];
  [_responseContentType release];
  [_url release];
  [_userInfo release];
  [super dealloc];
}

@end
