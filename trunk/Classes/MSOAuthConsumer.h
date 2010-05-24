//
//  MSOAuthConsumer.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/15/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSOAuthConsumer : NSObject {
@private
  id _implementation;
}

- (id)initWithKey:(NSString *)key secret:(NSString *)secret;

@property (nonatomic, readonly) id implementation;
@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *secret;

@end
