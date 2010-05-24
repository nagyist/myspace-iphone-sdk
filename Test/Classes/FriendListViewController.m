//
//  FriendListViewController.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/7/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "FriendListViewController.h"
#import <MySpaceSDK/MySpaceSDK.h>
#import "UIImage+Scale.h"

@interface FriendListViewController ()

- (void)_msSDKDidGetFriendsNotification:(NSNotification *)notification;
- (void)_updateImageView:(UIImageView *)imageView withFriend:(id)friend indexPath:(NSIndexPath *)indexPath;

@end

@implementation FriendListViewController

// this should go into some sort of application cache - using a static array for simplicity of demo
static NSMutableArray *_friends = nil;

#pragma mark -
#pragma mark View Management

- (void)viewDidLoad {
  [super viewDidLoad];
  
  MSSDK *sdk = [MSSDK sharedSDK];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_msSDKDidGetFriendsNotification:)
                                               name:MSSDKDidGetFriendsNotification
                                             object:sdk];
  
  if (nil == _friends) {
    [sdk getFriends];
  }
}

#pragma mark -
#pragma mark DataDownloaderDelegate Methods

- (void)dataDownloaderDidFinish:(DataDownloader *)dataDownloader {
  UIImage *image = [[UIImage imageWithData:[dataDownloader data]] imageAspectScaledToFill:CGSizeMake(40.0, 40.0)];
  
  NSDictionary *userInfo = [dataDownloader userInfo];
  id friend = [userInfo objectForKey:@"friend"];
  
  // caching image on friend object - can go into an URL cache for better re-use
  [friend setValue:image forKeyPath:@"userThumbnailImage"];
  
  NSIndexPath *indexPath = [dataDownloader indexPath];
  UITableViewCell *cell = (indexPath ? [self.tableView cellForRowAtIndexPath:indexPath] : nil);
  UIImageView *imageView = (cell ? [cell imageView] : [userInfo objectForKey:@"imageView"]);
  [imageView setImage:image];
  [cell setNeedsLayout];
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *reuseIdentifier = @"friendCell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if (!cell) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:reuseIdentifier] autorelease];
  }
  id friend = [_friends objectAtIndex:indexPath.row];
  [[cell textLabel] setText:[friend valueForKeyPath:@"userName"]];
  
  [self _updateImageView:[cell imageView] withFriend:friend indexPath:indexPath];
  
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_friends count];
}

#pragma mark -
#pragma mark Notification Handler Methods

- (void)_msSDKDidGetFriendsNotification:(NSNotification *)notification {
  id temp = [[notification userInfo] valueForKeyPath:@"data.objects"];
  if ([temp isKindOfClass:[NSArray class]]) {
    NSArray *friends = (NSArray *)temp;
    if (_friends) {
      [_friends removeAllObjects];
    } else {
      _friends = [[NSMutableArray alloc] initWithCapacity:[friends count]];
    }
    for (id friend in friends) {
      [_friends addObject:[[friend mutableCopy] autorelease]];
    }
    [_downloaders makeObjectsPerformSelector:@selector(cancel)];
    [_downloaders removeAllObjects];
    [self.tableView reloadData];
  }
}

#pragma mark -
#pragma mark Helper Methods

- (void)_updateImageView:(UIImageView *)imageView withFriend:(id)friend indexPath:(NSIndexPath *)indexPath {
  [imageView setImage:[friend valueForKeyPath:@"userThumbnailImage"]];
  if (![friend valueForKeyPath:@"userThumbnailImage"] && [friend valueForKeyPath:@"userThumbnailImageURL"]) {
    if (!_downloaders) {
      _downloaders = [[NSMutableSet alloc] init];
    }
    DataDownloader *downloader = [[[DataDownloader alloc] init] autorelease];
    [downloader setDataURL:[friend valueForKeyPath:@"userThumbnailImageURL"]];
    [downloader setDelegate:self];
    if (indexPath) {
      [downloader setIndexPath:indexPath];
      [downloader setUserInfo:[NSDictionary dictionaryWithObject:friend forKey:@"friend"]];
    } else {
      [downloader setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                               imageView, @"imageView",
                               friend, @"friend",
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
