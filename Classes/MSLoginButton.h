//
//  MSLoginButton.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 7/13/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
  MSLoginButtonStyleBlue,
  MSLoginButtonStyleGray,
  MSLoginButtonStyleMixed,
} MSLoginButtonStyle;

typedef enum {
  MSLoginButtonSizeNormal,
  MSLoginButtonSizeWide,
} MSLoginButtonSize;

@interface MSLoginButton : UIControl {
@private
  BOOL _automaticallyOpenLoginView;
  MSLoginButtonSize _buttonSize;
  MSLoginButtonStyle _buttonStyle;
  UIImageView *_imageView;
}

@property (nonatomic) BOOL automaticallyOpenLoginView;
@property (nonatomic) MSLoginButtonSize buttonSize;
@property (nonatomic) MSLoginButtonStyle buttonStyle;
@property (nonatomic, readonly) UIImageView *imageView;

@end
