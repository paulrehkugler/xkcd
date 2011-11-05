//
//  UIBarButtonItem_TLCommon.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/10/09.
//

#import <Foundation/Foundation.h>


@interface UIBarButtonItem (TLCommon)

+ (UIBarButtonItem *)spinnerBarButtonItem;
+ (UIBarButtonItem *)flexibleSpaceBarButtonItem;
+ (UIBarButtonItem *)fixedSpaceBarButtonItemWithWidth:(CGFloat)spaceWidth;
+ (UIBarButtonItem *)barButtonSystemItem:(UIBarButtonSystemItem)systemItem target:(id)target action:(SEL)action;

@end
