//
//  MySpaceSDKTesterAppDelegate.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/14/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MySpaceSDKTesterAppDelegate.h"
#import <MySpaceSDK/MySpaceSDK.h>
#import <QuartzCore/QuartzCore.h>
#import "FriendListViewController.h"
#import "StatusViewController.h"
#import "UploadMediaViewController.h"

@interface MySpaceSDKTesterAppDelegate ()

- (void)_msContextDidChangeIsLoggedInNotification:(NSNotification *)notification;
- (void)_msSDKDidFailNotification:(NSNotification *)notification;

@end

@implementation MySpaceSDKTesterAppDelegate

#pragma mark -
#pragma mark Properties

@synthesize loginButton=_loginButton;
@synthesize logoutButton=_logoutButton;
@synthesize showFriendsButton=_showFriendsButton;
@synthesize showStatusButton=_showStatusButton;
@synthesize uploadMediaButton=_uploadMediaButton;
@synthesize viewController=_viewController;
@synthesize window=_window;

#pragma mark -
#pragma mark Application Management

- (void)applicationDidFinishLaunching:(UIApplication *)application {
  // configure the SDK context with the details of your application
  // The following values are found in the application details page of the MySpace Developer Platform for
  // the app that you have configured.  If you have not yet created an app for your mobile application,
  // go to http://developer.myspace.com/Apps.mvc to create your app.
  //   consumerKey: OAuth Consumer Key
  //   secret: OAuth Consumer Secret (must click "Show OAuth Consumer Secret" to display)
  //   authorizationCallbackURL: External Callback Validation that you entered (must match)
  //
  // It is suggested that you serialize the OAuth configuration values into a byte array and then
  // pass them into the initialization method from the byte array.
  // ex:
  // const unicahr characters[] = {
  //   1,2,3,4,5,6,7,8,9,10,
  //   11,12,13,14,15,16,17,18,19,20,
  //   21,22,23,24,25,26,27,28,29,30,
  //   31,32,33,34,35,36,37,38,39,40,
  //   41,42,43,44,45,46,47,48,49,50,
  //   51,52,53,54,55,56,57,58,59,60,
  //   61,62,63,64,65,66,67,68,69,70,
  //   71,72,73,74,75,76,77,78,79,80,
  //   81,82,83,84,85,86,87,88,89,90,
  //   91,92,93,94,95,96
  // };
  // [MSContext initializaeSharedContextWithConsumerKey:[NSString stringWithCharacters:characters length:32]
  //                                             secret:[NSString stringWithCharacters:characters+32 length:64]
  //                           authorizationCallbackURL:EXTERNAL_CALLBACK_VALIDATION_HERE];
  //
  [MSContext initializeSharedContextWithConsumerKey:@"OAUTH_CONSUMER_KEY_HERE"
                                             secret:@"OAUTH_CONSUMER_SECRET_HERE"
                           authorizationCallbackURL:@"EXTERNAL_CALLBACK_VALIDATION_HERE"];
  MSSDK *sdk = [MSSDK sharedSDK];
  [sdk setUseLocation:YES];
  
  // listen for notifications from the SDK
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_msSDKDidFailNotification:)
                                               name:MSSDKDidFailNotification
                                             object:sdk];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_msContextDidChangeIsLoggedInNotification:)
                                               name:MSContextDidChangeIsLoggedInNotification
                                             object:[MSContext sharedContext]];
  
  // resume the context from a previously stored state
  [[MSContext sharedContext] resume];
  
  [self.window addSubview:[self.viewController view]];
  [self.window makeKeyAndVisible];
}

#pragma mark -
#pragma mark Actions

- (IBAction)captureScreen {
  CGRect bounds = [[UIScreen mainScreen] bounds];
  UIGraphicsBeginImageContext(bounds.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  [[UIColor blackColor] set];
  CGContextFillRect(context, bounds);
  [[[self.viewController view] layer] renderInContext:context];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
  UIGraphicsEndImageContext();
  UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil
                                                       message:@"Screen capture saved to photos album"
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil] autorelease];
  [alertView show];
}

- (IBAction)login {
  [[MSContext sharedContext] loginWithViewController:self.viewController animated:YES];
}

- (IBAction)logout {
  [[MSContext sharedContext] logout];
}

- (IBAction)showFriends {
  UIViewController *viewController = [[[FriendListViewController alloc] initWithNibName:nil bundle:nil] autorelease];
  [self.viewController pushViewController:viewController animated:YES];
}

- (IBAction)showStatus {
  UIViewController *viewController = [[[StatusViewController alloc] initWithNibName:nil bundle:nil] autorelease];
  [self.viewController pushViewController:viewController animated:YES];
}

- (IBAction)uploadMedia {
  UIViewController *viewController = [[[UploadMediaViewController alloc] initWithNibName:nil bundle:nil] autorelease];
  [self.viewController pushViewController:viewController animated:YES];
}

#pragma mark -
#pragma mark Notification Handler Methods

- (void)_msContextDidChangeIsLoggedInNotification:(NSNotification *)notification {
  if ([[MSContext sharedContext] isLoggedIn]) {
    [self.loginButton setEnabled:NO];
    [self.logoutButton setEnabled:YES];
    [self.showFriendsButton setEnabled:YES];
    [self.showStatusButton setEnabled:YES];
    [self.uploadMediaButton setEnabled:YES];
  } else {
    [self.loginButton setEnabled:YES];
    [self.logoutButton setEnabled:NO];
    [self.showFriendsButton setEnabled:NO];
    [self.showStatusButton setEnabled:NO];
    [self.uploadMediaButton setEnabled:NO];
    [self.viewController popToRootViewControllerAnimated:YES];
  }
}

- (void)_msSDKDidFailNotification:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                       message:[NSString stringWithFormat:@"Error executing request (%@): %@",
                                                                [userInfo valueForKeyPath:@"request.url"],
                                                                [userInfo objectForKey:@"error"]]
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil] autorelease];
  [alertView show];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [_loginButton release];
  [_logoutButton release];
  [_showFriendsButton release];
  [_showStatusButton release];
  [_uploadMediaButton release];
  [_viewController release];
  [_window release];
  [super dealloc];
}

@end
