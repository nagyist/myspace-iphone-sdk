//
//  MSDataMapper.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/17/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSDataMapper.h"
#import "MSHTMLConverter.h"

#pragma mark -
#pragma mark NSDictionary (MSMap)

@interface NSDictionary (MSMap)

- (NSDictionary *)msMap:(id)target selector:(SEL)selector;

@end

@implementation NSDictionary (MSMap)

- (NSDictionary *)msMap:(id)target selector:(SEL)selector {
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:[self count]];
  id temp;
  id value;
  for (id key in self) {
    value = [self objectForKey:key];
    temp = [target performSelector:selector withObject:value];
    if (nil != temp) {
      [dictionary setObject:temp forKey:key];
    }
  }
  return [NSDictionary dictionaryWithDictionary:dictionary];
}

@end

#pragma mark -
#pragma mark MSBoolFormatter

@interface MSBoolFormatter : NSFormatter {
@private
}

@end

@implementation MSBoolFormatter

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
  BOOL value = NO;
  if (NSOrderedSame == [string compare:@"YES" options:NSCaseInsensitiveSearch]) {
    value = YES;
  } else if ([@"1" isEqualToString:string]) {
    value = YES;
  }
  *anObject = [NSNumber numberWithBool:value];
  return (nil != anObject);
}

- (NSString *)stringForObjectValue:(id)anObject {
  return ([anObject boolValue] ? @"1" : @"0");
}

@end

#pragma mark -
#pragma mark MSDateFormatter

@interface MSDateFormatter : NSFormatter {
@private
  NSDateFormatter *_date1Formatter;
  NSDateFormatter *_date2Formatter;
}

@property (nonatomic, readonly) NSDateFormatter *date1Formatter;
@property (nonatomic, readonly) NSDateFormatter *date2Formatter;

@end

@implementation MSDateFormatter

- (id)init {
  if (self = [super init]) {
    _date1Formatter = [[NSDateFormatter alloc] init];
    [_date1Formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    
    _date2Formatter = [[NSDateFormatter alloc] init];
    [_date2Formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
  }
  return self;
}

@synthesize date1Formatter=_date1Formatter;
@synthesize date2Formatter=_date2Formatter;

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
  id innerObject = nil;
  NSString *innerError = nil;
  BOOL formatted = [self.date1Formatter getObjectValue:&innerObject forString:string errorDescription:&innerError];
  if (!formatted) {
    formatted = [self.date2Formatter getObjectValue:&innerObject forString:string errorDescription:&innerError];
  }
  if (formatted) {
    *anObject = innerObject;
  } else {
    *error = innerError;
  }
  return formatted;
}

- (NSString *)stringForObjectValue:(id)anObject {
  return [self.date1Formatter stringForObjectValue:anObject];
}

- (void)dealloc {
  [_date1Formatter release];
  [_date2Formatter release];
  [super dealloc];
}

@end

#pragma mark -
#pragma mark MSHTMLFormatter

@interface MSHTMLFormatter : NSFormatter {
@private
  BOOL _convertBreakTags;
}

@property (nonatomic) BOOL convertBreakTags;

@end

@implementation MSHTMLFormatter

- (id)init {
  if (self = [super init]) {
    _convertBreakTags = YES;
  }
  return self;
}

@synthesize convertBreakTags=_convertBreakTags;

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
  string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  MSHTMLConverter *converter = [[MSHTMLConverter alloc] init];
  [converter setConvertBreakTags:self.convertBreakTags];
  string = [converter textForHTML:string];
  [converter release];
  string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  *anObject = string;
  return YES;
}

- (NSString *)stringForObjectValue:(id)anObject {
  return [anObject description];
}

@end

#pragma mark -
#pragma mark MSTimeFormatter

@interface MSTimeFormatter : NSFormatter {
@private
  NSNumberFormatter *_numberFormatter;
}

@end

@implementation MSTimeFormatter

