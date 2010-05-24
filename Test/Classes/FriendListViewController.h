//
//  FriendListViewController.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/7/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataDownloader.h"

@interface FriendListViewController : UITableViewController <DataDownloaderDelegate> {
@private
  NSMutableSet *_downloaders;
}

@end
