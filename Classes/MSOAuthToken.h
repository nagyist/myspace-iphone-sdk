//
//  MSOAuthToken.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/15/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSOAuthToken : NSObject {
@private
  id _implementation;
}

+ (void)removeTokenFromUserDefaultsWithServiceProviderName:(NSString *)provider prefix:(NSString *)prefix;

- (id)initWithUserDefaultsUsingServiceProviderName:(NSString *)provider prefix:(NSString *)prefix;
- (id)initWithHTTPResponseBody:(NSString *)body;
- (id)initWithKey:(NSString *)key secret:(NSString *)secret;

@property (nonatomic, readonly) id implementation;
@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *secret;

- (void)storeInUserDefaultsWithServiceProviderName:(NSString *)provider prefix:(NSString *)prefix;

@end
