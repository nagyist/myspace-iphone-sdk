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
  UIButton *_showActivityListButton;
  UIButton *_showCurrentStatusButton;
  UIButton *_showFriendListButton;
  UIButton *_showStatusListButton;
  UIButton *_uploadMediaButton;
  UINavigationController *_viewController;
  UIWindow *_window;
  UIView *_loginButtonContainer;
}

@property (nonatomic, retain) IBOutlet UIButton *loginButton;
@property (nonatomic, retain) IBOutlet UIButton *logoutButton;
@property (nonatomic, retain) IBOutlet UIButton *showActivityListButton;
@property (nonatomic, retain) IBOutlet UIButton *showCurrentStatusButton;
@property (nonatomic, retain) IBOutlet UIButton *showFriendListButton;
@property (nonatomic, retain) IBOutlet UIButton *showStatusListButton;
@property (nonatomic, retain) IBOutlet UIButton *uploadMediaButton;
@property (nonatomic, retain) IBOutlet UINavigationController *viewController;
@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UIView *loginButtonContainer;

- (IBAction)captureScreen;
- (IBAction)login;
- (IBAction)logout;
- (IBAction)showActivityList;
- (IBAction)showCurrentStatus;
- (IBAction)showFriendList;
- (IBAction)showStatusList;
- (IBAction)uploadMedia;

@end
