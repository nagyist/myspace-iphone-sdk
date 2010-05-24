//
//  MSOAuthConsumer.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/15/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSOAuthConsumer.h"
#import "OAuthConsumer.h"

@implementation MSOAuthConsumer

#pragma mark -
#pragma mark Initialization

- (id)initWithKey:(NSString *)key secret:(NSString *)secret {
  if (self = [super init]) {
    _implementation = [[OAConsumer alloc] initWithKey:key secret:secret];
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
  return [_implementation key];
}

- (NSString *)secret {
  return [_implementation secret];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [_implementation release];
  [super dealloc];
}

@end
