//
//  UIFont_TLCommon.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 10/11/09.
//

#import "UIFont_TLCommon.h"



@implementation UIFont (TLCommon)

+ (UIFont *)helveticaWithSize:(CGFloat)size {
  return [UIFont fontWithName:@"Helvetica" size:size];  
}

+ (UIFont *)helveticaBoldWithSize:(CGFloat)size {
  return [UIFont fontWithName:@"Helvetica-Bold" size:size];
}

+ (UIFont *)helveticaItalicWithSize:(CGFloat)size {
  return [UIFont fontWithName:@"Helvetica-Oblique" size:size];
}

+ (UIFont *)helveticaBoldItalicWithSize:(CGFloat)size {
  return [UIFont fontWithName:@"Helvetica-BoldOblique" size:size];
}

@end
