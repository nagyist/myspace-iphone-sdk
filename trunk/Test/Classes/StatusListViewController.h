//
//  StatusListViewController.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/26/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataDownloader.h"

@interface StatusListViewController : UITableViewController <DataDownloaderDelegate> {
@private
  NSMutableSet *_downloaders;
}

@end
