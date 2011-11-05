//
//  UIViewController_TLCommon.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 8/31/09.
//

@interface UIViewController (TLCommon)

+ (UIViewController *)viewController;
- (UINavigationController *)navigationControllerWithSelfAsRootViewController;

- (void)dismissAnimated; // convenience for - (void)dismissModalViewControllerAnimated:YES so that it can be called directly from buttons
- (void)dismissNotAnimated; // convenience for - (void)dismissModalViewControllerAnimated:NO so that it can be called directly from buttons

- (void)popAnimated; // convenience for telling the nav controller to popViewControllerAnimated:YES so that it can be called directly from buttons
- (void)popNotAnimated; // convenience for telling the nav controller to popViewControllerAnimated:NO so that it can be called directly from buttons

@end
