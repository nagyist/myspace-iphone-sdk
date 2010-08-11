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
  UIActivityIndicatorView *_activityIndicatorView;
  MSContext *_context;
  id<MSLoginViewControllerDelegate> _delegate;
  MSRequest *_request;
  MSOAuthToken *_requestToken;
  UIWebView *_webView;
}

- (id)initWithContext:(MSContext *)context delegate:(id<MSLoginViewControllerDelegate>)delegate;

@property (nonatomic, assign) id<MSLoginViewControllerDelegate> delegate;

- (void)cancel;
- (void)dismiss;

@end

@protocol MSLoginViewControllerDelegate <NSObject>

@optional

- (void)loginViewController:(MSLoginViewController *)loginViewController didFailWithError:(NSError *)error;
- (void)loginViewController:(MSLoginViewController *)loginViewController didLoginWithToken:(MSOAuthToken *)token;
- (void)loginViewControllerUserDidCancel:(MSLoginViewController *)loginViewController;

@end