- (id)init {
  if (self = [super init]) {
    _numberFormatter = [[NSNumberFormatter alloc] init];
  }
  return self;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
  if ([string length] > 10) {
    string = [string substringToIndex:10];
  }
  NSNumber *number = [_numberFormatter numberFromString:string];
  *anObject = [NSDate dateWithTimeIntervalSince1970:[number doubleValue]];
  return (nil != anObject);
}

- (NSString *)stringForObjectValue:(id)anObject {
  return ([anObject isKindOfClass:[NSDate class]] ?
          [NSString stringWithFormat:@"%qu", [(NSDate *)anObject timeIntervalSince1970]]
          : [anObject description]);
}

- (void)dealloc {
  [_numberFormatter release];
  [super dealloc];
}

@end

#pragma mark -
#pragma mark MSURLFormatter

@interface MSURLFormatter : NSFormatter {
@private
}

@end

@implementation MSURLFormatter

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
  *anObject = ([string length] ? [NSURL URLWithString:string] : nil);
  return (nil != anObject);
}

- (NSString *)stringForObjectValue:(id)anObject {
  return [anObject isKindOfClass:[NSURL class]] ? [(NSURL *)anObject absoluteString] : [anObject description];
}

@end

#pragma mark -
#pragma mark MSDataMapper

@implementation MSDataMapper

#pragma mark -
#pragma mark Class Methods

+ (NSFormatter *)boolFormatter {
  static MSBoolFormatter *_boolFormatter = nil;
  if (!_boolFormatter) {
    @synchronized(self) {
      if (!_boolFormatter) {
        _boolFormatter = [[MSBoolFormatter alloc] init];
      }
    }
  }
  return _boolFormatter;
}

+ (NSFormatter *)dateFormatter {
  NSString *key = @"MSSDKDateFormatter";
  NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
  MSDateFormatter *dateFormatter = [dictionary objectForKey:key];
  if (!dateFormatter) {
    @synchronized(self) {
      dateFormatter = [dictionary objectForKey:key];
      if (!dateFormatter) {
        dateFormatter = [[[MSDateFormatter alloc] init] autorelease];
        [dictionary setObject:dateFormatter forKey:key];
      }
    }
  }
  return dateFormatter;
}

+ (NSFormatter *)date1Formatter {
  return [(MSDateFormatter *)[self dateFormatter] date1Formatter];
}

+ (NSFormatter *)date2Formatter {
  return [(MSDateFormatter *)[self dateFormatter] date2Formatter];
}

+ (NSFormatter *)doubleFormatter {
  NSString *key = @"MSSDKDoubleFormatter";
  NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
  NSNumberFormatter *doubleFormatter = [dictionary objectForKey:key];
  if (!doubleFormatter) {
    @synchronized(self) {
      doubleFormatter = [dictionary objectForKey:key];
      if (!doubleFormatter) {
        doubleFormatter = [[[NSNumberFormatter alloc] init] autorelease];
        [doubleFormatter setDecimalSeparator:@"."];
        [doubleFormatter setMaximumFractionDigits:12];
        [dictionary setObject:doubleFormatter forKey:key];
      }
    }
  }
  return doubleFormatter;
}

+ (NSFormatter *)formatterWithType:(NSString *)type {
  if ([type isEqualToString:@"bool"]) {
    return [[self class] boolFormatter];
  } else if ([type isEqualToString:@"date"]) {
    return [[self class] dateFormatter];
  } else if ([type isEqualToString:@"date1"]) {
    return [[self class] date1Formatter];
  } else if ([type isEqualToString:@"date2"]) {
    return [[self class] date2Formatter];
  } else if ([type isEqualToString:@"double"]) {
    return [[self class] doubleFormatter];
  } else if ([type isEqualToString:@"html"]) {
    return [[self class] htmlFormatter];
  } else if ([type isEqualToString:@"integer"]) {
    return [[self class] integerFormatter];
  } else if ([type isEqualToString:@"preview"]) {
    return [[self class] previewHTMLFormatter];
  } else if ([type isEqualToString:@"time"]) {
    return [[self class] timeFormatter];
  } else if ([type isEqualToString:@"url"]) {
    return [[self class] urlFormatter];
  }
  return nil;
}

