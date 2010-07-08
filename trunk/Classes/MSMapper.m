//
//  MSMapper.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 7/7/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSMapper.h"

@implementation MSMapper

#pragma mark -
#pragma mark Class Methods

+ (id)mapperWithType:(NSString *)type dictionary:(NSDictionary *)dictionary {
  return [[[self alloc] initWithType:type dictionary:dictionary] autorelease];
}

#pragma mark -
#pragma mark Initialization

- (id)initWithType:(NSString *)type {
  if (self = [super init]) {
    _type = [type copy];
  }
  return self;
}

- (id)initWithType:(NSString *)type dictionary:(NSDictionary *)dictionary {
  if (self = [self initWithType:type]) {
    self.objectArrayKey = [dictionary objectForKey:@"objectArrayKey"];
    self.objectAttributes = [dictionary objectForKey:@"objectAttributes"];
    self.userInfo = [dictionary objectForKey:@"userInfo"];
  }
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize objectArrayKey=_objectArrayKey;
@synthesize objectAttributes=_objectAttributes;
@synthesize type=_type;
@synthesize userInfo=_userInfo;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [_objectArrayKey release];
  [_objectAttributes release];
  [_type release];
  [_userInfo release];
  [super dealloc];
}

@end
