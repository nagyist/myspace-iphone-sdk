//
//  StatusViewController.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/16/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "DataDownloader.h"

@interface StatusViewController : UIViewController <DataDownloaderDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate> {
@private
  NSDictionary *_currentStatusAndMood;
  NSMutableSet *_downloaders;
  UIImageView *_moodImageView;
  UILabel *_moodLabel;
  UIPickerView *_moodPicker;
  UILabel *_statusLabel;
  UITextField *_statusTextField;
}

@property (nonatomic, retain) IBOutlet UIImageView *moodImageView;
@property (nonatomic, retain) IBOutlet UILabel *moodLabel;
@property (nonatomic, retain) IBOutlet UIPickerView *moodPicker;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UITextField *statusTextField;

- (IBAction)updateStatusAndMood;

@end
