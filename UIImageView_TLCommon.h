//
//  UIImageView_TLCommon.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 10/11/09.
//

#import <Foundation/Foundation.h>


@interface UIImageView (TLCommon)

+ (UIImageView *)imageViewWithImage:(UIImage *)image;
+ (UIImageView *)imageViewWithImageNamed:(NSString *)imageName;
+ (UIImageView *)imageViewWithImageNamed:(NSString *)imageName extension:(NSString *)fileExtension;
+ (UIImageView *)imageViewWithImage:(UIImage *)image centeredInRect:(CGRect)boundingRect;
+ (UIImageView *)imageViewWithImageNamed:(NSString *)imageName centeredInRect:(CGRect)boundingRect;
+ (UIImageView *)imageViewWithImageNamed:(NSString *)imageName extension:(NSString *)fileExtension centeredInRect:(CGRect)boundingRect;

@end
