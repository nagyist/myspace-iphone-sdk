//
//  MSJSONCoder.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/15/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSJSONCoder.h"
#import "JSON.h"

@implementation MSJSONCoder

- (id)decodeJSON:(NSString *)json {
  return [json JSONValue];
}

- (NSString *)encodeJSON:(id)object {
  return [object JSONRepresentation];
}

@end
