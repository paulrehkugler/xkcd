//
//  UIImage_TLCommon.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/7/09.
//

#import <Foundation/Foundation.h>

@interface UIImage (TLCommon)

// Assumes extension == @"png"
// Uses imageWithContentsOfFile: under the hood, not imageNamed:
+ (UIImage *)imageWithName:(NSString *)fileName;

// Uses imageWithContentsOfFile: under the hood, not imageNamed:
+ (UIImage *)imageWithName:(NSString *)fileName extension:(NSString *)fileExtension;

- (UIImage *)imageScaledToSize:(CGSize)size;

@end
