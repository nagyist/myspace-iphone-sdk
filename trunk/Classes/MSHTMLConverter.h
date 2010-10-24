//
//  MSHTMLConverter.h
//  MySpaceSDK
//
//  Created by Todd Krabach on 10/23/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __IPHONE_4_0
@interface MSHTMLConverter : NSObject <NSXMLParserDelegate>
#else
@interface MSHTMLConverter : NSObject
#endif
{
@private
  BOOL _convertBreakTags;
  BOOL _foundError;
  BOOL _foundHTML;
  BOOL _hide;
  NSMutableArray *_hideElements;
  NSMutableString *_resultString;
}

@property (nonatomic) BOOL convertBreakTags;

- (NSString *)compressSpaces:(NSString *)string;
- (NSString *)compressWhitespace:(NSString *)string;
- (NSString *)htmlDecode:(NSString *)string;
- (NSString *)removeHTMLTags:(NSString *)string;
- (NSString *)removeNewlines:(NSString *)string;
- (NSString *)textForHTML:(NSString *)string;

@end
