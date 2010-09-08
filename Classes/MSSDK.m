//
//  MSSDK.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/14/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSSDK.h"
#import "MSConstants.h"
#import "MSDataMapper.h"
#import "MSMapper.h"
#import "MSURLCoder.h"

@interface NSNotificationCenter (MSSDK)

- (void)msPostNotificationName:(NSString *)notificationName
                        object:(id)notificationSender
                      userInfo:(NSDictionary *)userInfo
               forceMainThread:(BOOL)forceMainThread;

@end

@implementation NSNotificationCenter (MSSDK)

- (void)msPostNotificationName:(NSString *)notificationName
                        object:(id)notificationSender
                      userInfo:(NSDictionary *)userInfo
               forceMainThread:(BOOL)forceMainThread {
  if (!forceMainThread || [NSThread isMainThread]) {
    [self postNotificationName:notificationName object:notificationSender userInfo:userInfo];
  } else {
    [self performSelectorOnMainThread:@selector(postNotification:)
                           withObject:[NSNotification notificationWithName:notificationName
                                                                    object:notificationSender
                                                                  userInfo:userInfo]
                        waitUntilDone:YES];
  }
}

@end

@interface MSSDK ()

- (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification;
- (void)_applicationWillEnterForegroundNotification:(NSNotification *)notification;
- (void)_applicationWillTerminateNotification:(NSNotification *)notification;
- (void)_loadMappers;
- (void)_mapData:(NSDictionary *)userInfo notifyOnMainThread:(BOOL)notifyOnMainThread;
- (void)_mapDataInBackground:(NSDictionary *)userInfo;
- (void)_threadWillExitNotification:(NSNotification *)notification;

@end

@implementation MSSDK

#pragma mark -
#pragma mark Class Methods

static MSSDK *_sharedSDK = nil;

+ (void)resetSharedSDK {
  @synchronized(self) {
    [_sharedSDK release];
    _sharedSDK = nil;
  }
}

+ (MSSDK *)sharedSDK {
  if (!_sharedSDK) {
    @synchronized(self) {
      if (!_sharedSDK) {
        MSContext *context = [MSContext sharedContext];
        if (context) {
          _sharedSDK = [[self alloc] initWithContext:context];
        }
      }
    }
  }
  return _sharedSDK;
}

#pragma mark -
#pragma mark Initialization

- (id)initWithConsumerKey:(NSString *)key secret:(NSString *)secret {
  MSContext *context = [[[MSContext alloc] initWithConsumerKey:key secret:secret] autorelease];
  self = [self initWithContext:context];
  return self;
}

- (id)initWithContext:(MSContext *)context {
  if (self = [super init]) {
    _context = [context retain];
    _requests = [[NSMutableSet alloc] init];
    _requestPriorities = [[NSMutableDictionary alloc] init];
    _locationAccuracy = kCLLocationAccuracyHundredMeters;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    UIApplication *application = [UIApplication sharedApplication];
#ifdef __IPHONE_4_0
    if (NULL != &UIApplicationDidEnterBackgroundNotification) {
      [nc addObserver:self selector:@selector(_applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:application];
    }
    if (NULL != &UIApplicationWillEnterForegroundNotification) {
      [nc addObserver:self selector:@selector(_applicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:application];
    }
#endif
    [nc addObserver:self selector:@selector(_applicationWillTerminateNotification:) name:UIApplicationWillTerminateNotification object:application];
  }
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize context=_context;
@synthesize dataMappers=_dataMappers;
@synthesize locationAccuracy=_locationAccuracy;
@synthesize servicesPlistName=_servicesPlistName;
@synthesize useLocation=_useLocation;
@synthesize xmlMappers=_xmlMappers;

- (NSDictionary *)dataMappers {
  [self _loadMappers];
  return _dataMappers;
}

- (void)setLocationAccuracy:(CLLocationAccuracy)value {
  if (_locationAccuracy != value) {
    _locationAccuracy = value;
    [_locationManager setDesiredAccuracy:value];
  }
}

- (NSOperationQueuePriority)requestPriority {
  @synchronized(_requestPriorities) {
    return (NSOperationQueuePriority)[[_requestPriorities objectForKey:[NSNumber numberWithUnsignedInteger:[[NSThread currentThread] hash]]] integerValue];
  }
}

- (void)setRequestPriority:(NSOperationQueuePriority)value {
  @synchronized(_requestPriorities) {
    NSThread *thread = [NSThread currentThread];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:NSThreadWillExitNotification object:thread];
    [nc addObserver:self selector:@selector(_threadWillExitNotification:) name:NSThreadWillExitNotification object:thread];
    [_requestPriorities setObject:[NSNumber numberWithInteger:value]
                           forKey:[NSNumber numberWithUnsignedInteger:[thread hash]]];
  }
}

- (void)setUseLocation:(BOOL)value {
  if (_useLocation != value) {
    _useLocation = value;
    if (_useLocation) {
      [self startUpdatingLocation];
    } else {
      [self stopUpdatingLocation];
    }
  }
}

- (NSDictionary *)xmlMappers {
  [self _loadMappers];
  return _xmlMappers;
}

#pragma mark -
#pragma mark API Methods

- (void)cancelAllRequests {
  [_requests makeObjectsPerformSelector:@selector(cancel)];
  [_requests removeAllObjects];
}

- (void)executeRequestWithURL:(NSURL *)url
                       method:(NSString *)method
           requestContentType:(NSString *)requestContentType
                  requestData:(NSDictionary *)requestData
               rawRequestData:(NSData *)rawRequestData
                         type:(NSString *)type
             notificationName:(NSString *)notificationName
                     userInfo:(NSDictionary *)userInfo {
  MSRequest *request = [[[MSRequest alloc] initWithContext:self.context
                                                       url:url
                                                    method:method
                                        requestContentType:requestContentType
                                               requestData:requestData
                                            rawRequestData:rawRequestData
                                                  delegate:self] autorelease];
  [request setPriority:self.requestPriority];
  NSMutableDictionary *fullUserInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       type, @"type",
                                       notificationName, @"notificationName",
                                       nil];
  [fullUserInfo addEntriesFromDictionary:userInfo];
  [request setUserInfo:fullUserInfo];
  [_requests addObject:request];
  [request execute];
}

- (void)executeRequestWithURL:(NSURL *)url
                       method:(NSString *)method
                  requestData:(NSDictionary *)requestData
               rawRequestData:(NSData *)rawRequestData
                         type:(NSString *)type
             notificationName:(NSString *)notificationName
                     userInfo:(NSDictionary *)userInfo  {
  [self executeRequestWithURL:url
                       method:method
           requestContentType:nil
                  requestData:requestData
               rawRequestData:rawRequestData
                         type:type
             notificationName:notificationName
                     userInfo:userInfo];
}

- (void)getActivities {
  [self getActivitiesWithParameters:nil];
}

- (void)getActivitiesWithParameters:(NSDictionary *)parameters {
  NSString *type = @"activity";
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:parameters]]
                       method:@"GET"
                  requestData:nil
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidGetActivitiesNotification
                     userInfo:(parameters ? [NSDictionary dictionaryWithObject:parameters forKey:@"parameters"] : nil)];
}

