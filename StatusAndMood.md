# getStatus #

Gets the status and mood values for the current user's friends.

## Steps ##

Listen for notifications for the status service
```
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(msSDKDidGetStatusNotification:)
                                             name:MSSDKDidGetStatusNotification
                                           object:[MSSDK sharedSDK]];
```

Get the status for friends
```
[[MSSDK sharedSDK] getStatus];
```

Handle the status response
```
- (void)msSDKDidGetStatusNotification:(NSNotification *)notification {
  NSArray *statuses = [[notification userInfo] valueForKeyPath:@"data.objects"];
  // do something here with the statuses
}
```


---


# getCurrentStatus #

Gets the current status and mood of the user.

## Steps ##

Listen for notifications for the status service
```
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(msSDKDidGetCurrentStatusNotification:)
                                             name:MSSDKDidGetCurrentStatusNotification
                                           object:[MSSDK sharedSDK]];
```

Load the current status
```
[[MSSDK sharedSDK] getCurrentStatus];
```

// Handle the status response
```
- (void)msSDKDidGetCurrentStatusNotification:(NSNotification *)notification {
  NSDictionary *statusAndMood = [[notification userInfo] valueForKeyPath:@"data"];
  // do something here with the status and mood
}
```

# getMoods #

Get the list of available moods to display to the user.

## Steps ##

Listen for notifications for the moods service
```
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(msSDKDidGetMoodsNotification:)
                                             name:MSSDKDidGetMoodNotification
                                           object:[MSSDK sharedSDK]];
```

Load the moods
```
[[MSSDK sharedSDK] getMoods];
```

Handle the moods response
```
- (void)msSDKDidGetMoodsNotification:(NSNotification *)notification {
  // stores the moods in a member variable
  moods = [[[notification userInfo] valueForKeyPath:@"data.objects"] retain];
}
```

# updateStatus:mood: #

Updates the current user's status and mood.

## Steps ##

Get the new status and mood from UI controls
```
NSString *status = newStatusValue;
NSDictionary *mood = [moods objectAtIndex:selectedMoodIndex];
```

Construct the request data
```
NSMutableDictionary *currentStatusAndMood = [NSMutableDictionary dictionary];
if ([mood valueForKey:@"key"]) {
  [currentStatusAndMood setObject:[mood valueForKey:@"key"] forKey:@"moodKey"];
  [currentStatusAndMood addEntriesFromDictionary:mood];
} else {
  mood = nil;
}
[currentStatusAndMood setObject:status forKey:@"status"];
```

Send the update
```
[[MSSDK sharedSDK] updateStatus:status mood:mood];
```