//
//  UIAlertView_TLCommon.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/10/09.
//

#import "UIAlertView_TLCommon.h"

@implementation UIAlertView (TLCommon)

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:nil
										  cancelButtonTitle:nil
										  otherButtonTitles:NSLocalizedString(@"Ok", @"Button to acknowledge modal alert"), nil];
	[alert show];
}

@end