- (void)getActivitiesForPerson:(NSString *)personID {
  [self getActivitiesForPerson:personID parameters:nil];
}

- (void)getActivitiesForPerson:(NSString *)personID parameters:(NSDictionary *)parameters {
  NSString *type = @"activityForPerson";
  NSString *urlString = [self urlForServiceType:type parameters:parameters];
  urlString = [urlString stringByReplacingOccurrencesOfString:@"{personID}" withString:personID];
  NSDictionary *userInfo;
  if (parameters) {
    userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                personID, @"personID",
                parameters, @"parameters",
                nil];
  } else {
    userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                personID, @"personID",
                nil];
  }
  [self executeRequestWithURL:[NSURL URLWithString:urlString]
                       method:@"GET"
                  requestData:nil
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidGetActivitiesForPersonNotification
                     userInfo:userInfo];
}

- (void)getCurrentStatus {
  NSString *type = @"currentStatus";
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:nil]]
                       method:@"GET"
                  requestData:nil
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidGetCurrentStatusNotification
                     userInfo:nil];
}

- (void)getFriends {
  [self getFriendsWithParameters:nil];
}

- (void)getFriendsWithParameters:(NSDictionary *)parameters {
  NSString *type = @"friend";
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:parameters]]
                       method:@"GET"
                  requestData:nil
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidGetFriendsNotification
                     userInfo:(parameters ? [NSDictionary dictionaryWithObject:parameters forKey:@"parameters"] : nil)];
}

- (void)getMoods {
  [self getMoodsWithParameters:nil];
}

