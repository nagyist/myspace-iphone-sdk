//
//  MSURLCoder.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/19/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSURLCoder : NSObject {
@private
}

- (NSString *)decodeURIComponent:(NSString *)value;
- (NSString *)encodeURIComponent:(NSString *)value;

@end
