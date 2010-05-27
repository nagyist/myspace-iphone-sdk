//
//  ActivityListViewController.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/26/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataDownloader.h"

@interface ActivityListViewController : UIViewController <DataDownloaderDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
@private
  UITextField *_activityMessageTextField;
  NSMutableSet *_downloaders;
  UITableView *_tableView;
}

@property (nonatomic, retain) IBOutlet UITextField *activityMessageTextField;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

- (IBAction)publishActivity;

@end