- (void)getMoodsWithParameters:(NSDictionary *)parameters {
  NSString *type = @"mood";
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:parameters]]
                       method:@"GET"
                  requestData:nil
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidGetMoodNotification
                     userInfo:(parameters ? [NSDictionary dictionaryWithObject:parameters forKey:@"parameters"] : nil)];
}

- (void)getStatus {
  [self getStatusWithParameters:nil];
}

- (void)getStatusWithParameters:(NSDictionary *)parameters {
  NSString *type = @"status";
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:parameters]]
                       method:@"GET"
                  requestData:nil
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidGetStatusNotification
                     userInfo:(parameters ? [NSDictionary dictionaryWithObject:parameters forKey:@"parameters"] : nil)];
}

- (void)getTopFriends {
  [self getTopFriendsWithParameters:nil];
}

- (void)getTopFriendsWithParameters:(NSDictionary *)parameters {
  NSString *type = @"topFriend";
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:parameters]]
                       method:@"GET"
                  requestData:nil
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidGetTopFriendsNotification
                     userInfo:(parameters ? [NSDictionary dictionaryWithObject:parameters forKey:@"parameters"] : nil)];
}

- (void)getVideoCategories {
  NSString *type = @"videoCategory";
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:nil]]
                       method:@"GET"
                  requestData:nil
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidGetVideoCategoriesNotification
                     userInfo:nil];
}

- (void)publishActivityWithTemplate:(NSString *)templateID
                 templateParameters:(NSDictionary *)templateParameters
                         externalID:(NSString *)externalID {
  NSString *type = @"publishActivity";
  NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObject:templateID forKey:@"titleId"];
  if ([templateParameters count]) {
    NSArray *keys = [templateParameters allKeys];
    NSMutableArray *templateParametersArray = [NSMutableArray arrayWithCapacity:[keys count]];
    for (NSString *key in keys) {
      [templateParametersArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                          key, @"key",
                                          [templateParameters objectForKey:key], @"value",
                                          nil]];
    }
    [data setObject:[NSDictionary dictionaryWithObject:templateParametersArray forKey:@"msParameters"] forKey:@"templateParams"];
  }
  if ([externalID length]) {
    [data setObject:externalID forKey:@"externalId"];
  }
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:templateID forKey:@"templateID"];
  if (templateParameters) {
    [userInfo setObject:templateParameters forKey:@"templateParameters"];
  }
  if (externalID) {
    [userInfo setObject:externalID forKey:@"externalID"];
  }
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:nil]]
                       method:@"POST"
                  requestData:data
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidPublishActivityNotification
                     userInfo:userInfo];
}

- (NSString *)queryStringWithParameters:(NSDictionary *)parameters {
  NSMutableString *queryString = nil;
  if ([parameters count]) {
    queryString = [NSMutableString string];
    MSURLCoder *coder = [[MSURLCoder alloc] init];
    for (NSString *key in parameters) {
      [queryString appendFormat:@"%@=%@&",
       [coder encodeURIComponent:key],
       [coder encodeURIComponent:[parameters objectForKey:key]]];
    }
    [coder release];
    [queryString deleteCharactersInRange:NSMakeRange([queryString length] - 1, 1)];
  }
  return queryString;
}

- (void)updateStatus:(NSString *)status {
  [self updateStatus:status mood:nil];
}

- (void)updateStatus:(NSString *)status mood:(NSDictionary *)mood {
  NSString *type = @"updateStatus";
  NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObject:(status ? status : @"") forKey:@"status"];
  if (mood) {
    MSDataMapper *dataMapper = [self.dataMappers objectForKey:@"mood"];
    if (dataMapper) {
      mood = [dataMapper reverseMapObject:mood];
    }
    [data addEntriesFromDictionary:mood];
  }
  if (_locationManager) {
    CLLocationCoordinate2D location = [[_locationManager location] coordinate];
    [data setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                     [NSString stringWithFormat:@"%f", location.latitude], @"latitude",
                     [NSString stringWithFormat:@"%f", location.longitude], @"longitude",
                     nil]
             forKey:@"currentLocation"];
  }
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
  if (status) {
    [userInfo setObject:status forKey:@"status"];
  }
  if (mood) {
    [userInfo setObject:mood forKey:@"mood"];
  }
  if (0 == [userInfo count]) {
    userInfo = nil;
  }
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:nil]]
                       method:@"PUT"
                  requestData:data
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidUpdateStatusNotification
                     userInfo:userInfo];
}

