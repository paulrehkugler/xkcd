//
//  UIImage+EXIFCompensation.m
//  xkcd
//
//  Created by Paul Rehkugler on 5/31/13.
//
//

#import "UIImage+EXIFCompensation.h"

@implementation UIImage (EXIFCompensation)

- (CGSize) exifAgnosticSize {
  int bitmapWidth = CGImageGetWidth(self.CGImage);
  int bitmapHeight = CGImageGetHeight(self.CGImage);
  
  return CGSizeMake(bitmapWidth, bitmapHeight);
}

@end
