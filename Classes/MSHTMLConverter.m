//
//  MSHTMLConverter.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 10/23/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "MSHTMLConverter.h"

@implementation MSHTMLConverter

static NSArray *_hiddenTags = nil;

#pragma mark -
#pragma mark Class Methods

+ (void)initialize {
  if (!_hiddenTags) {
    @synchronized(self) {
      if (!_hiddenTags) {
        _hiddenTags = [[NSArray alloc] initWithObjects:
                       @"script",
                       @"style",
                       nil];
      }
    }
  }
}

#pragma mark -
#pragma mark Initialization

- (id)init {
  if (self = [super init]) {
    _resultString = [[NSMutableString alloc] init];
    _hideElements = [[NSMutableArray alloc] init];
    _convertBreakTags = YES;
  }
  return self;
}

#pragma mark -
#pragma mark Properties

@synthesize convertBreakTags=_convertBreakTags;

#pragma mark -
#pragma mark HTML Methods

- (NSString *)compressSpaces:(NSString *)string {
  NSUInteger length;
  do {
    length = [string length];
    
    string = [string stringByReplacingOccurrencesOfString:@"  " withString:@" "];
  } while (length != [string length]);
  return string;
}

- (NSString *)compressWhitespace:(NSString *)string {
  string = [self removeNewlines:string];
  string = [self compressSpaces:string];
  return string;
}

- (NSString *)htmlDecode:(NSString *)string {
  _foundError = NO;
  _foundHTML = NO;
  _hide = NO;
  [_resultString deleteCharactersInRange:NSMakeRange(0, [_resultString length])];
  [_hideElements removeAllObjects];
  
  if (nil == string) {
    return nil;
  }
  if (![string length]) {
    return @"";
  }
  
  NSString *xmlString = [NSString stringWithFormat:@"<root>%@</root>", string];
  NSData *data = [xmlString dataUsingEncoding:[string fastestEncoding]];
  NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
  [parser setDelegate:self];
  [parser parse];
  [parser release];
  NSString *result;
  
  if (_foundError) {
    return string;
  }
  
  if (_foundHTML) {
    result = [self compressWhitespace:_resultString];
    if (self.convertBreakTags) {
      result = [result stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    }
  } else {
    result = [[_resultString copy] autorelease];
  }
  
  return result;
}

- (NSString *)removeHTMLTags:(NSString *)string {
  if (nil == string) {
    return nil;
  }
  if (![string length]) {
    return @"";
  }
  
  if (self.convertBreakTags) {
    string = [string stringByReplacingOccurrencesOfString:@"<br/>" withString:@"@BR@"];
  }
  NSScanner *scanner = [NSScanner scannerWithString:string];
  [scanner setCharactersToBeSkipped:nil];
  NSMutableString *text = [[NSMutableString alloc] initWithCapacity:[string length]];
  NSString *part = nil;
  BOOL foundHTML = NO;
  while (![scanner isAtEnd]) {
    [scanner scanUpToString:@"<" intoString:&part];
    if ([part length]) {
      [text appendString:part];
      part = nil;
    }
    if ([scanner scanUpToString:@">" intoString:NULL]) {
      [text appendString:@" "];
      foundHTML = YES;
    }
    [scanner scanString:@">" intoString:NULL];
  }
  string = [[text copy] autorelease];
  [text release];
  if (foundHTML) {
    string = [self compressWhitespace:string];
  }
  if (self.convertBreakTags) {
    string = [string stringByReplacingOccurrencesOfString:@"@BR@" withString:@"\n"];
  }
  
  return string;
}

- (NSString *)removeNewlines:(NSString *)string {
  string = [string stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
  string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
  string = [string stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
  return string;
}

- (NSString *)textForHTML:(NSString *)string {
  NSString *text = [self htmlDecode:string];
  if (_foundError) {
    text = [self removeHTMLTags:string];
  }
  return text;
}

#pragma mark -
#pragma mark NSXMLParserDelegate Methods

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
  if (![elementName isEqualToString:@"root"]) {
    if (!_hide) {
      if (self.convertBreakTags && [elementName isEqualToString:@"br"]) {
        [_resultString appendString:@"<br/>"];
      } else {
        [_resultString appendString:@" "];
      }
    }
    _foundHTML = YES;
    
    if (_hide && [[_hideElements lastObject] isEqualToString:elementName]) {
      [_hideElements removeLastObject];
      if (0 == [_hideElements count]) {
        _hide = NO;
      }
    }
  }
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
  if ([_hiddenTags containsObject:elementName]) {
    [_hideElements addObject:elementName];
    _hide = YES;
  }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
  if (!_hide) {
    [_resultString appendString:string];
  }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
  _foundError = YES;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
  [_hideElements release];
  [_resultString release];
  [super dealloc];
}

@end