- (void)uploadImage:(UIImage *)image title:(NSString *)title {
  NSString *type = @"uploadImage";
  NSData *data = UIImagePNGRepresentation(image);
  NSDictionary *parameters = nil;
  if ([title length]) {
    parameters = [NSDictionary dictionaryWithObject:title forKey:@"caption"];
  }
  NSMutableString *url = [NSMutableString stringWithString:[self urlForServiceType:type parameters:parameters]];
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:image forKey:@"image"];
  if (title) {
    [userInfo setObject:title forKey:@"title"];
  }
  [self executeRequestWithURL:[NSURL URLWithString:url]
                       method:@"POST"
           requestContentType:@"image/png"
                  requestData:nil
               rawRequestData:data
                         type:type
             notificationName:MSSDKDidUploadImageNotification
                     userInfo:userInfo];
}

- (void)uploadVideo:(NSURL *)videoURL
              title:(NSString *)title
        description:(NSString *)description
               tags:(NSArray *)tags
         categories:(NSArray *)categories {
  NSString *type = @"uploadVideo";
  NSData *data = [NSData dataWithContentsOfURL:videoURL];
  NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:4];
  if ([title length]) {
    [parameters setObject:title forKey:@"caption"];
  }
  if ([description length]) {
    [parameters setObject:description forKey:@"description"];
  }
  if ([tags count]) {
    [parameters setObject:[tags componentsJoinedByString:@","] forKey:@"tags"];
  }
  if ([categories count]) {
    [parameters setObject:[categories componentsJoinedByString:@","] forKey:@"msCategories"];
  }
  NSMutableString *url = [NSMutableString stringWithString:[self urlForServiceType:type parameters:parameters]];
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:videoURL forKey:@"videoURL"];
  if (title) {
    [userInfo setObject:title forKey:@"title"];
  }
  if (description) {
    [userInfo setObject:description forKey:@"description"];
  }
  if (tags) {
    [userInfo setObject:tags forKey:@"tags"];
  }
  if (categories) {
    [userInfo setObject:categories forKey:@"categories"];
  }
  [self executeRequestWithURL:[NSURL URLWithString:url]
                       method:@"POST"
           requestContentType:@"video/quicktime"
                  requestData:nil
               rawRequestData:data
                         type:type
             notificationName:MSSDKDidUploadVideoNotification
                     userInfo:userInfo];
}

- (NSString *)urlForServiceType:(NSString *)type parameters:(NSDictionary *)parameters {
  NSString *serviceURL = [[[self dataMappers] objectForKey:type] serviceURL];
  NSString *queryString = [self queryStringWithParameters:parameters];
  if ([queryString length]) {
    serviceURL = [NSString stringWithFormat:@"%@%@%@",
                  serviceURL,
                  (NSNotFound == [serviceURL rangeOfString:@"?"].location ? @"?" : @"&"),
                  queryString];
  }
  return serviceURL;
}

#pragma mark -
#pragma mark Location Services Methods

- (void)startUpdatingLocation {
  if ([CLLocationManager respondsToSelector:@selector(locationServicesEnabled)] &&
      ![CLLocationManager performSelector:@selector(locationServicesEnabled)]) {
    return;
  }
  if (!_locationManager) {
    _locationManager = [[CLLocationManager alloc] init];
    [_locationManager setDesiredAccuracy:self.locationAccuracy];
    [_locationManager startUpdatingLocation];
  }
}

- (void)stopUpdatingLocation {
  if (_locationManager) {
    [_locationManager stopUpdatingLocation];
    [_locationManager release];
    _locationManager = nil;
  }
}

#pragma mark -
#pragma mark MSRequestDelegate Methods

- (void)msRequest:(MSRequest *)request didFailWithError:(NSError *)error {
  [[NSNotificationCenter defaultCenter] msPostNotificationName:MSSDKDidFailNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                request, @"request",
                                                                error, @"error",
                                                                nil]
                                               forceMainThread:YES];
}

- (void)msRequest:(MSRequest *)request didFinishWithData:(NSDictionary *)data {
  NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                            [request userInfo], @"requestUserInfo",
                            [NSNumber numberWithBool:[request isAnonymous]], @"isAnonymous",
                            data, @"data",
                            nil];
  if ([NSThread isMainThread]) {
    [self performSelectorInBackground:@selector(_mapDataInBackground:) withObject:userInfo];
  } else {
    [self _mapData:userInfo notifyOnMainThread:NO];
  }
  [_requests removeObject:request];
}

