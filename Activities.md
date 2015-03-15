# getActivities #

You can retrieve activities from the stream of the current user.  You can optionally pass additional parameters to the service to give paging context, etc (see http://wiki.developer.myspace.com/index.php?title=OpenSocial_v0.9_Activities for details on supported parameters).

## Steps ##

Listen for notifications for the activities service
```
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(msSDKDidGetActivitiesNotification:)
                                             name:MSSDKDidGetActivitiesNotification
                                           object:[MSSDK sharedSDK]];
```

Load the activities
```
[[MSSDK sharedSDK] getActivities];
```

Handle the activities response
```
- (void)msSDKDidGetActivitiesNotification:(NSNotification *)notification {
  NSArray *activities = [[notification userInfo] valueForKeyPath:@"data.objects"];
  // do something here with the activities
}
```


---


# publishActivityWithTemplate:templateParameters:externalID: #

You can publish new activities to the stream from your application.  This requires a LIVE activity template for your MySpaceID application (http://developer.myspace.com/Apps.mvc - "Manage templates for raising activities" under your application).

## Steps ##

Publish activity data.  The templateID is the template name in the MySpaceID portal.  The templateParameters dictionary provides values for the template.
```
[[MSSDK sharedSDK] publishActivityWithTemplate:@"sdk"
                            templateParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                [self.activityMessageTextField text], @"message",
                                                nil]
                                    externalID:nil];
```