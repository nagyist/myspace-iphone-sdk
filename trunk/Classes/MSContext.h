//
//  MSContext.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/16/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSLoginViewController.h"
#import "MSOAuthConsumer.h"
#import "MSOAuthToken.h"

typedef enum {
  MSLoginModeModal,
  MSLoginModeNavigation,
} MSLoginMode;

@interface MSContext : NSObject <MSLoginViewControllerDelegate> {
@private
  MSOAuthToken *_accessToken;
  NSString *_authorizationCallbackURL;
  MSOAuthConsumer *_consumer;
  UIViewController *_defaultViewController;
  MSLoginMode _loginMode;
  NSString *_permissions;
}

+ (void)initializeSharedContextWithConsumerKey:(NSString *)key
                                        secret:(NSString *)secret
                      authorizationCallbackURL:(NSString *)authorizationCallbackURL;
+ (void)resetSharedContext;
+ (MSContext *)sharedContext;

- (id)initWithConsumerKey:(NSString *)key
                   secret:(NSString *)secret
 authorizationCallbackURL:(NSString *)authorizationCallbackURL;

@property (nonatomic, retain) MSOAuthToken *accessToken;
@property (nonatomic, readonly) NSString *authorizationCallbackURL;
@property (nonatomic, readonly) MSOAuthConsumer *consumer;
@property (nonatomic, retain) UIViewController *defaultViewController;
@property (nonatomic, readonly) BOOL isLoggedIn;
@property (nonatomic) MSLoginMode loginMode;
@property (nonatomic, copy) NSString *permissions;

- (void)login:(BOOL)animated;
- (void)loginWithViewController:(UIViewController *)viewController;
- (void)loginWithViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)logout;
- (BOOL)resume;

@end
