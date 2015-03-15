The following code snippets will help you get started with MySpace iPhone SDK.  Some common facts/notes you will use and need to know about SDK:
  1. All SDK Requests are made Asynchronous (implicit)
  1. Use MSAPI class from SDK to make requests into the SDK. (e.g. [getCurrentStatus](MSAPI.md))
  1. Register for notifications to handle the responses from the SDK calls
  1. Specify POST parameters using NSDictionary for POST/PUT functionality (e.g. Status, Mood)
  1. Specify GET parameters using Java Map for GET functionality to access certain properties
  1. Response will return with an NSDictionary containing the data


---


## Login and Logout ##

Following is a code snippet to login into new/existing MySpace session/context.  The full example is in MySpaceSDKTesterAppDelegate.

#### Steps: ####

```
// configure the SDK context with the details of your application
[MSContext initializeSharedContextWithConsumerKey:CONSUMER_KEY
                                           secret:CONSUMER_SECRET
                         authorizationCallbackURL:CALLBACK_URL];
MSSDK *sdk = [MSSDK sharedSDK];
[sdk setUseLocation:YES];
```

```
// resume the context from a previously stored state
[[MSContext sharedContext] resume];
```

```
// login if context not resumed
if (![[MSContext sharedContext] isLoggedIn]) {
  [[MSContext sharedContext] loginWithViewController:self.viewController animated:YES];
}
```


---


## Get Status Mood ##

Following is a code snippet to Get Current User Status & Mood. The full example is in StatusViewController.

#### Steps ####

```
// listen for notifications for the status service
MSSDK *sdk = [MSSDK sharedSDK];
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(msSDKDidGetCurrentStatusNotification:)
                                             name:MSSDKDidGetCurrentStatusNotification
                                           object:sdk];
// load the current status & mood
[[MSSDK sharedSDK] getCurrentStatus];
```

```
- (void)msSDKDidGetCurrentStatusNotification:(NSNotification *)notification {
  NSString *status = [[notification userInfo] valueForKeyPath:@"data.status"];
  NSString *mood = [[notification userInfo] valueForKeyPath:@"data.moodName"];
  NSString *moodImageURL = [[notification userInfo] valueForKeyPath:@"data.moodImageURL"];
  // do something here with the status and mood
}
```


---


## Update Status Mood ##

Following is a code snippet to Update Status Mood. Full example is in StatusViewController.

#### Steps ####

```
// get the status
NSString *status = @"Using the MySpace SDK on iPhone!";
// construct the mood dictionary
NSDictionary *mood = [NSDictionary dictionaryWithObject:@"jedi" forKey:@"moodName"];
```

```
// update the status and mood
[[MSSDK sharedSDK] updateStatus:status mood:mood];
```


---


## Lower level SDK Developers Support ##

This will be special case for users who do not want to use the MSAPI class to make requests into MySpace SDK.  Programmers will still need to implement notification handlers for Async requests as before.  Currently MySpace iPhone SDKs will work with all JSON web services for now and POST, PUT payload is “application/json” type. The MySpace team is working on adding support for XML.

  * GET Request:

```
MSRequest *request = [MSRequest msRequestWithContext:context
                                                 url:url
                                              method:@"GET"
                                         requestData:nil
                                      rawRequestData:nil
                                            delegate:self];
[request execute];
```

  * POST Request:

```
MSRequest *request = [[[MSRequest alloc] initWithContext:context
                                                     url:url
                                                  method:@"POST"
                                      requestContentType:@"image/png"
                                             requestData:nil
                                          rawRequestData:imageData
                                                delegate:self] autorelease];
[request execute];
```

  * PUT Request:

```
MSRequest *request = [[[MSRequest alloc] initWithContext:context
                                                     url:url
                                                  method:@"PUT"
                                             requestData:dictionaryData
                                          rawRequestData:nil
                                                delegate:self] autorelease];
[request execute];
```

NOTE:
Myspace API urls are provided on http://wiki.developer.myspace.com
e.g.  http://wiki.developer.myspace.com/index.php?title=OpenSocial_v0.9_StatusMood