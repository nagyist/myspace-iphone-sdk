//
//  MSDataMapper.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/17/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSDataMapper.h"

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
#pragma mark MSHTMLFormatter

@interface NSString (MSHTMLEncoding)

- (NSString *)msHTMLDecode;

@end

#ifdef __IPHONE_4_0
@interface MSStringHTMLConverter : NSObject <NSXMLParserDelegate>
#else
@interface MSStringHTMLConverter : NSObject
#endif
{
@private
  BOOL _foundError;
  NSMutableString *_resultString;
}

- (NSString *)convertEntitiesInString:(NSString *)string;

@end

@implementation MSStringHTMLConverter

- (id)init {
  if (self = [super init]) {
    _resultString = [[NSMutableString alloc] init];
  }
  return self;
}

- (NSString *)convertEntitiesInString:(NSString *)string {
  if (nil == string) {
    return nil;
  }
  if (![string length]) {
    return @"";
  }
  NSString *xmlString = [NSString stringWithFormat:@"<d>%@</d>", string];
  NSData *data = [xmlString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
  NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
  [parser setDelegate:self];
  [parser parse];
  [parser release];
  return (_foundError ? string : [[_resultString copy] autorelease]);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
  [_resultString appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
  _foundError = YES;
}

- (void)dealloc {
  [_resultString release];
  [super dealloc];
}

@end

@implementation NSString (MSHTMLEncoding)

- (NSString *)msHTMLDecode {
  MSStringHTMLConverter *converter = [[MSStringHTMLConverter alloc] init];
  NSString *text = [converter convertEntitiesInString:self];
  [converter release];
  return text;
}

@end

@interface MSHTMLFormatter : NSFormatter {
@private
}

@end

@implementation MSHTMLFormatter

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
  *anObject = [string msHTMLDecode];
  return YES;
}

- (NSString *)stringForObjectValue:(id)anObject {
  return [anObject description];
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

+ (id)dataMapperWithType:(NSString *)type dictionary:(NSDictionary *)dictionary {
  return [[[self alloc] initWithType:type dictionary:dictionary] autorelease];
}

+ (NSFormatter *)dateFormatter {
  static NSDateFormatter *_dateFormatter = nil;
  if (!_dateFormatter) {
    @synchronized(self) {
      if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
      }
    }
  }
  return _dateFormatter;
}

+ (NSFormatter *)formatterWithType:(NSString *)type {
  if ([type isEqualToString:@"date"]) {
    return [[self class] dateFormatter];
  } else if ([type isEqualToString:@"html"]) {
    return [[self class] htmlFormatter];
  } else if ([type isEqualToString:@"integer"]) {
    return [[self class] integerFormatter];
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
  static NSNumberFormatter *_integerFormatter = nil;
  if (!_integerFormatter) {
    @synchronized(self) {
      if (!_integerFormatter) {
        _integerFormatter = [[NSNumberFormatter alloc] init];
        [_integerFormatter setRoundingMode:NSNumberFormatterRoundFloor];
      }
    }
  }
  return _integerFormatter;
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

- (id)initWithType:(NSString *)type {
  if (self = [super init]) {
    _type = [type copy];
  }
  return self;
}

- (id)initWithType:(NSString *)type dictionary:(NSDictionary *)dictionary {
  if (self = [self initWithType:type]) {
    self.objectArrayKeyPath = [dictionary objectForKey:@"objectArrayKeyPath"];
    self.objectAttributes = [dictionary objectForKey:@"objectAttributes"];
    self.objectFormatters = [[dictionary objectForKey:@"objectFormatters"] msMap:[self class]
                                                                        selector:@selector(formatterWithType:)];
    self.serviceURL = [dictionary objectForKey:@"serviceURL"];
    self.staticAttributes = [dictionary objectForKey:@"staticAttributes"];
  }
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize objectArrayKeyPath=_objectArrayKeyPath;
@synthesize objectAttributes=_objectAttributes;
@synthesize objectFormatters=_objectFormatters;
@synthesize serviceURL=_serviceURL;
@synthesize staticAttributes=_staticAttributes;
@synthesize type=_type;

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
    }
  }
  return value;
}

- (NSDictionary *)mapData:(NSDictionary *)data {
  NSString *objectArayKeyPath = self.objectArrayKeyPath;
  NSDictionary *object = nil;
  if ([objectArayKeyPath length]) {
    NSArray *entries = [data valueForKeyPath:objectArayKeyPath];
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
  for (NSString *key in keys) {
    value = [self formatValue:[data valueForKeyPath:[objectAttributes objectForKey:key]]
                withFormatter:[objectFormatters objectForKey:key]];
    if (nil != value) {
      [object setObject:value forKey:key];
    }
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
  for (NSString *key in keys) {
    value = [self reverseFormatValue:[data valueForKeyPath:key]
                       withFormatter:[objectFormatters objectForKey:key]];
    if (nil != value) {
      [object setObject:value forKey:[objectAttributes objectForKey:key]];
    }
  }
  return object;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [_objectArrayKeyPath release];
  [_objectAttributes release];
  [_objectFormatters release];
  [_serviceURL release];
  [_staticAttributes release];
  [_type release];
  [super dealloc];
}

@end
