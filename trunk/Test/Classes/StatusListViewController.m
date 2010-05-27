//
//  StatusListViewController.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/26/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "StatusListViewController.h"
#import <MySpaceSDK/MySpaceSDK.h>
#import "UIImage+Scale.h"

@interface StatusListViewController ()

- (void)_msSDKDidGetStatusNotification:(NSNotification *)notification;
- (void)_updateImageView:(UIImageView *)imageView withStatus:(id)status indexPath:(NSIndexPath *)indexPath;

@end

@implementation StatusListViewController

// this should go into some sort of application cache - using a static array for simplicity of demo
static NSMutableArray *_statuses = nil;

#pragma mark -
#pragma mark View Management

- (void)viewDidLoad {
  [super viewDidLoad];
  
  MSSDK *sdk = [MSSDK sharedSDK];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_msSDKDidGetStatusNotification:)
                                               name:MSSDKDidGetStatusNotification
                                             object:sdk];
  
  if (nil == _statuses) {
    [sdk getStatus];
  }
}

#pragma mark -
#pragma mark DataDownloaderDelegate Methods

- (void)dataDownloaderDidFinish:(DataDownloader *)dataDownloader {
  UIImage *image = [[UIImage imageWithData:[dataDownloader data]] imageAspectScaledToFill:CGSizeMake(40.0, 40.0)];
  
  NSDictionary *userInfo = [dataDownloader userInfo];
  id status = [userInfo objectForKey:@"status"];
  
  // caching image on status object - can go into an URL cache for better re-use
  [status setValue:image forKeyPath:@"userThumbnailImage"];
  
  NSIndexPath *indexPath = [dataDownloader indexPath];
  UITableViewCell *cell = (indexPath ? [self.tableView cellForRowAtIndexPath:indexPath] : nil);
  UIImageView *imageView = (cell ? [cell imageView] : [userInfo objectForKey:@"imageView"]);
  [imageView setImage:image];
  [cell setNeedsLayout];
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *reuseIdentifier = @"statusCell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if (!cell) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                   reuseIdentifier:reuseIdentifier] autorelease];
  }
  id status = [_statuses objectAtIndex:indexPath.row];
  [[cell textLabel] setText:[status valueForKeyPath:@"userName"]];
  [[cell detailTextLabel] setText:[status valueForKeyPath:@"status"]];
  
  [self _updateImageView:[cell imageView] withStatus:status indexPath:indexPath];
  
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_statuses count];
}

#pragma mark -
#pragma mark Notification Handler Methods

- (void)_msSDKDidGetStatusNotification:(NSNotification *)notification {
  id temp = [[notification userInfo] valueForKeyPath:@"data.objects"];
  if ([temp isKindOfClass:[NSArray class]]) {
    NSArray *statuses = (NSArray *)temp;
    if (_statuses) {
      [_statuses removeAllObjects];
    } else {
      _statuses = [[NSMutableArray alloc] initWithCapacity:[statuses count]];
    }
    for (id status in statuses) {
      [_statuses addObject:[[status mutableCopy] autorelease]];
    }
    [_downloaders makeObjectsPerformSelector:@selector(cancel)];
    [_downloaders removeAllObjects];
    [self.tableView reloadData];
  }
}

#pragma mark -
#pragma mark Helper Methods

- (void)_updateImageView:(UIImageView *)imageView withStatus:(id)status indexPath:(NSIndexPath *)indexPath {
  [imageView setImage:[status valueForKeyPath:@"userThumbnailImage"]];
  if (![status valueForKeyPath:@"userThumbnailImage"] && [status valueForKeyPath:@"userThumbnailImageURL"]) {
    if (!_downloaders) {
      _downloaders = [[NSMutableSet alloc] init];
    }
    DataDownloader *downloader = [[[DataDownloader alloc] init] autorelease];
    [downloader setDataURL:[status valueForKeyPath:@"userThumbnailImageURL"]];
    [downloader setDelegate:self];
    if (indexPath) {
      [downloader setIndexPath:indexPath];
      [downloader setUserInfo:[NSDictionary dictionaryWithObject:status forKey:@"status"]];
    } else {
      [downloader setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                               imageView, @"imageView",
                               status, @"status",
                               nil]];
    }
    [_downloaders addObject:downloader];
    [downloader execute];
  }
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_downloaders makeObjectsPerformSelector:@selector(cancel)];
  
  [_downloaders release];
  [super dealloc];
}

@end
