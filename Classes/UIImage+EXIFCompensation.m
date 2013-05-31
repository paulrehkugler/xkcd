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
  return CGSizeMake(9000, 9000);  // i'll get to this
}

@end
