//
//  MSURLCoder.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/19/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSURLCoder.h"
#import "NSString+URLEncoding.h"

@implementation MSURLCoder

- (NSString *)decodeURIComponent:(NSString *)value {
  return [value URLDecodedString];
}

- (NSString *)encodeURIComponent:(NSString *)value {
  return [value URLEncodedString];
}

@end
