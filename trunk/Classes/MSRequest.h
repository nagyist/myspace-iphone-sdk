//
//  MSRequest.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/16/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MSContext;
@class MSOAuthToken;

@protocol MSRequestDelegate;

@interface MSRequest : NSObject {
@private
  MSContext *_context;
  id<MSRequestDelegate> _delegate;
  BOOL _delegateToMainThread;
  BOOL _isAnonymous;
  NSString *_method;
  NSOperationQueuePriority _priority;
  NSData *_rawRequestData;
  NSData *_rawResponseData;
  NSString *_requestContentType;
  NSDictionary *_requestData;
  NSString *_responseContentType;
  NSURL *_url;
  NSDictionary *_userInfo;
}

+ (NSString *)defaultContentType;
+ (NSInteger)maxConcurrentRequestCount;
+ (void)setMaxConcurrentRequestCount:(NSInteger)value;

+ (MSRequest *)msRequestWithContext:(MSContext *)context
                                url:(NSURL *)url
                             method:(NSString *)method
                        requestData:(NSDictionary *)requestData
                     rawRequestData:(NSData *)rawRequestData
                           delegate:(id<MSRequestDelegate>)delegate;

- (id)initWithContext:(MSContext *)context
                  url:(NSURL *)url
               method:(NSString *)method
          requestData:(NSDictionary *)requestData
       rawRequestData:(NSData *)rawRequestData
             delegate:(id<MSRequestDelegate>)delegate;

- (id)initWithContext:(MSContext *)context
                  url:(NSURL *)url
               method:(NSString *)method
   requestContentType:(NSString *)requestContentType
          requestData:(NSDictionary *)requestData
       rawRequestData:(NSData *)rawRequestData
             delegate:(id<MSRequestDelegate>)delegate;

@property (nonatomic, readonly) MSContext *context;
@property (nonatomic, assign) id<MSRequestDelegate> delegate;
@property (nonatomic, readonly) BOOL isAnonymous;
@property (nonatomic, readonly) NSString *method;
@property (nonatomic) NSOperationQueuePriority priority;
@property (nonatomic, readonly) NSData *rawRequestData;
@property (nonatomic, retain) NSData *rawResponseData;
@property (nonatomic, readonly) NSString *requestContentType;
@property (nonatomic, readonly) NSDictionary *requestData;
@property (nonatomic, readonly) NSString *responseContentType;
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, retain) NSDictionary *userInfo;

- (void)cancel;
- (NSDictionary *)decodeResponseData:(NSData *)data;
- (NSData *)encodeRequestData:(NSDictionary *)data;
- (void)execute;
- (void)executeWithToken:(MSOAuthToken *)token;

@end

@protocol MSRequestDelegate <NSObject>

@optional

- (void)msRequest:(MSRequest *)request didFailWithError:(NSError *)error;
- (void)msRequest:(MSRequest *)request didFinishWithData:(NSDictionary *)data;
- (void)msRequest:(MSRequest *)request didFinishWithRawData:(NSData *)data;
- (BOOL)msRequestWillExecute:(MSRequest *)request;

@end
