//
//  MySpaceSDKTesterAppDelegate.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/14/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MySpaceSDKTesterAppDelegate : NSObject <UIApplicationDelegate> {
@private
  UIButton *_loginButton;
  UIButton *_logoutButton;
  UIButton *_showFriendsButton;
  UIButton *_showStatusButton;
  UIButton *_uploadMediaButton;
  UINavigationController *_viewController;
  UIWindow *_window;
}

@property (nonatomic, retain) IBOutlet UIButton *loginButton;
@property (nonatomic, retain) IBOutlet UIButton *logoutButton;
@property (nonatomic, retain) IBOutlet UIButton *showFriendsButton;
@property (nonatomic, retain) IBOutlet UIButton *showStatusButton;
@property (nonatomic, retain) IBOutlet UIButton *uploadMediaButton;
@property (nonatomic, retain) IBOutlet UINavigationController *viewController;
@property (nonatomic, retain) IBOutlet UIWindow *window;

- (IBAction)captureScreen;
- (IBAction)login;
- (IBAction)logout;
- (IBAction)showFriends;
- (IBAction)showStatus;
- (IBAction)uploadMedia;

@end
