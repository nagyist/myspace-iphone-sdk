//
//  MSOAuthToken.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/15/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSOAuthToken.h"
#import "OAuthConsumer.h"

@implementation MSOAuthToken

#pragma mark -
#pragma mark Class Methods

+ (void)removeTokenFromUserDefaultsWithServiceProviderName:(NSString *)provider prefix:(NSString *)prefix {
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"OAUTH_%@_%@_KEY",
                                                             prefix,
                                                             provider]];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"OAUTH_%@_%@_SECRET",
                                                             prefix,
                                                             provider]];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark Initialization

- (id)initWithUserDefaultsUsingServiceProviderName:(NSString *)provider prefix:(NSString *)prefix {
  if (self = [super init]) {
    _implementation = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:provider prefix:prefix];
    if (!_implementation) {
      [self release];
      self = nil;
    }
  }
  return self;
}

- (id)initWithHTTPResponseBody:(NSString *)body {
  if (self = [super init]) {
    _implementation = [[OAToken alloc] initWithHTTPResponseBody:body];
    if (!_implementation) {
      [self release];
      self = nil;
    }
  }
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize implementation=_implementation;

- (NSString *)key {
  return [(OAToken *)_implementation key];
}

- (NSString *)secret {
  return [(OAToken *)_implementation secret];
}

#pragma mark -
#pragma mark Storage

- (void)storeInUserDefaultsWithServiceProviderName:(NSString *)provider prefix:(NSString *)prefix {
  [(OAToken *)_implementation storeInUserDefaultsWithServiceProviderName:provider prefix:prefix];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [_implementation release];
  [super dealloc];
}

@end
