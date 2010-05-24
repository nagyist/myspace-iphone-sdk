//
//  MSDataMapper.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/17/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSDataMapper : NSObject {
@private
  NSString *_objectArrayKeyPath;
  NSDictionary *_objectAttributes;
  NSDictionary *_objectFormatters;
  NSString *_serviceURL;
  NSString *_type;
}

+ (id)dataMapperWithType:(NSString *)type dictionary:(NSDictionary *)dictionary;
+ (NSFormatter *)dateFormatter;
+ (NSFormatter *)formatterWithType:(NSString *)type;
+ (NSFormatter *)htmlFormatter;
+ (NSFormatter *)integerFormatter;
+ (NSFormatter *)urlFormatter;

- (id)initWithType:(NSString *)type;
- (id)initWithType:(NSString *)type dictionary:(NSDictionary *)dictionary;

@property (nonatomic, copy) NSString *objectArrayKeyPath;
@property (nonatomic, retain) NSDictionary *objectAttributes;
@property (nonatomic, retain) NSDictionary *objectFormatters;
@property (nonatomic, retain) NSString *serviceURL;
@property (nonatomic, readonly) NSString *type;

- (id)formatValue:(id)value withFormatter:(NSFormatter *)formatter;
- (NSDictionary *)mapData:(NSDictionary *)data;
- (NSDictionary *)mapObject:(NSDictionary *)data;
- (id)reverseFormatValue:(id)value withFormatter:(NSFormatter *)formatter;
- (NSDictionary *)reverseMapObject:(NSDictionary *)data;

@end
