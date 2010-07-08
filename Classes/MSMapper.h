//
//  MSMapper.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 7/7/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSMapper : NSObject {
@private
  NSString *_objectArrayKey;
  NSDictionary *_objectAttributes;
  NSString *_type;
  NSDictionary *_userInfo;
}

+ (id)mapperWithType:(NSString *)type dictionary:(NSDictionary *)dictionary;

- (id)initWithType:(NSString *)type;
- (id)initWithType:(NSString *)type dictionary:(NSDictionary *)dictionary;

@property (nonatomic, copy) NSString *objectArrayKey;
@property (nonatomic, retain) NSDictionary *objectAttributes;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, retain) NSDictionary *userInfo;

@end
