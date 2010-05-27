//
//  MSOAuthMutableURLRequest.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/15/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSOAuthConsumer.h"
#import "MSOAuthToken.h"

@interface MSOAuthMutableURLRequest : NSMutableURLRequest {
@private
}

- (id)initWithURL:(NSURL *)url consumer:(MSOAuthConsumer *)consumer token:(MSOAuthToken *)token;

- (void)sign;

@end
