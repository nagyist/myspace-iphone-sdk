//
//  MSJSONCoder.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/15/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSJSONCoder : NSObject {
@private
}

- (id)decodeJSON:(NSString *)json;
- (NSString *)encodeJSON:(id)object;

@end
