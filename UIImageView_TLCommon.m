//
//  UIImageView_TLCommon.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 10/11/09.
//

#import <UIKit/UIKit.h>
#import "UIImageView_TLCommon.h"
#import "UIImage_TLCommon.h"
#import "CGGeometry_TLCommon.h"

@implementation UIImageView (TLCommon)

+ (UIImageView *)imageViewWithImage:(UIImage *)image {
  return [[UIImageView alloc] initWithImage:image];
}


+ (UIImageView *)imageViewWithImage:(UIImage *)image centeredInRect:(CGRect)boundingRect {
  UIImageView *imageView = [self imageViewWithImage:image];
  imageView.frame = CenteredRectInRectWithSize(boundingRect, image.size);
  return imageView;
}

+ (UIImageView *)imageViewWithImageNamed:(NSString *)imageName {
  return [self imageViewWithImage:[UIImage imageWithName:imageName]];
}

+ (UIImageView *)imageViewWithImageNamed:(NSString *)imageName centeredInRect:(CGRect)boundingRect {
  UIImageView *imageView = [self imageViewWithImageNamed:imageName];
  imageView.frame = CenteredRectInRectWithSize(boundingRect, imageView.image.size);
  return imageView;
}

+ (UIImageView *)imageViewWithImageNamed:(NSString *)imageName extension:(NSString *)fileExtension {
  return [self imageViewWithImage:[UIImage imageWithName:imageName extension:fileExtension]];
}

+ (UIImageView *)imageViewWithImageNamed:(NSString *)imageName extension:(NSString *)fileExtension centeredInRect:(CGRect)boundingRect {
  UIImageView *imageView = [self imageViewWithImageNamed:imageName extension:fileExtension];
  imageView.frame = CenteredRectInRectWithSize(boundingRect, imageView.image.size);
  return imageView;  
}

@end
