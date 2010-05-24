//
//  UploadMediaViewController.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/19/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UploadMediaViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
@private
}

- (IBAction)captureMedia;
- (IBAction)pickMedia;

@end
