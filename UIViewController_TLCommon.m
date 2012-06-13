//
//  UIViewController_TLCommonExtension.m
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 8/31/09.
//

#import <UIKit/UIKit.h>
#import "UIViewController_TLCommon.h"
#import "CGGeometry_TLCommon.h"

@implementation UIViewController (TLCommon)

+ (UIViewController *)viewController {
  return [[self alloc] initWithNibName:nil bundle:nil];
}

- (UINavigationController *)navigationControllerWithSelfAsRootViewController {
  return [[UINavigationController alloc] initWithRootViewController:self];
}

- (void)dismissAnimated {
  [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)dismissNotAnimated {
  [self dismissViewControllerAnimated:NO completion:^{}];
}

- (void)popAnimated {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)popNotAnimated {
  [self.navigationController popViewControllerAnimated:NO];
}

@end
