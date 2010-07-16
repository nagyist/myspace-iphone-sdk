//
//  MSLoginButton.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 7/13/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSLoginButton.h"
#import "MSConstants.h"
#import "MSContext.h"

@interface MSLoginButton ()

- (void)initLoginButton;
- (void)msContextDidChangeIsLoggedInNotification:(NSNotification *)notification;
- (void)touchUpInsideHandler;
- (void)updateImage;

@end

@interface MSLoginButton (Internal)

@property (nonatomic, retain, readwrite) UIImageView *imageView;

@end

@implementation MSLoginButton (Internal)

- (UIImageView *)imageView {
  return _imageView;
}

- (void)setImageView:(UIImageView *)value {
  if (_imageView != value) {
    [_imageView release];
    _imageView = [value retain];
    [self updateImage];
  }
}

@end

@implementation MSLoginButton

#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self initLoginButton];
    if (CGRectIsEmpty(frame)) {
      [self sizeToFit];
    }
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
  if (self = [super initWithCoder:decoder]) {
    [self initLoginButton];
  }
  return self;
}

- (void)initLoginButton {
  self.automaticallyOpenLoginView = YES;
  
  [self setBackgroundColor:[UIColor clearColor]];
  
  UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
  [imageView setBackgroundColor:[UIColor clearColor]];
  [imageView setContentMode:UIViewContentModeCenter];
  [self addSubview:imageView];
  self.imageView = imageView;
  [imageView release];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(msContextDidChangeIsLoggedInNotification:)
                                               name:MSContextDidChangeIsLoggedInNotification
                                             object:[MSContext sharedContext]];
  
  [self addTarget:self action:@selector(touchUpInsideHandler) forControlEvents:UIControlEventTouchUpInside];
  
  [self updateImage];
}

#pragma mark -
#pragma mark Properties

@synthesize automaticallyOpenLoginView=_automaticallyOpenLoginView;
@synthesize buttonSize=_buttonSize;
@synthesize buttonStyle=_buttonStyle;
@synthesize imageView=_imageView;

- (void)setButtonSize:(MSLoginButtonSize)value {
  if (_buttonSize != value) {
    _buttonSize = value;
    [self updateImage];
  }
}

- (void)setButtonStyle:(MSLoginButtonStyle)value {
  if (_buttonStyle != value) {
    _buttonStyle = value;
    [self updateImage];
  }
}

#pragma mark -
#pragma mark UIView Methods

- (void)layoutSubviews {
  [super layoutSubviews];
  
  [self.imageView setFrame:self.bounds];
}

- (CGSize)sizeThatFits:(CGSize)size {
  return [[self.imageView image] size];
}

#pragma mark -
#pragma mark Helper Methods

- (void)msContextDidChangeIsLoggedInNotification:(NSNotification *)notification {
  [self updateImage];
}

- (void)touchUpInsideHandler {
  if (self.automaticallyOpenLoginView) {
    if ([[MSContext sharedContext] isLoggedIn]) {
      [[MSContext sharedContext] logout];
    } else {
      [[MSContext sharedContext] loginWithViewController:nil animated:YES];
    }
  }
}

- (void)updateImage {
  NSString *actionSuffix = @"_logout";
  if (![[MSContext sharedContext] isLoggedIn]) {
    actionSuffix = @"_login";
  }
  
  NSString *sizeSuffix = @"";
  switch (self.buttonSize) {
    case MSLoginButtonSizeWide:{
      sizeSuffix = @"_wide";
      break;
    }
  }
  
  NSString *styleSuffix = @"_blue";
  switch (self.buttonStyle) {
    case MSLoginButtonStyleGray:{
      styleSuffix = @"_gray";
      break;
    }
    case MSLoginButtonStyleMixed:{
      styleSuffix = @"_mixed";
      break;
    }
  }
  
  NSString *imageName = [NSString stringWithFormat:@"MySpaceSDK.bundle/MySpaceSDK%@%@%@.png",
                         actionSuffix,
                         sizeSuffix,
                         styleSuffix];
  UIImage *image = [UIImage imageNamed:imageName];
  [self.imageView setImage:image];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [_imageView release];
  [super dealloc];
}

@end