#pragma mark -
#pragma mark Notification Handler Methods

- (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification {
  [self stopUpdatingLocation];
}

- (void)_applicationWillEnterForegroundNotification:(NSNotification *)notification {
  if (self.useLocation) {
    [self startUpdatingLocation];
  }
}

- (void)_applicationWillTerminateNotification:(NSNotification *)notification {
  [self stopUpdatingLocation];
}

- (void)_threadWillExitNotification:(NSNotification *)notification {
  @synchronized(_requestPriorities) {
    [_requestPriorities removeObjectForKey:[NSNumber numberWithUnsignedInteger:[[NSThread currentThread] hash]]];
  }
}

#pragma mark -
#pragma mark Helper Methods

- (void)_loadMappers {
  if (!_dataMappers || !_xmlMappers) {
    @synchronized(self) {
      if (!_dataMappers || !_xmlMappers) {
        NSString *plistName = self.servicesPlistName;
        if (![plistName length]) {
          plistName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MySpaceSDKServicesList"];
        }
        if (![plistName length]) {
          plistName = @"MySpaceSDKServices";
        }
        NSString *path = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
        NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:path];
        NSArray *allKeys = [config allKeys];
        
        if (!_dataMappers) {
          NSMutableDictionary *dataMappers = [NSMutableDictionary dictionaryWithCapacity:[allKeys count]];
          for (NSString *key in allKeys) {
            [dataMappers setObject:[MSDataMapper mapperWithType:key dictionary:[config objectForKey:key]]
                            forKey:key];
          }
          _dataMappers = [[NSDictionary alloc] initWithDictionary:dataMappers];
        }
        
        if (!_xmlMappers) {
          NSMutableDictionary *xmlMappers = _xmlMappers ? nil : [NSMutableDictionary dictionaryWithCapacity:[allKeys count]];
          Class klass = objc_getClass("MSXMLMapper");
          if (klass) {
            for (NSString *key in allKeys) {
              [xmlMappers setObject:[klass mapperWithType:key dictionary:[config objectForKey:key]]
                             forKey:key];
            }
          }
          _xmlMappers = [[NSDictionary alloc] initWithDictionary:xmlMappers];
        }
      }
    }
  }
}

- (void)_mapData:(NSDictionary *)userInfo notifyOnMainThread:(BOOL)notifyOnMainThread {
  NSMutableDictionary *mutableUserInfo = [[[userInfo objectForKey:@"requestUserInfo"] mutableCopy] autorelease];
  NSString *type = [mutableUserInfo objectForKey:@"type"];
  NSDictionary *data = [userInfo objectForKey:@"data"];
  if ([type length]) {
    MSDataMapper *dataMapper = [self.dataMappers objectForKey:type];
    if (dataMapper) {
      NSString *objectArrayKey = [dataMapper objectArrayKey];
      if ([objectArrayKey length]) {
        NSMutableDictionary *otherData = [NSMutableDictionary dictionaryWithDictionary:data];
        [otherData removeObjectForKey:objectArrayKey];
        [mutableUserInfo setObject:otherData forKey:@"otherData"];
      }
      data = [dataMapper mapData:data];
    }
  }
  [mutableUserInfo setObject:data forKey:@"data"];
  [mutableUserInfo setObject:[userInfo objectForKey:@"isAnonymous"] forKey:@"isAnonymous"];
  
  NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
  [dnc msPostNotificationName:MSSDKDidFinishNotification object:self userInfo:mutableUserInfo forceMainThread:notifyOnMainThread];
  NSString *notificationName = [mutableUserInfo objectForKey:@"notificationName"];
  if ([notificationName length]) {
    [dnc msPostNotificationName:notificationName object:self userInfo:mutableUserInfo forceMainThread:notifyOnMainThread];
  }
}

- (void)_mapDataInBackground:(NSDictionary *)userInfo {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [self _mapData:userInfo notifyOnMainThread:YES];
  [pool drain];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [_requests makeObjectsPerformSelector:@selector(cancel)];
  [self stopUpdatingLocation];
  
  [_context release];
  [_dataMappers release];
  [_locationManager release];
  [_requests release];
  [_requestPriorities release];
  [_servicesPlistName release];
  [_xmlMappers release];
  [super dealloc];
}

@end
