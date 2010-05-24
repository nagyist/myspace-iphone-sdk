//
//  MSLoginViewController.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/14/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSLoginViewController.h"
#import "MSConstants.h"
#import "MSURLCoder.h"

@implementation MSLoginViewController

#pragma mark -
#pragma mark Initialization

- (id)initWithContext:(MSContext *)context delegate:(id<MSLoginViewControllerDelegate>)delegate {
  if (self = [super initWithNibName:nil bundle:nil]) {
    _context = (context ? [context retain] : [MSContext sharedContext]);
    self.delegate = delegate;
    
    _request = [[MSRequest alloc] initWithContext:_context
                                              url:[NSURL URLWithString:kMSSDKOAuthRequestTokenURL]
                                           method:@"GET"
                                      requestData:nil
                                   rawRequestData:nil
                                         delegate:self];
    [_request setUserInfo:[NSDictionary dictionaryWithObject:@"requestToken" forKey:@"type"]];
    [_request execute];
  }
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [self initWithContext:nil delegate:nil];
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize delegate=_delegate;

#pragma mark -
#pragma mark Actions

- (void)cancel {
  [_request cancel];
  [_request release];
  _request = nil;
  
  [_requestToken release];
  _requestToken = nil;
}

- (void)dismiss {
  UIViewController *parentViewController = self.parentViewController;
  if ([parentViewController modalViewController] == self) {
    [parentViewController dismissModalViewControllerAnimated:YES];
  }
}

#pragma mark -
#pragma mark MSRequestDelegate Methods

- (void)msRequest:(MSRequest *)request didFailWithError:(NSError *)error {
  [self cancel];
  if ([self.delegate respondsToSelector:@selector(loginViewController:didFailWithError:)]) {
    [self.delegate loginViewController:self didFailWithError:error];
  }
}

- (void)msRequest:(MSRequest *)request didFinishWithRawData:(NSData *)data {
  NSString *type = [[request userInfo] objectForKey:@"type"];
  if ([type isEqualToString:@"requestToken"]) {
    NSString *responseBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    [_requestToken release];
    _requestToken = nil;
    _requestToken = [[MSOAuthToken alloc] initWithHTTPResponseBody:responseBody];
    
    if (!_webView) {
      _webView = [[UIWebView alloc] initWithFrame:[self.view bounds]];
      [_webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
      [_webView setDataDetectorTypes:UIDataDetectorTypeNone];
      [_webView setDelegate:self];
      [_webView setScalesPageToFit:YES];
    }
    MSURLCoder *urlEncoder = [[[MSURLCoder alloc] init] autorelease];
    NSString *urlString = [NSString stringWithFormat:kMSSDKOAuthAuthorizationURL,
                           [urlEncoder encodeURIComponent:[_context authorizationCallbackURL]],
                           [urlEncoder encodeURIComponent:[_requestToken key]],
                           nil];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:request];
    [self.view addSubview:_webView];
    
    [_request release];
    _request = nil;
  } else if ([type isEqualToString:@"accessToken"]) {
    NSString *responseBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    MSOAuthToken *accessToken = [[[MSOAuthToken alloc] initWithHTTPResponseBody:responseBody] autorelease];
    
    [self cancel];
    
    if ([self.delegate respondsToSelector:@selector(loginViewController:didLoginWithToken:)]) {
      [self.delegate loginViewController:self didLoginWithToken:accessToken];
    }
  }
}

#pragma mark -
#pragma mark UIWebViewDelegate Methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  NSString *absoluteURL = [[request URL] absoluteString];
  if (NSNotFound != [absoluteURL rangeOfString:[_context authorizationCallbackURL] options:NSCaseInsensitiveSearch | NSAnchoredSearch].location) {
    if (NSNotFound == [absoluteURL rangeOfString:@"oauth_problem="].location) {
      [_request cancel];
      [_request release];
      _request = nil;
      _request = [[MSRequest alloc] initWithContext:_context
                                                url:[NSURL URLWithString:kMSSDKOAuthAccessTokenURL]
                                             method:@"GET"
                                        requestData:nil
                                     rawRequestData:nil
                                           delegate:self];
      [_request setUserInfo:[NSDictionary dictionaryWithObject:@"accessToken" forKey:@"type"]];
      [_request executeWithToken:_requestToken];
      [_requestToken release];
      _requestToken = nil;
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
#pragma mark Memory Management

- (void)dealloc {
  [self cancel];
  
  [_context release];
  [_webView release];
  [super dealloc];
}

@end
