//
//  MSLoginViewController.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/14/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSLoginViewController.h"
#import "MSConstants.h"
#import "MSContext.h"
#import "MSURLCoder.h"

@interface MSLoginViewController ()

- (void)addLoadingView;
- (void)getAccessToken;
- (void)getRequestToken;

@end

@implementation MSLoginViewController

#define kCloseButtonSize  44.0

#pragma mark -
#pragma mark Initialization

- (id)initWithContext:(MSContext *)context delegate:(id<MSLoginViewControllerDelegate>)delegate {
  self = [self initWithContext:context nibName:nil bundle:nil delegate:delegate];
  return self;
}

- (id)initWithContext:(MSContext *)context
              nibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
             delegate:(id<MSLoginViewControllerDelegate>)delegate {
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    _context = (context ? [context retain] : [[MSContext sharedContext] retain]);
    self.delegate = delegate;
    self.showCloseButton = YES;
  }
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [self initWithContext:nil delegate:nil];
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize context=_context;
@synthesize delegate=_delegate;
@synthesize showCloseButton=_showCloseButton;

- (void)setShowCloseButton:(BOOL)value {
  _showCloseButton = value;
  [_closeButton setHidden:!value];
}

#pragma mark -
#pragma mark View Management

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [self getRequestToken];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  if (!_closeButton) {
    _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - kCloseButtonSize,
                                                              0.0,
                                                              kCloseButtonSize,
                                                              kCloseButtonSize)];
    [_closeButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [_closeButton setBackgroundImage:[UIImage imageNamed:@"flickr-close.png"] forState:UIControlStateNormal];
    [_closeButton setOpaque:NO];
    [_closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
  }
  [self.view addSubview:_closeButton];
  self.showCloseButton = self.showCloseButton;
  
  [self addLoadingView];
}

#pragma mark -
#pragma mark Actions

- (void)cancel {
  [_request cancel];
  [_request release];
  _request = nil;
  
  [_requestToken release];
  _requestToken = nil;
}

- (BOOL)dismiss {
  BOOL dismissed = NO;
  [self cancel];
  UIViewController *parentViewController = self.presentingViewController;
  if ([parentViewController modalViewController] == self) {
    [parentViewController dismissModalViewControllerAnimated:YES];
    dismissed = YES;
  } else if (self.navigationController && ([self.navigationController topViewController] == self)) {
    [self.navigationController popViewControllerAnimated:YES];
    dismissed = YES;
  }
  return dismissed;
}

#pragma mark -
#pragma mark MSRequestDelegate Methods

- (void)msRequest:(MSRequest *)request didFailWithError:(NSError *)error {
NSString *type = [[request userInfo] objectForKey:@"type"];
  if ([type isEqualToString:@"accessToken"] && (2 > _accessTokenCalls)) {
    [self performSelector:@selector(getAccessToken) withObject:nil afterDelay:0.5];
    return;
  }
  
  [self cancel];
  if ([self.delegate respondsToSelector:@selector(loginViewController:didFailWithError:)]) {
    [self.delegate loginViewController:self didFailWithError:error];
  }
}

