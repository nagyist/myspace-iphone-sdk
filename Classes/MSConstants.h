//
//  MSConstants.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/14/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MSContextDidChangeIsLoggedInNotification  @"MSContextDidChangeIsLoggedInNotification"

#define MSSDKDidFailNotification                @"MSSDKDidFailNotification"
#define MSSDKDidFinishNotification              @"MSSDKDidFinishNotification"
#define MSSDKDidGetCurrentStatusNotification    @"MSSDKDidGetCurrentStatusNotification"
#define MSSDKDidGetFriendsNotification          @"MSSDKDidGetFriendsNotification"
#define MSSDKDidGetMoodNotification             @"MSSDKDidGetMoodNotification"
#define MSSDKDidGetVideoCategoriesNotification  @"MSSDKDidGetVideoCategoriesNotification"
#define MSSDKDidUpdateStatusNotification        @"MSSDKDidUpdateStatusNotification"
#define MSSDKDidUploadImageNotification         @"MSSDKDidUploadImageNotification"
#define MSSDKDidUploadVideoNotification         @"MSSDKDidUploadVideoNotification"

#define kMSRequestJSONContentType               @"application/json"
#define kMSSDKErrorDomain                       @"com.myspace.mobile.errorDomain"
#define kMSSDKOAuthAccessTokenURL               @"http://api.myspace.com/access_token"
#define kMSSDKOAuthAuthorizationURL             @"http://api.myspace.com/authorize?oauth_callback=%@&oauth_token=%@"
#define kMSSDKOAuthRequestTokenURL              @"http://api.myspace.com/request_token"
#define kMSSDKOpenSocialErrorCode               1

#define kMSSDKROAPrefix                         @"http://opensocial.myspace.com/roa/"
#define kMSSDKAPIPrefix                         @"http://api.myspace.com/v1/"
#define kMSSDKAPIJSONSuffix                     @".json"
