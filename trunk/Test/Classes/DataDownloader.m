//
//  DataDownloader.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/29/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "DataDownloader.h"

@implementation DataDownloader

#pragma mark -
#pragma mark Properties

@synthesize data=_data;
@synthesize dataURL=_dataURL;
@synthesize delegate=_delegate;
@synthesize indexPath=_indexPath;
@synthesize userInfo=_userInfo;

#pragma mark -
#pragma mark Download Management

- (void)cancel {
  [_connection cancel];
  [_connection release];
  _connection = nil;
  
  [_data release];
  _data = nil;
}

- (void)execute {
  if (!_connection) {
    [_data release];
    _data = [[NSMutableData alloc] init];
    _connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:self.dataURL] delegate:self];
  }
}

#pragma mark -
#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  [_data release];
  _data = nil;
  
  [_connection release];
  _connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  [self.delegate dataDownloaderDidFinish:self];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  _delegate = nil;
  [_connection cancel];
  
  [_connection release];
  [_data release];
  [_dataURL release];
  [_indexPath release];
  [_userInfo release];
  [super dealloc];
}

@end
