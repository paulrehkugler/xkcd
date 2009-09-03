//
//  StatusBarController.h
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

// normal usage: init, add statusBar view as subview, modify spinner's state and messageLabel as desired

@interface StatusBarController : NSObject {
@private
  UIToolbar *statusBar;
  UIActivityIndicatorView *spinner;
  UILabel *messageLabel;
  CGPoint hiddenPosition;
  CGPoint shownPosition;
  UIBarButtonItem *spinnerBarButtonItem;
  UIBarButtonItem *labelBarButtonItem;
  UIBarButtonItem *leftFlexibleSpace;
  UIBarButtonItem *rightFlexibleSpace;
  BOOL hidden;
}

- (id)initWithStatusBarFrame:(CGRect)statusBarFrame; // should be bottom of screen
// Animated is not a boolean argument for ease of nstimer-based invocations
- (void)setStatusBarFrame:(CGRect)newStatusBarFrame;
- (void)hide;
- (void)hideAnimated;
- (void)show;
- (void)showAnimated;

- (void)startSpinner;
- (void)stopSpinner;

@property(nonatomic, retain, readonly) UIToolbar *statusBar;
@property(nonatomic, retain, readonly) UILabel *messageLabel;

@end
