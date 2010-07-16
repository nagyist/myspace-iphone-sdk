//
//  MSContext.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/16/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSContext.h"
#import "MSConstants.h"

@interface MSContext ()

- (void)_setAccessToken:(MSOAuthToken *)value action:(NSString *)action;

@end

@implementation MSContext

#define kMSContext_AccessTokenPrefix    @"USER"
#define kMSContext_AccessTokenProvider  @"MYSPACE"

#pragma mark -
#pragma mark Class Methods

static MSContext *_sharedContext = nil;

+ (void)initializeSharedContextWithConsumerKey:(NSString *)key
                                        secret:(NSString *)secret
                      authorizationCallbackURL:(NSString *)authorizationCallbackURL {
  @synchronized(self) {
    [_sharedContext release];
    _sharedContext = [[self alloc] initWithConsumerKey:key
                                                secret:secret
                              authorizationCallbackURL:authorizationCallbackURL];
  }
}

+ (void)resetSharedContext {
  @synchronized(self) {
    [_sharedContext release];
    _sharedContext = nil;
  }
}

+ (MSContext *)sharedContext {
  return _sharedContext;
}

#pragma mark -
#pragma mark Initialization

- (id)initWithConsumerKey:(NSString *)key
                   secret:(NSString *)secret
 authorizationCallbackURL:(NSString *)authorizationCallbackURL {
  if (self = [super init]) {
    _consumer = [[MSOAuthConsumer alloc] initWithKey:key secret:secret];
    _authorizationCallbackURL = [authorizationCallbackURL copy];
  }
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize authorizationCallbackURL=_authorizationCallbackURL;
@synthesize defaultViewController=_defaultViewController;

- (BOOL)isLoggedIn {
  return (nil != _accessToken);
}

#pragma mark -
#pragma mark Account Methods

- (void)login:(BOOL)animated {
  [self loginWithViewController:nil animated:animated];
}

- (void)loginWithViewController:(UIViewController *)viewController {
  [self loginWithViewController:viewController animated:YES];
}

- (void)loginWithViewController:(UIViewController *)viewController animated:(BOOL)animated {
  if (!viewController) {
    viewController = self.defaultViewController;
  }
  if (viewController && [[viewController view] superview]) {
    MSLoginViewController *loginViewController = [[[MSLoginViewController alloc] initWithContext:self
                                                                                        delegate:self] autorelease];
    if ([loginViewController respondsToSelector:@selector(setModalPresentationStyle:)]) {
      [loginViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    }
    [viewController presentModalViewController:loginViewController animated:animated];
  }
}

- (void)logout {
  [MSOAuthToken removeTokenFromUserDefaultsWithServiceProviderName:kMSContext_AccessTokenProvider
                                                            prefix:kMSContext_AccessTokenPrefix];
  [self _setAccessToken:nil action:MSContextLogoutAction];
}

- (BOOL)resume {
  if (!_accessToken) {
    MSOAuthToken *accessToken = [[MSOAuthToken alloc] initWithUserDefaultsUsingServiceProviderName:kMSContext_AccessTokenProvider
                                                                                            prefix:kMSContext_AccessTokenPrefix];
    [self _setAccessToken:accessToken action:(accessToken ? MSContextResumeAction : nil)];
  }
  return (nil != _accessToken);
}

#pragma mark -
#pragma mark MSLoginViewControllerDelegate Methods

- (void)loginViewController:(MSLoginViewController *)loginViewController didFailWithError:(NSError *)error {
  [loginViewController dismiss];
}

- (void)loginViewController:(MSLoginViewController *)loginViewController didLoginWithToken:(MSOAuthToken *)token {
  [loginViewController dismiss];
  [token storeInUserDefaultsWithServiceProviderName:kMSContext_AccessTokenProvider prefix:kMSContext_AccessTokenPrefix];
  [self _setAccessToken:token action:MSContextLoginAction];
}

- (void)loginViewControllerUserDidCancel:(MSLoginViewController *)loginViewController {
  [loginViewController dismiss];
}

#pragma mark -
#pragma mark Helper Methods

- (void)_setAccessToken:(MSOAuthToken *)value action:(NSString *)action {
  if (_accessToken != value) {
    [_accessToken release];
    _accessToken = [value retain];
    NSDictionary *userInfo = nil;
    if (action) {
      userInfo = [NSDictionary dictionaryWithObject:action forKey:MSContextActionKey];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MSContextDidChangeIsLoggedInNotification 
                                                        object:self
                                                      userInfo:userInfo];
  }
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [_accessToken release];
  [_authorizationCallbackURL release];
  [_consumer release];
  [_defaultViewController release];
  [super dealloc];
}

@end
