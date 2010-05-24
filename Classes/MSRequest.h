//
//  MSRequest.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/16/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSContext.h"

@protocol MSRequestDelegate;

@interface MSRequest : NSObject {
@private
  NSURLConnection *_connection;
  MSContext *_context;
  id<MSRequestDelegate> _delegate;
  NSString *_method;
  NSData *_rawRequestData;
  NSMutableData *_rawResponseData;
  NSString *_requestContentType;
  NSDictionary *_requestData;
  NSString *_responseContentType;
  NSURL *_url;
  NSDictionary *_userInfo;
}

+ (NSString *)defaultContentType;

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
@property (nonatomic, readonly) NSString *method;
@property (nonatomic, readonly) NSString *requestContentType;
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
