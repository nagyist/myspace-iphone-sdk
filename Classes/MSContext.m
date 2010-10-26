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

@synthesize accessToken=_accessToken;
@synthesize authorizationCallbackURL=_authorizationCallbackURL;
@synthesize consumer=_consumer;
@synthesize defaultViewController=_defaultViewController;
@synthesize locale=_locale;
@synthesize loginMode=_loginMode;
@synthesize permissions=_permissions;
@synthesize userInfo=_userInfo;

- (BOOL)isLoggedIn {
  return (nil != self.accessToken);
}

- (NSString *)languageString {
  NSLocale *locale = self.locale;
  return [NSString stringWithFormat:@"%@-%@",
          [locale objectForKey:NSLocaleLanguageCode],
          [locale objectForKey:NSLocaleCountryCode]];
}

- (NSLocale *)locale {
  return (_locale ? _locale : [NSLocale currentLocale]);
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
    switch (self.loginMode) {
      case MSLoginModeNavigation:{
        [viewController.navigationController pushViewController:loginViewController animated:animated];
        break;
      }
      case MSLoginModeModal:
      default:{
#ifdef __IPHONE_3_2
        if ([loginViewController respondsToSelector:@selector(setModalPresentationStyle:)]) {
          [loginViewController setModalPresentationStyle:UIModalPresentationFormSheet];
        }
#endif
        [viewController presentModalViewController:loginViewController animated:animated];
        break;
      }
    }
  }
}

- (void)logout {
  [MSOAuthToken removeTokenFromUserDefaultsWithServiceProviderName:kMSContext_AccessTokenProvider
                                                            prefix:kMSContext_AccessTokenPrefix];
  [self _setAccessToken:nil action:MSContextLogoutAction];
}

- (BOOL)resume {
  if (!self.accessToken) {
    MSOAuthToken *accessToken = [[MSOAuthToken alloc] initWithUserDefaultsUsingServiceProviderName:kMSContext_AccessTokenProvider
                                                                                            prefix:kMSContext_AccessTokenPrefix];
    [self _setAccessToken:accessToken action:(accessToken ? MSContextResumeAction : nil)];
    [accessToken release];
  }
  return (nil != self.accessToken);
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
  NSDictionary *userInfo = [NSDictionary dictionaryWithObject:MSContextCancelKey forKey:MSContextActionKey];
  [[NSNotificationCenter defaultCenter] postNotificationName:MSContextDidCancelLoginNotification
                                                      object:self
                                                    userInfo:userInfo];
}

#pragma mark -
#pragma mark Helper Methods

- (void)_setAccessToken:(MSOAuthToken *)value action:(NSString *)action {
  if (self.accessToken != value) {
    self.accessToken = value;
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
  [_locale release];
  [_permissions release];
  [_userInfo release];
  [super dealloc];
}

@end
