//
//  MSJSONRequest.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/21/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSJSONRequest.h"
#import "MSConstants.h"

@implementation MSJSONRequest

#pragma mark -
#pragma mark Class Methods

+ (NSString *)defaultContentType {
  return kMSRequestJSONContentType;
}

#pragma mark -
#pragma mark Properties

- (MSJSONCoder *)jsonCoder {
  if (!_jsonCoder) {
    _jsonCoder = [[MSJSONCoder alloc] init];
  }
  return _jsonCoder;
}

#pragma mark -
#pragma mark Data Coding

- (NSDictionary *)decodeResponseData:(NSData *)data {
  NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  id temp = [self.jsonCoder decodeJSON:stringData];
  [stringData release];
  return ([temp isKindOfClass:[NSDictionary class]] ?
          (NSDictionary *)temp :
          [NSDictionary dictionaryWithObject:temp forKey:@"data"]);
}

- (NSData *)encodeRequestData:(NSDictionary *)data {
  return [[self.jsonCoder encodeJSON:data] dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [_jsonCoder release];
  [super dealloc];
}

@end