+ (NSFormatter *)htmlFormatter {
  static MSHTMLFormatter *_htmlFormatter = nil;
  if (!_htmlFormatter) {
    @synchronized(self) {
      if (!_htmlFormatter) {
        _htmlFormatter = [[MSHTMLFormatter alloc] init];
      }
    }
  }
  return _htmlFormatter;
}

+ (NSFormatter *)integerFormatter {
  NSString *key = @"MSSDKIntegerFormatter";
  NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
  NSNumberFormatter *integerFormatter = [dictionary objectForKey:key];
  if (!integerFormatter) {
    @synchronized(self) {
      integerFormatter = [dictionary objectForKey:key];
      if (!integerFormatter) {
        integerFormatter = [[[NSNumberFormatter alloc] init] autorelease];
        [integerFormatter setRoundingMode:NSNumberFormatterRoundFloor];
        [dictionary setObject:integerFormatter forKey:key];
      }
    }
  }
  return integerFormatter;
}

+ (NSFormatter *)previewHTMLFormatter {
  static MSHTMLFormatter *_previewHTMLFormatter = nil;
  if (!_previewHTMLFormatter) {
    @synchronized(self) {
      if (!_previewHTMLFormatter) {
        _previewHTMLFormatter = [[MSHTMLFormatter alloc] init];
        [_previewHTMLFormatter setConvertBreakTags:NO];
      }
    }
  }
  return _previewHTMLFormatter;
}

+ (NSFormatter *)timeFormatter {
  NSString *key = @"MSSDKTimeFormatter";
  NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
  MSTimeFormatter *timeFormatter = [dictionary objectForKey:key];
  if (!timeFormatter) {
    @synchronized(self) {
      timeFormatter = [dictionary objectForKey:key];
      if (!timeFormatter) {
        timeFormatter = [[[MSTimeFormatter alloc] init] autorelease];
        [dictionary setObject:timeFormatter forKey:key];
      }
    }
  }
  return timeFormatter;
}

+ (NSFormatter *)urlFormatter {
  static MSURLFormatter *_urlFormatter = nil;
  if (!_urlFormatter) {
    @synchronized(self) {
      if (!_urlFormatter) {
        _urlFormatter = [[MSURLFormatter alloc] init];
      }
    }
  }
  return _urlFormatter;
}

#pragma mark -
#pragma mark Initialization

- (id)initWithType:(NSString *)type dictionary:(NSDictionary *)dictionary {
  if (self = [self initWithType:type]) {
    self.objectArrayKey = [dictionary objectForKey:@"objectArrayKeyPath"];
    self.objectAttributes = [dictionary objectForKey:@"objectAttributes"];
    self.objectFormatters = [[dictionary objectForKey:@"objectFormatters"] msMap:[self class]
                                                                        selector:@selector(formatterWithType:)];
    self.serviceURL = [dictionary objectForKey:@"serviceURL"];
    self.staticAttributes = [dictionary objectForKey:@"staticAttributes"];
    self.userInfo = [dictionary objectForKey:@"userInfo"];
  }
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize objectFormatters=_objectFormatters;
@synthesize serviceURL=_serviceURL;
@synthesize staticAttributes=_staticAttributes;

#pragma mark -
#pragma mark Data Mapping Methods

- (id)formatValue:(id)value withFormatter:(NSFormatter *)formatter {
  if (formatter) {
    if ([value isKindOfClass:[NSString class]]) {
      NSString *error = nil;
      id formattedValue = nil;
      if ([formatter getObjectValue:&formattedValue forString:(NSString *)value errorDescription:&error]) {
        value = formattedValue;
      } else {
        NSLog(@"Error formatting value (%@): %@", value, error);
        value = nil;
      }
    } else if ([value isKindOfClass:[NSArray class]]) {
      NSMutableArray *formattedValues = [NSMutableArray arrayWithCapacity:[(NSArray *)value count]];
      for (id item in (NSArray *)value) {
        item = [self formatValue:item withFormatter:formatter];
        if (nil != item) {
          [formattedValues addObject:item];
        }
      }
      value = [NSArray arrayWithArray:formattedValues];
    } else if ([value isKindOfClass:[NSNumber class]] && [formatter isKindOfClass:[MSTimeFormatter class]]) {
      value = [self formatValue:[NSString stringWithFormat:@"%@", value] withFormatter:formatter];
    }
  }
  return value;
}

- (NSDictionary *)mapData:(NSDictionary *)data {
  NSString *objectArrayKey = self.objectArrayKey;
  NSDictionary *object = nil;
  if ([objectArrayKey length]) {
    NSArray *entries = [data valueForKeyPath:objectArrayKey];
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[entries count]];
    for (NSDictionary *entry in entries) {
      [objects addObject:[self mapObject:entry]];
    }
    object = [NSDictionary dictionaryWithObject:objects forKey:@"objects"];
  } else {
    object = [self mapObject:data];
  }
  
  return object;
}

