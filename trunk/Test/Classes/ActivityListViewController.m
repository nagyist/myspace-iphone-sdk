//
//  ActivityListViewController.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/26/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "ActivityListViewController.h"
#import <MySpaceSDK/MySpaceSDK.h>
#import "UIImage+Scale.h"

@interface ActivityListViewController ()

- (void)_msSDKDidGetActivitiesNotification:(NSNotification *)notification;
- (void)_updateImageView:(UIImageView *)imageView withActivity:(id)activity indexPath:(NSIndexPath *)indexPath;

@end

@implementation ActivityListViewController

// this should go into some sort of application cache - using a static array for simplicity of demo
static NSMutableArray *_activities = nil;

#pragma mark -
#pragma mark Properties

@synthesize activityMessageTextField=_activityMessageTextField;
@synthesize tableView=_tableView;

#pragma mark -
#pragma mark View Management

- (void)viewDidLoad {
  [super viewDidLoad];
  
  MSSDK *sdk = [MSSDK sharedSDK];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_msSDKDidGetActivitiesNotification:)
                                               name:MSSDKDidGetActivitiesNotification
                                             object:sdk];
  
  if (nil == _activities) {
    [sdk getActivities];
  }
}

- (void)viewDidUnload {
  self.activityMessageTextField = nil;
  self.tableView = nil;
  
  [super viewDidUnload];
}

#pragma mark -
#pragma mark Actions

- (IBAction)publishActivity {
  [[MSSDK sharedSDK] publishActivityWithTemplate:@"sdk"
                              templateParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  [self.activityMessageTextField text], @"message",
                                                  nil]
                                      externalID:nil];
}

#pragma mark -
#pragma mark DataDownloaderDelegate Methods

- (void)dataDownloaderDidFinish:(DataDownloader *)dataDownloader {
  UIImage *image = [[UIImage imageWithData:[dataDownloader data]] imageAspectScaledToFill:CGSizeMake(40.0, 40.0)];
  
  NSDictionary *userInfo = [dataDownloader userInfo];
  id activity = [userInfo objectForKey:@"activity"];
  
  // caching image on activity object - can go into an URL cache for better re-use
  [activity setValue:image forKeyPath:@"sourceImage"];
  
  NSIndexPath *indexPath = [dataDownloader indexPath];
  UITableViewCell *cell = (indexPath ? [self.tableView cellForRowAtIndexPath:indexPath] : nil);
  UIImageView *imageView = (cell ? [cell imageView] : [userInfo objectForKey:@"imageView"]);
  [imageView setImage:image];
  [cell setNeedsLayout];
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *reuseIdentifier = @"activityCell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if (!cell) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:reuseIdentifier] autorelease];
  }
  id activity = [_activities objectAtIndex:indexPath.row];
  [[cell textLabel] setText:[activity valueForKeyPath:@"title"]];
  
  [self _updateImageView:[cell imageView] withActivity:activity indexPath:indexPath];
  
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_activities count];
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self.activityMessageTextField resignFirstResponder];
  [self publishActivity];
  return YES;
}

#pragma mark -
#pragma mark Notification Handler Methods

- (void)_msSDKDidGetActivitiesNotification:(NSNotification *)notification {
  id temp = [[notification userInfo] valueForKeyPath:@"data.objects"];
  if ([temp isKindOfClass:[NSArray class]]) {
    NSArray *activities = (NSArray *)temp;
    if (_activities) {
      [_activities removeAllObjects];
    } else {
      _activities = [[NSMutableArray alloc] initWithCapacity:[activities count]];
    }
    for (id activity in activities) {
      [_activities addObject:[[activity mutableCopy] autorelease]];
    }
    [_downloaders makeObjectsPerformSelector:@selector(cancel)];
    [_downloaders removeAllObjects];
    [self.tableView reloadData];
  }
}

#pragma mark -
#pragma mark Helper Methods

- (void)_updateImageView:(UIImageView *)imageView withActivity:(id)activity indexPath:(NSIndexPath *)indexPath {
  [imageView setImage:[activity valueForKeyPath:@"sourceImage"]];
  if (![activity valueForKeyPath:@"sourceImage"] && [activity valueForKeyPath:@"sourceImageURL"]) {
    if (!_downloaders) {
      _downloaders = [[NSMutableSet alloc] init];
    }
    DataDownloader *downloader = [[[DataDownloader alloc] init] autorelease];
    [downloader setDataURL:[activity valueForKeyPath:@"sourceImageURL"]];
    [downloader setDelegate:self];
    if (indexPath) {
      [downloader setIndexPath:indexPath];
      [downloader setUserInfo:[NSDictionary dictionaryWithObject:activity forKey:@"activity"]];
    } else {
      [downloader setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                               imageView, @"imageView",
                               activity, @"activity",
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
