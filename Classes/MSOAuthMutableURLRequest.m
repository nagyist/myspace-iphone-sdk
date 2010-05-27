//
//  MSOAuthMutableURLRequest.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/15/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSOAuthMutableURLRequest.h"
#import "OAuthConsumer.h"

@interface MSOAuthMutableURLRequest_Implementation : OAMutableURLRequest {
@private
}

- (id)initWithURL:(NSURL *)url consumer:(MSOAuthConsumer *)consumer token:(MSOAuthToken *)token;

- (void)sign;

@end

@implementation MSOAuthMutableURLRequest_Implementation

- (id)initWithURL:(NSURL *)url consumer:(MSOAuthConsumer *)aConsumer token:(MSOAuthToken *)aToken {
  self = [self initWithURL:url
                  consumer:(OAConsumer *)[aConsumer implementation]
                     token:(OAToken *)[aToken implementation]
                     realm:nil
         signatureProvider:nil];
  return self;
}

- (void)sign {
  [self prepare];
}

@end

@implementation MSOAuthMutableURLRequest

- (id)initWithURL:(NSURL *)url consumer:(MSOAuthConsumer *)aConsumer token:(MSOAuthToken *)aToken {
  [self release];
  self = nil;
  self = [[MSOAuthMutableURLRequest_Implementation alloc] initWithURL:url
                                                             consumer:aConsumer
                                                                token:aToken];
  return self;
}

- (void)sign {
}

@end