- (void)msRequest:(MSRequest *)request didFinishWithRawData:(NSData *)data {
  NSString *type = [[request userInfo] objectForKey:@"type"];
  if ([type isEqualToString:@"requestToken"]) {
    NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [_requestToken release];
    _requestToken = nil;
    _requestToken = [[MSOAuthToken alloc] initWithHTTPResponseBody:responseBody];
    [responseBody release];
    
    if (!_webView) {
      _webView = [[UIWebView alloc] initWithFrame:[self.view bounds]];
      [_webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
      [_webView setDataDetectorTypes:UIDataDetectorTypeNone];
      [_webView setDelegate:self];
      [_webView setScalesPageToFit:YES];
    }
    MSURLCoder *urlEncoder = [[MSURLCoder alloc] init];
    NSString *permissions = [self.context permissions];
    NSString *urlString;
    if ([permissions length]) {
      urlString = [NSString stringWithFormat:kMSSDKOAuthAuthorizationAndPermissionURL,
                   [urlEncoder encodeURIComponent:[self.context authorizationCallbackURL]],
                   [urlEncoder encodeURIComponent:[_requestToken key]],
                   [self.context languageString],
                   [urlEncoder encodeURIComponent:[self.context permissions]],
                   nil];
    } else {
      urlString = [NSString stringWithFormat:kMSSDKOAuthAuthorizationURL,
                   [urlEncoder encodeURIComponent:[self.context authorizationCallbackURL]],
                   [urlEncoder encodeURIComponent:[_requestToken key]],
                   [self.context languageString],
                   nil];
    }
    [urlEncoder release];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:request];
    [self.view insertSubview:_webView belowSubview:_closeButton];
    
    [_request release];
    _request = nil;
  } else if ([type isEqualToString:@"accessToken"]) {
    NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    MSOAuthToken *accessToken = [[MSOAuthToken alloc] initWithHTTPResponseBody:responseBody];
    [responseBody release];
    
    [self cancel];
    
    if ([self.delegate respondsToSelector:@selector(loginViewController:didLoginWithToken:)]) {
      [self.delegate loginViewController:self didLoginWithToken:accessToken];
    }
    [accessToken release];
  }
}

#pragma mark -
#pragma mark UIWebViewDelegate Methods

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  [_activityIndicatorView removeFromSuperview];
  [_activityIndicatorView release];
  _activityIndicatorView = nil;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  NSString *absoluteURL = [[request URL] absoluteString];
  if (NSNotFound != [absoluteURL rangeOfString:[self.context authorizationCallbackURL] options:NSCaseInsensitiveSearch | NSAnchoredSearch].location) {
    if (NSNotFound == [absoluteURL rangeOfString:@"oauth_problem="].location) {
      [_request cancel];
      [_request release];
      _request = nil;
      _accessTokenCalls = 0;
      [self getAccessToken];
    } else {
      [self cancel];
      if ([self.delegate respondsToSelector:@selector(loginViewControllerUserDidCancel:)]) {
        [self.delegate loginViewControllerUserDidCancel:self];
      }
    }
    return NO;
  }
  return YES;
}

#pragma mark -
#pragma mark Helper Methods

- (void)addLoadingView {
  UIView *view = self.view;
  [view setBackgroundColor:[UIColor whiteColor]];
  if (!_activityIndicatorView) {
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    CGRect bounds = [view bounds];
    [_activityIndicatorView setCenter:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
    [_activityIndicatorView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin |
                                                 UIViewAutoresizingFlexibleRightMargin |
                                                 UIViewAutoresizingFlexibleTopMargin |
                                                 UIViewAutoresizingFlexibleBottomMargin)];
    [view insertSubview:_activityIndicatorView belowSubview:_closeButton];
    [_activityIndicatorView startAnimating];
  }
}

- (void)getAccessToken {
  if (_requestToken) {
    [_request cancel];
    [_request release];
    _request = nil;    
    _accessTokenCalls++;
    
    _request = [[MSRequest alloc] initWithContext:self.context
                                              url:[NSURL URLWithString:kMSSDKOAuthAccessTokenURL]
                                           method:@"GET"
                               requestContentType:nil
                                      requestData:nil
                                   rawRequestData:nil
                                         delegate:self];
    [_request setUserInfo:[NSDictionary dictionaryWithObject:@"accessToken" forKey:@"type"]];
    [_request executeWithToken:_requestToken];
  }
}

- (void)getRequestToken {
  if (!_request && !_requestToken) {
    _request = [[MSRequest alloc] initWithContext:self.context
                                              url:[NSURL URLWithString:kMSSDKOAuthRequestTokenURL]
                                           method:@"GET"
                               requestContentType:nil
                                      requestData:nil
                                   rawRequestData:nil
                                         delegate:self];
    [_request setUserInfo:[NSDictionary dictionaryWithObject:@"requestToken" forKey:@"type"]];
    [_request execute];
  }
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [_webView setDelegate:nil];
  [_request cancel];
  
  [_activityIndicatorView release];
  [_context release];
  [_request release];
  [_requestToken release];
  [_webView release];
  [super dealloc];
}

@end