- (NSDictionary *)mapObject:(NSDictionary *)data {
  NSDictionary *objectAttributes = self.objectAttributes;
  NSDictionary *objectFormatters = self.objectFormatters;
  NSDictionary *staticAttributes = self.staticAttributes;
  NSArray *keys = [objectAttributes allKeys];
  NSMutableDictionary *object = (staticAttributes ?
                                 [[staticAttributes mutableCopy] autorelease] :
                                 [NSMutableDictionary dictionaryWithCapacity:[keys count] + 1]);
  [object setObject:self.type forKey:@"type"];
  id value = nil;
  if ([keys count]) {
    for (NSString *key in keys) {
      value = [self formatValue:[data valueForKeyPath:[objectAttributes objectForKey:key]]
                  withFormatter:[objectFormatters objectForKey:key]];
      if (nil != value) {
        [object setObject:value forKey:key];
      }
    }
  } else {
    [object addEntriesFromDictionary:data];
  }
  return object;
}

- (id)reverseFormatValue:(id)value withFormatter:(NSFormatter *)formatter {
  if (formatter) {
    if ([value isKindOfClass:[NSArray class]]) {
      NSMutableArray *formattedValues = [NSMutableArray arrayWithCapacity:[(NSArray *)value count]];
      for (id item in (NSArray *)value) {
        item = [self reverseFormatValue:item withFormatter:formatter];
        if (nil != item) {
          [formattedValues addObject:item];
        }
      }
      value = [NSArray arrayWithArray:formattedValues];
    } else {
      value = [formatter stringForObjectValue:value];
    }
  }
  return value;
}

- (NSDictionary *)reverseMapObject:(NSDictionary *)data {
  NSDictionary *objectAttributes = self.objectAttributes;
  NSDictionary *objectFormatters = self.objectFormatters;
  NSDictionary *staticAttributes = self.staticAttributes;
  NSArray *keys = [objectAttributes allKeys];
  NSMutableDictionary *object = (staticAttributes ?
                                 [[staticAttributes mutableCopy] autorelease] :
                                 [NSMutableDictionary dictionaryWithCapacity:[keys count]]);
  id value = nil;
  if ([keys count]) {
    for (NSString *key in keys) {
      value = [self reverseFormatValue:[data valueForKeyPath:key]
                         withFormatter:[objectFormatters objectForKey:key]];
      if (nil != value) {
        [object setObject:value forKey:[objectAttributes objectForKey:key]];
      }
    }
  } else {
    [object addEntriesFromDictionary:data];
  }
  return object;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [_objectFormatters release];
  [_serviceURL release];
  [_staticAttributes release];
  [super dealloc];
}

@end
