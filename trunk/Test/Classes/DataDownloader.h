//
//  DataDownloader.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 4/29/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DataDownloaderDelegate;

@interface DataDownloader : NSObject {
@private
  NSURLConnection *_connection;
  NSMutableData *_data;
  NSURL *_dataURL;
  id<DataDownloaderDelegate> _delegate;
  NSIndexPath *_indexPath;
  NSDictionary *_userInfo;
}

@property (nonatomic, readonly) NSData *data;
@property (nonatomic, retain) NSURL *dataURL;
@property (nonatomic, assign) id<DataDownloaderDelegate> delegate;
@property (nonatomic, retain) NSIndexPath *indexPath;
@property (nonatomic, retain) NSDictionary *userInfo;

- (void)cancel;
- (void)execute;

@end

@protocol DataDownloaderDelegate <NSObject>

- (void)dataDownloaderDidFinish:(DataDownloader *)dataDownloader;

@end
