//
//  MSSDK.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/14/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MSContext.h"
#import "MSRequest.h"

@interface MSSDK : NSObject <MSRequestDelegate> {
@private
  MSContext *_context;
  NSDictionary *_dataMappers;
  CLLocationAccuracy _locationAccuracy;
  CLLocationManager *_locationManager;
  NSMutableSet *_requests;
  BOOL _useLocation;
  NSDictionary *_xmlMappers;
}

+ (void)resetSharedSDK;
+ (MSSDK *)sharedSDK;

- (id)initWithConsumerKey:(NSString *)key secret:(NSString *)secret;
- (id)initWithContext:(MSContext *)context;

@property (nonatomic, readonly) MSContext *context;
@property (nonatomic, retain) NSDictionary *dataMappers;
@property (nonatomic, assign) CLLocationAccuracy locationAccuracy;
@property (nonatomic) BOOL useLocation;
@property (nonatomic, retain) NSDictionary *xmlMappers;

- (void)cancelAllRequests;
- (void)executeRequestWithURL:(NSURL *)url
                       method:(NSString *)method
           requestContentType:(NSString *)requestContentType
                  requestData:(NSDictionary *)requestData
               rawRequestData:(NSData *)rawRequestData
                         type:(NSString *)type
             notificationName:(NSString *)notificationName
                     userInfo:(NSDictionary *)userInfo;
- (void)executeRequestWithURL:(NSURL *)url
                       method:(NSString *)method
                  requestData:(NSDictionary *)requestData
               rawRequestData:(NSData *)rawRequestData
                         type:(NSString *)type
             notificationName:(NSString *)notificationName
                     userInfo:(NSDictionary *)userInfo;
- (void)getActivities;
- (void)getActivitiesWithParameters:(NSDictionary *)parameters;
- (void)getActivitiesForPerson:(NSString *)personID;
- (void)getActivitiesForPerson:(NSString *)person parameters:(NSDictionary *)parameters;
- (void)getCurrentStatus;
- (void)getFriends;
- (void)getFriendsWithParameters:(NSDictionary *)parameters;
- (void)getMoods;
- (void)getMoodsWithParameters:(NSDictionary *)parameters;
- (void)getStatus;
- (void)getStatusWithParameters:(NSDictionary *)parameters;
- (void)getVideoCategories;
- (void)publishActivityWithTemplate:(NSString *)templateID
                 templateParameters:(NSDictionary *)templateParameters
                         externalID:(NSString *)externalID;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
- (void)updateStatus:(NSString *)status;
- (void)updateStatus:(NSString *)status mood:(NSDictionary *)mood;
- (void)uploadImage:(UIImage *)image title:(NSString *)title;
- (void)uploadVideo:(NSURL *)videoURL
              title:(NSString *)title
        description:(NSString *)description
               tags:(NSArray *)tags
         categories:(NSArray *)categories;
- (NSString *)urlForServiceType:(NSString *)type parameters:(NSDictionary *)parameters;

@end
