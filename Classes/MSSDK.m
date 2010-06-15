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
#import "MSURLCoder.h"

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
  }
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize context=_context;
@synthesize dataMappers=_dataMappers;
@synthesize useLocation=_useLocation;

- (NSDictionary *)dataMappers {
  if (!_dataMappers) {
    @synchronized(self) {
      if (!_dataMappers) {
        NSString *plistName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MySpaceSDKServicesList"];
        if (![plistName length]) {
          plistName = @"MySpaceSDKServices";
        }
        NSString *path = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
        NSDictionary *dataMapperData = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
        NSArray *allKeys = [dataMapperData allKeys];
        NSMutableDictionary *dataMappers = [NSMutableDictionary dictionaryWithCapacity:[allKeys count]];
        for (NSString *key in allKeys) {
          [dataMappers setObject:[MSDataMapper dataMapperWithType:key dictionary:[dataMapperData objectForKey:key]]
                          forKey:key];
        }
        _dataMappers = [[NSDictionary alloc] initWithDictionary:dataMappers];
      }
    }
  }
  return _dataMappers;
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

#pragma mark -
#pragma mark API Methods

- (void)executeRequestWithURL:(NSURL *)url
                       method:(NSString *)method
           requestContentType:(NSString *)requestContentType
                  requestData:(NSDictionary *)requestData
               rawRequestData:(NSData *)rawRequestData
                         type:(NSString *)type
             notificationName:(NSString *)notificationName {
  MSRequest *request = [[[MSRequest alloc] initWithContext:self.context
                                                       url:url
                                                    method:method
                                        requestContentType:requestContentType
                                               requestData:requestData
                                            rawRequestData:rawRequestData
                                                  delegate:self] autorelease];
  [request setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                        type, @"type",
                        notificationName, @"notificationName",
                        nil]];
  [_requests addObject:request];
  [request execute];
}

- (void)executeRequestWithURL:(NSURL *)url
                       method:(NSString *)method
                  requestData:(NSDictionary *)requestData
               rawRequestData:(NSData *)rawRequestData
                         type:(NSString *)type
             notificationName:(NSString *)notificationName {
  MSRequest *request = [MSRequest msRequestWithContext:self.context
                                                   url:url
                                                method:method
                                           requestData:requestData
                                        rawRequestData:rawRequestData
                                              delegate:self];
  [request setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                        type, @"type",
                        notificationName, @"notificationName",
                        nil]];
  [_requests addObject:request];
  [request execute];
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
             notificationName:MSSDKDidGetActivitiesNotification];
}

- (void)getCurrentStatus {
  NSString *type = @"currentStatus";
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:nil]]
                       method:@"GET"
                  requestData:nil
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidGetCurrentStatusNotification];
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
             notificationName:MSSDKDidGetFriendsNotification];
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
             notificationName:MSSDKDidGetMoodNotification];
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
             notificationName:MSSDKDidGetStatusNotification];
}

- (void)getVideoCategories {
  NSString *type = @"videoCategory";
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:nil]]
                       method:@"GET"
                  requestData:nil
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidGetVideoCategoriesNotification];
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
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:nil]]
                       method:@"POST"
                  requestData:data
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidPublishActivityNotification];
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
  [self executeRequestWithURL:[NSURL URLWithString:[self urlForServiceType:type parameters:nil]]
                       method:@"PUT"
                  requestData:data
               rawRequestData:nil
                         type:type
             notificationName:MSSDKDidUpdateStatusNotification];
}

- (void)uploadImage:(UIImage *)image title:(NSString *)title {
  NSString *type = @"uploadImage";
  NSData *data = UIImagePNGRepresentation(image);
  NSDictionary *parameters = nil;
  if ([title length]) {
    parameters = [NSDictionary dictionaryWithObject:title forKey:@"caption"];
  }
  NSMutableString *url = [NSMutableString stringWithString:[self urlForServiceType:type parameters:parameters]];
  [self executeRequestWithURL:[NSURL URLWithString:url]
                       method:@"POST"
           requestContentType:@"image/png"
                  requestData:nil
               rawRequestData:data
                         type:type
             notificationName:MSSDKDidUploadImageNotification];
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
  [self executeRequestWithURL:[NSURL URLWithString:url]
                       method:@"POST"
           requestContentType:@"video/quicktime"
                  requestData:nil
               rawRequestData:data
                         type:type
             notificationName:MSSDKDidUploadVideoNotification];
}

- (NSString *)urlForServiceType:(NSString *)type parameters:(NSDictionary *)parameters {
  NSString *serviceURL = [[[self dataMappers] objectForKey:type] serviceURL];
  if ([parameters count]) {
    MSURLCoder *coder = [[[MSURLCoder alloc] init] autorelease];
    NSMutableString *mutableServiceURL = [[serviceURL mutableCopy] autorelease];
    NSArray *keys = [parameters allKeys];
    NSString *separator = (NSNotFound == [serviceURL rangeOfString:@"?"].location ? @"?" : @"&");
    for (NSString *key in keys) {
      [mutableServiceURL appendFormat:@"%@%@=%@",
       separator,
       [coder encodeURIComponent:key],
       [coder encodeURIComponent:[parameters objectForKey:key]]];
      separator = @"&";
    }
    serviceURL = mutableServiceURL;
  }
  return serviceURL;
}

#pragma mark -
#pragma mark Location Services Methods

- (void)startUpdatingLocation {
  if (!_locationManager) {
    _locationManager = [[CLLocationManager alloc] init];
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
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
  [[NSNotificationCenter defaultCenter] postNotificationName:MSSDKDidFailNotification
                                                      object:self
                                                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              request, @"request",
                                                              error, @"error",
                                                              nil]];
}

- (void)msRequest:(MSRequest *)request didFinishWithData:(NSDictionary *)data {
  NSMutableDictionary *userInfo = [[[request userInfo] mutableCopy] autorelease];
  NSString *type = [userInfo objectForKey:@"type"];
  if ([type length]) {
    MSDataMapper *dataMapper = [self.dataMappers objectForKey:type];
    if (dataMapper) {
      data = [dataMapper mapData:data];
    }
  }
  [userInfo setObject:data forKey:@"data"];
  NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
  [dnc postNotificationName:MSSDKDidFinishNotification object:self userInfo:userInfo];
  NSString *notificationName = [userInfo objectForKey:@"notificationName"];
  if ([notificationName length]) {
    [dnc postNotificationName:notificationName object:self userInfo:userInfo];
  }
  [_requests removeObject:request];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [_requests makeObjectsPerformSelector:@selector(cancel)];
  [self stopUpdatingLocation];
  
  [_context release];
  [_dataMappers release];
  [_locationManager release];
  [_requests release];
  [super dealloc];
}

@end
