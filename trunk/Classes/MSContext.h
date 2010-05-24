//
//  MSContext.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/16/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSOAuthConsumer.h"
#import "MSOAuthToken.h"

@interface MSContext : NSObject {
@private
  MSOAuthToken *_accessToken;
  NSString *_authorizationCallbackURL;
  MSOAuthConsumer *_consumer;
}

+ (void)initializeSharedContextWithConsumerKey:(NSString *)key
                                        secret:(NSString *)secret
                      authorizationCallbackURL:(NSString *)authorizationCallbackURL;
+ (void)resetSharedContext;
+ (MSContext *)sharedContext;

- (id)initWithConsumerKey:(NSString *)key
                   secret:(NSString *)secret
 authorizationCallbackURL:(NSString *)authorizationCallbackURL;

@property (nonatomic, readonly) NSString *authorizationCallbackURL;
@property (nonatomic, readonly) BOOL isLoggedIn;

- (void)loginWithViewController:(UIViewController *)viewController;
- (void)loginWithViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)logout;
- (BOOL)resume;

@end
