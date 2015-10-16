//
//  UIActivityIndicatorView_TLCommon.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/17/09.
//

#import "UIActivityIndicatorView_TLCommon.h"


@implementation UIActivityIndicatorView (TLCommon)

+ (UIActivityIndicatorView *)animatingActivityIndicatorViewWithStyle:(UIActivityIndicatorViewStyle)style {
	UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
	[spinner sizeToFit];
	[spinner startAnimating];
	spinner.hidesWhenStopped = YES;
	return spinner;
}

@end
