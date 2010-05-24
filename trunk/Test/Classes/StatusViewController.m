//
//  StatusViewController.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/16/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "StatusViewController.h"
#import <MySpaceSDK/MySpaceSDK.h>

@interface StatusViewController ()

- (void)_msSDKDidGetCurrentStatusNotification:(NSNotification *)notification;
- (void)_msSDKDidGetMoodsNotification:(NSNotification *)notification;
- (void)_statusAndMoodUpdated:(BOOL)animated;
- (void)_updateImageView:(UIImageView *)imageView withMood:(id)mood indexPath:(NSIndexPath *)indexPath;

@end

@implementation StatusViewController

#define MOOD_PICKER_IMAGE_TAG 1
#define MOOD_PICKER_LABEL_TAG 2

#define MOOD_IMAGE_MAX_SIZE   20.0
#define MOOD_ITEM_HEIGHT      34.0

// this should go into some sort of application cache - using a static array for simplicity of demo
static NSMutableArray *_moods = nil;

#pragma mark -
#pragma mark Properties

@synthesize moodImageView=_moodImageView;
@synthesize moodLabel=_moodLabel;
@synthesize moodPicker=_moodPicker;
@synthesize statusLabel=_statusLabel;
@synthesize statusTextField=_statusTextField;

#pragma mark -
#pragma mark View Management

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // listen for notifications for the status service
  MSSDK *sdk = [MSSDK sharedSDK];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_msSDKDidGetCurrentStatusNotification:)
                                               name:MSSDKDidGetCurrentStatusNotification
                                             object:sdk];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(_msSDKDidGetMoodsNotification:)
                                               name:MSSDKDidGetMoodNotification
                                             object:sdk];
  
  [self _statusAndMoodUpdated:NO];
  
  if (nil == _moods) {
    [sdk getMoods];
  }
}

- (void)viewDidUnload {
  [super viewDidUnload];
  
  MSSDK *sdk = [MSSDK sharedSDK];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:MSSDKDidGetCurrentStatusNotification
                                                object:sdk];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:MSSDKDidGetMoodNotification
                                                object:sdk];
  
  self.moodImageView = nil;
  self.moodLabel = nil;
  self.moodPicker = nil;
  self.statusLabel = nil;
  self.statusTextField = nil;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  if (nil == _currentStatusAndMood) {
    [_currentStatusAndMood release];
    _currentStatusAndMood = [[NSDictionary alloc] init];
    [[MSSDK sharedSDK] getCurrentStatus];
  }
}

#pragma mark -
#pragma mark UIResponder Methods

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if ([_statusTextField isFirstResponder]) {
    UITouch *touch = [touches anyObject];
    if ([touch view] != _statusTextField) {
      [_statusTextField resignFirstResponder];
    }
  }
}

#pragma mark -
#pragma mark Actions

- (IBAction)updateStatusAndMood {
  NSString *status = [self.statusTextField text];
  NSDictionary *mood = [_moods objectAtIndex:[self.moodPicker selectedRowInComponent:0]];
  NSMutableDictionary *currentStatusAndMood = [NSMutableDictionary dictionaryWithObject:status forKey:@"status"];
  [currentStatusAndMood addEntriesFromDictionary:mood];
  [_currentStatusAndMood release];
  _currentStatusAndMood = [currentStatusAndMood retain];
  [self _statusAndMoodUpdated:YES];
  [[MSSDK sharedSDK] updateStatus:status mood:mood];
}

#pragma mark -
#pragma mark DataDownloaderDelegate Methods

- (void)dataDownloaderDidFinish:(DataDownloader *)dataDownloader {
  UIImage *image = [UIImage imageWithData:[dataDownloader data]];
  
  NSDictionary *userInfo = [dataDownloader userInfo];
  id mood = [userInfo objectForKey:@"mood"];
  [mood setValue:image forKeyPath:@"cachedImage"];
  
  NSIndexPath *indexPath = [dataDownloader indexPath];
  UIImageView *imageView = (indexPath ?
                            (UIImageView *)[[self.moodPicker viewForRow:[indexPath row]
                                                           forComponent:[indexPath section]] viewWithTag:MOOD_PICKER_IMAGE_TAG] :
                            [userInfo objectForKey:@"imageView"]);
  [imageView setImage:image];
}

#pragma mark -
#pragma mark UIPickerViewDataSource Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return [_moods count];
}

