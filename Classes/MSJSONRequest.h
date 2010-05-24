//
//  MSJSONRequest.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/21/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSJSONCoder.h"
#import "MSRequest.h"

@interface MSJSONRequest : MSRequest {
@private
  MSJSONCoder *_jsonCoder;
}

@property (nonatomic, readonly) MSJSONCoder *jsonCoder;

@end
