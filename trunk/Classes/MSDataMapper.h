//
//  MSDataMapper.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/17/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSMapper.h"

@interface MSDataMapper : MSMapper {
@private
  NSDictionary *_objectFormatters;
  NSString *_serviceURL;
  NSDictionary *_staticAttributes;
}

+ (NSFormatter *)boolFormatter;
+ (NSFormatter *)dateFormatter;
+ (NSFormatter *)formatterWithType:(NSString *)type;
+ (NSFormatter *)htmlFormatter;
+ (NSFormatter *)integerFormatter;
+ (NSFormatter *)timeFormatter;
+ (NSFormatter *)urlFormatter;

@property (nonatomic, retain) NSDictionary *objectFormatters;
@property (nonatomic, retain) NSString *serviceURL;
@property (nonatomic, retain) NSDictionary *staticAttributes;

- (id)formatValue:(id)value withFormatter:(NSFormatter *)formatter;
- (NSDictionary *)mapData:(NSDictionary *)data;
- (NSDictionary *)mapObject:(NSDictionary *)data;
- (id)reverseFormatValue:(id)value withFormatter:(NSFormatter *)formatter;
- (NSDictionary *)reverseMapObject:(NSDictionary *)data;

@end
