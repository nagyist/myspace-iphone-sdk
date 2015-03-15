# getVideoCategories #

In order to upload a video you must provide a category for that video.  You can fetch the possible category values through the getVideoCategories method.

## Steps ##

Listen for notifications for the video categories service
```
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(msSDKDidGetVideoCategoriesNotification:)
                                             name:MSSDKDidGetVideoCategoriesNotification
                                           object:sdk];
```

Get the categories.
```
[[MSSDK sharedSDK] getVideoCategories];
```

Handle the video categories response
```
- (void)_msSDKDidGetVideoCategoriesNotification:(NSNotification *)notification {
  // store the video categories in a member variable
  videoCategories = [[[notification userInfo] valueForKeyPath:@"data.objects"] retain];
}
```


---


# uploadImage:title: or uploadVideo:title:description:tags:categories: #

Upload an image or video to your mobile uploads album.

## Steps ##

Open the camera to capture a picture or video
```
if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
  UIImagePickerController *viewController = [[[UIImagePickerController alloc] init] autorelease];
  [viewController setDelegate:self];
  [viewController setSourceType:UIImagePickerControllerSourceTypeCamera];
  [self presentModalViewController:viewController animated:YES];
} else {
  NSLog(@"You need a camera to capture media!");
}
```

OR open the media picker to select an existing picture or video
```
if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
  UIImagePickerController *viewController = [[[UIImagePickerController alloc] init] autorelease];
  [viewController setDelegate:self];
  NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
  [viewController setMediaTypes:mediaTypes];
  [viewController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
  [self presentModalViewController:viewController animated:YES];
} else {
  NSLog(@"You need a photo album to pick media!");
}
```

Image picker delegate methods
```
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
      NSLog(@"Error loading image!");
    }
  } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
    NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    if (videoURL) {
      [[MSSDK sharedSDK] uploadVideo:videoURL title:@"Test Video" description:@"This is a test video uploaded through the iPhone SDK" tags:[NSArray arrayWithObject:@"mobile"] categories:[NSArray arrayWithObject:[[videoCategories objectAtIndex:0] valueForKeyPath:@"key"]]];
    } else {
      NSLog(@"Error loading video!");
    }
  } else {
    NSLog(@"Unknown media type!");
  }
}
```