#pragma mark -
#pragma mark UIPickerViewDelegate Methods

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
  return MOOD_ITEM_HEIGHT;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return [[_moods objectAtIndex:row] valueForKeyPath:@"moodName"];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
  UIImageView *imageView;
  UILabel *label;
  if (!view) {
    CGRect frame = CGRectMake(0.0,
                              0.0,
                              [self pickerView:pickerView widthForComponent:component],
                              [self pickerView:pickerView rowHeightForComponent:component]);
    view = [[[UIView alloc] initWithFrame:frame] autorelease];
    
    CGFloat imageOffset = (frame.size.height - MOOD_IMAGE_MAX_SIZE) / 2;
    imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(imageOffset,
                                                               imageOffset,
                                                               MOOD_IMAGE_MAX_SIZE,
                                                               MOOD_IMAGE_MAX_SIZE)] autorelease];
    [imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth |
     UIViewAutoresizingFlexibleHeight |
     UIViewAutoresizingFlexibleRightMargin];
    [imageView setBackgroundColor:[UIColor clearColor]];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [imageView setTag:MOOD_PICKER_IMAGE_TAG];
    [view addSubview:imageView];
    
    label = [[[UILabel alloc] initWithFrame:CGRectMake(frame.size.height,
                                                       0.0,
                                                       frame.size.width - frame.size.height,
                                                       frame.size.height)] autorelease];
    [label setAutoresizingMask:UIViewAutoresizingFlexibleWidth |
     UIViewAutoresizingFlexibleHeight |
     UIViewAutoresizingFlexibleLeftMargin];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTag:MOOD_PICKER_LABEL_TAG];
    [view addSubview:label];
  }
  imageView = (UIImageView *)[view viewWithTag:MOOD_PICKER_IMAGE_TAG];
  label = (UILabel *)[view viewWithTag:MOOD_PICKER_LABEL_TAG];
  
  id mood = [_moods objectAtIndex:row];
  [label setText:[mood valueForKeyPath:@"moodName"]];
  
  [self _updateImageView:imageView withMood:mood indexPath:[NSIndexPath indexPathForRow:row inSection:component]];
  
  return view;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
  return pickerView.bounds.size.width;
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [_statusTextField resignFirstResponder];
  return YES;
}

#pragma mark -
#pragma mark Notification Handler Methods

- (void)_msSDKDidGetCurrentStatusNotification:(NSNotification *)notification {
  [_currentStatusAndMood release];
  _currentStatusAndMood = [[[notification userInfo] valueForKeyPath:@"data"] retain];
  [self _statusAndMoodUpdated:YES];
}

- (void)_msSDKDidGetMoodsNotification:(NSNotification *)notification {
  id temp = [[notification userInfo] valueForKeyPath:@"data.objects"];
  if ([temp isKindOfClass:[NSArray class]]) {
    NSArray *moods = (NSArray *)temp;
    if (_moods) {
      [_moods removeAllObjects];
    } else {
      _moods = [[NSMutableArray alloc] initWithCapacity:[moods count]];
    }
    [_moods addObject:[NSDictionary dictionaryWithObject:@"(none)" forKey:@"moodName"]];
    for (id mood in moods) {
      [_moods addObject:[[mood mutableCopy] autorelease]];
    }
    [_downloaders makeObjectsPerformSelector:@selector(cancel)];
    [_downloaders removeAllObjects];
    [self.moodPicker reloadAllComponents];
    [self _statusAndMoodUpdated:YES];
  }
}

#pragma mark -
#pragma mark Helper Methods

- (void)_statusAndMoodUpdated:(BOOL)animated {
  [self.statusLabel setText:[_currentStatusAndMood valueForKeyPath:@"status"]];
  [self _updateImageView:self.moodImageView withMood:_currentStatusAndMood indexPath:nil];
  [self.moodLabel setText:[_currentStatusAndMood valueForKeyPath:@"moodName"]];
  NSUInteger index = NSNotFound;
  NSUInteger count = [_moods count];
  id moodKey = [_currentStatusAndMood valueForKeyPath:@"moodKey"];
  for (NSUInteger i = 0; i < count; ++i) {
    if ([moodKey isEqual:[[_moods objectAtIndex:i] valueForKeyPath:@"key"]]) {
      index = i;
      break;
    }
  }
  [self.moodPicker selectRow:(NSNotFound == index ? 0 : index)
                 inComponent:0
                    animated:animated];
}

- (void)_updateImageView:(UIImageView *)imageView withMood:(id)mood indexPath:(NSIndexPath *)indexPath {
  [imageView setImage:[mood valueForKeyPath:@"cachedImage"]];
  if (![mood valueForKeyPath:@"cachedImage"] && [mood valueForKeyPath:@"moodImageURL"]) {
    if (!_downloaders) {
      _downloaders = [[NSMutableSet alloc] init];
    }
    DataDownloader *downloader = [[[DataDownloader alloc] init] autorelease];
    [downloader setDataURL:[mood valueForKeyPath:@"moodImageURL"]];
    [downloader setDelegate:self];
    if (indexPath) {
      [downloader setIndexPath:indexPath];
      [downloader setUserInfo:[NSDictionary dictionaryWithObject:mood forKey:@"mood"]];
    } else {
      [downloader setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                               imageView, @"imageView",
                               mood, @"mood",
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
  
  [_currentStatusAndMood release];
  [_downloaders release];
  [super dealloc];
}

@end
