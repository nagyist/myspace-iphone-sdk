//
//  MSOAuthMutableURLRequest.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/15/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSOAuthMutableURLRequest.h"

@implementation MSOAuthMutableURLRequest

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
