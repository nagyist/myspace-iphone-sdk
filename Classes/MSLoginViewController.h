//
//  MSLoginViewController.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/14/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSOAuthToken.h"
#import "MSRequest.h"

@class MSContext;

@protocol MSLoginViewControllerDelegate;

@interface MSLoginViewController : UIViewController <MSRequestDelegate, UIWebViewDelegate> {
@private
  NSUInteger _accessTokenCalls;
  UIActivityIndicatorView *_activityIndicatorView;
  UIButton *_closeButton;
  MSContext *_context;
  id<MSLoginViewControllerDelegate> _delegate;
  MSRequest *_request;
  MSOAuthToken *_requestToken;
  BOOL _showCloseButton;
  UIWebView *_webView;
}

- (id)initWithContext:(MSContext *)context delegate:(id<MSLoginViewControllerDelegate>)delegate;
- (id)initWithContext:(MSContext *)context
              nibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
             delegate:(id<MSLoginViewControllerDelegate>)delegate;

@property (nonatomic, readonly) MSContext *context;
@property (nonatomic, assign) id<MSLoginViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL showCloseButton;

- (void)cancel;
- (BOOL)dismiss;
- (void)msRequest:(MSRequest *)request didFailWithError:(NSError *)error;
- (void)msRequest:(MSRequest *)request didFinishWithRawData:(NSData *)data;

@end

@protocol MSLoginViewControllerDelegate <NSObject>

@optional

- (void)loginViewController:(MSLoginViewController *)loginViewController didFailWithError:(NSError *)error;
- (void)loginViewController:(MSLoginViewController *)loginViewController didLoginWithToken:(MSOAuthToken *)token;
- (void)loginViewControllerUserDidCancel:(MSLoginViewController *)loginViewController;

@end
