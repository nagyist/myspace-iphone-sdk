//
//  UIImage+Scale.m
//  MySpaceSDK
//
//  Created by Todd Krabach on 5/10/10.
//  Copyright 2010 MySpace. All rights reserved.
//

#import "UIImage+Scale.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIImage (Scale)

- (UIImage *)imageAspectScaledToFill:(CGSize)size {
  UIImage *image = self;
  if ((size.width != image.size.width) || (size.height != image.size.height)) {
    CGFloat scale = 1.0;
    CGFloat width = size.width;
    CGFloat height = size.height;
    
    if (image.size.width - size.width > image.size.height - size.height) {
      scale = size.height / image.size.height;
      width = image.size.width * scale;
    } else {
      scale = size.width / image.size.width;
      height = image.size.height * scale;
    }
    
    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake((width - (scale * image.size.width)) / 2.0,
                             (height - (scale * image.size.height)) / 2.0,
                             width,
                             height);
    [image drawInRect:rect];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  }
  return image;
}

@end
