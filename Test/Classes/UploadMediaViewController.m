//
//  UploadMediaViewController.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/19/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "UploadMediaViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MySpaceSDK/MySpaceSDK.h>

@interface UploadMediaViewController ()

- (void)_msSDKDidGetVideoCategoriesNotification:(NSNotification *)notification;
- (void)_showError:(NSString *)message;

@end

@implementation UploadMediaViewController

// this should go into some sort of application cache - using a static array for simplicity of demo
static NSArray *_videoCategories = nil;

#pragma mark -
#pragma mark View Management

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // listen for notifications for the video categories service
  MSSDK *sdk = [MSSDK sharedSDK];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_msSDKDidGetVideoCategoriesNotification:)
                                               name:MSSDKDidGetVideoCategoriesNotification
                                             object:sdk];
  
  if (nil == _videoCategories) {
    [sdk getVideoCategories];
  }
}

- (void)viewDidUnload {
  [super viewDidUnload];
  
  MSSDK *sdk = [MSSDK sharedSDK];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:MSSDKDidGetVideoCategoriesNotification
                                                object:sdk];
}

#pragma mark -
#pragma mark Actions

- (IBAction)captureMedia {
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    UIImagePickerController *viewController = [[[UIImagePickerController alloc] init] autorelease];
    [viewController setDelegate:self];
    [viewController setSourceType:UIImagePickerControllerSourceTypeCamera];
    [self presentModalViewController:viewController animated:YES];
  } else {
    [self _showError:@"You need a camera to capture media!"];
  }
}

- (IBAction)pickMedia {
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
    UIImagePickerController *viewController = [[[UIImagePickerController alloc] init] autorelease];
    [viewController setDelegate:self];
    NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [viewController setMediaTypes:mediaTypes];
    [viewController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [self presentModalViewController:viewController animated:YES];
  } else {
    [self _showError:@"You need a photo album to pick media!"];
  }
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  [self dismissModalViewControllerAnimated:YES];
  NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
  if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) {
      image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    if (image) {
      [[MSSDK sharedSDK] uploadImage:image title:nil];
    } else {
      [self _showError:@"Error loading image!"];
    }
  } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
    NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    if (videoURL) {
      [[MSSDK sharedSDK] uploadVideo:videoURL title:@"Test Video" description:@"This is a test video uploaded through the iPhone SDK" tags:[NSArray arrayWithObject:@"mobile"] categories:[NSArray arrayWithObject:[[_videoCategories objectAtIndex:0] valueForKeyPath:@"key"]]];
    } else {
      [self _showError:@"Error loading video!"];
    }
  } else {
    [self _showError:@"Unknown media type!"];
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Notification Handler Methods

- (void)_msSDKDidGetVideoCategoriesNotification:(NSNotification *)notification {
  id temp = [[notification userInfo] valueForKeyPath:@"data.objects"];
  if ([temp isKindOfClass:[NSArray class]]) {
    [_videoCategories release];
    _videoCategories = [[NSArray alloc] initWithArray:(NSArray *)temp];
  }
}

#pragma mark -
#pragma mark Helper Methods

- (void)_showError:(NSString *)message {
  UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                       message:message
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil] autorelease];
  [alertView show];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

@end
