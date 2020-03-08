//
//  UIBarButtonItem_TLCommon.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/10/09.
//

#import <UIKit/UIKit.h>
#import "UIBarButtonItem_TLCommon.h"
#import "UIActivityIndicatorView_TLCommon.h"

@implementation UIBarButtonItem (TLCommon)

+ (UIBarButtonItem *)spinnerBarButtonItem {
	UIActivityIndicatorView *spinner = [UIActivityIndicatorView animatingActivityIndicatorViewWithStyle:UIActivityIndicatorViewStyleWhite];
	
	UIBarButtonItem *spinnerBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
	spinnerBarButtonItem.enabled = NO;
	
	return spinnerBarButtonItem;
}

+ (UIBarButtonItem *)flexibleSpaceBarButtonItem {
	return [self barButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

+ (UIBarButtonItem *)fixedSpaceBarButtonItemWithWidth:(CGFloat)spaceWidth {
	UIBarButtonItem *fixedSpace = [self barButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	fixedSpace.width = spaceWidth;
	return fixedSpace;
}

+ (UIBarButtonItem *)barButtonSystemItem:(UIBarButtonSystemItem)systemItem target:(id)target action:(SEL)action {
	return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:systemItem target:target action:action];
}


@end
