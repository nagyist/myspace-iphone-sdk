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

+ (NSOperationQueue *)requestQueue;

@property (nonatomic, readonly) MSContext *context;
@property (nonatomic, assign) id<MSRequestDelegate> delegate;
@property (nonatomic, readonly) NSString *method;
@property (nonatomic, readonly) NSString *requestContentType;
@property (nonatomic, readonly) NSString *responseContentType;
@property (nonatomic, readonly) NSURL *url;

- (BOOL)connectionDidReceiveResponse:(NSURLResponse *)response;
- (void)connectionDidFinishLoading;
- (void)_decodeResponseDataInBackground:(NSData *)rawResponseData;
- (void)_didFailWithError:(NSError *)error;
- (void)_executeWithToken:(MSOAuthToken *)token;
- (void)_notifyDidFinishWithData:(NSDictionary *)responseData;
- (void)_releaseConnection;

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
        _requestQueue = [[NSOperationQueue alloc] init];
        [_requestQueue setMaxConcurrentOperationCount:2];
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
  }
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize context=_context;
@synthesize delegate=_delegate;
@synthesize isAnonymous=_isAnonymous;
@synthesize method=_method;
@synthesize requestContentType=_requestContentType;
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
  
  if (_delegateToMainThread) {
    [_requestOperation cancel];
    [_requestOperation release];
    _requestOperation = [[NSInvocationOperation alloc] initWithTarget:self
                                                             selector:@selector(_executeWithToken:)
                                                               object:token];
    [[[self class] requestQueue] addOperation:_requestOperation];
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
#pragma mark NSURLConnection Delegate Methods

- (BOOL)connectionDidReceiveResponse:(NSURLResponse *)response {
  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSError *error = nil;
    NSDictionary *userInfo = nil;
    NSInteger statusCode = [httpResponse statusCode];
    if ((200 <= statusCode) && (300 > statusCode)) {
      _responseContentType = [[[httpResponse allHeaderFields] objectForKey:@"Content-Type"] copy];
      return YES;
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

- (void)connectionDidFinishLoading {
  if (_delegateToMainThread && ![NSThread isMainThread]) {
    [self performSelectorOnMainThread:@selector(connectionDidFinishLoading) withObject:nil waitUntilDone:NO];
    return;
  }
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
  if (_delegateToMainThread && ![NSThread isMainThread]) {
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
    [self cancel];
    return;
  }
  
  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData *rawData = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
  
  if (error) {
    [self _didFailWithError:error];
    return;
  }
  
  if ([self connectionDidReceiveResponse:response]) {
    [_rawResponseData release];
    _rawResponseData = [rawData retain];
    [self connectionDidFinishLoading];
  }
}

- (void)_notifyDidFinishWithData:(NSDictionary *)responseData {
  if (_delegateToMainThread && ![NSThread isMainThread]) {
    [self performSelectorOnMainThread:@selector(_notifyDidFinishWithData:) withObject:responseData waitUntilDone:NO];
    return;
  }
  if ([self.delegate respondsToSelector:@selector(msRequest:didFinishWithData:)]) {
    [self.delegate msRequest:self didFinishWithData:responseData];
  }
}

#pragma mark -
#pragma mark Memory Management

- (void)_releaseConnection {
  [_requestOperation cancel];
  [_requestOperation release];
  _requestOperation = nil;
  
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
  [_requestOperation release];
  [_responseContentType release];
  [_url release];
  [_userInfo release];
  [super dealloc];
}

@end
